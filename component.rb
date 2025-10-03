# frozen_string_literal: true

require 'js'

module ZephyrWasm
  class Component
    class << self
      attr_accessor :tag_name
      attr_reader :observed_attrs

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@observed_attrs, [])
      end

      def observed_attributes(*attrs)
        @observed_attrs ||= []
        @observed_attrs.concat(attrs.map(&:to_s))
      end

      def on_connect(&block)
        define_method(:on_connect_impl, &block)
      end

      def on_disconnect(&block)
        define_method(:on_disconnect_impl, &block)
      end

      def template(&block)
        @template_block = block
      end
      
      def get_template_block
        @template_block
      end
    end

    attr_reader :element, :signal, :state

    def initialize(element)
      @element = element
      @abort_controller = JS.global[:AbortController].new
      @signal = @abort_controller[:signal]
      @state = {}
    end

    def connected
      setup_observed_attributes
      on_connect_impl if respond_to?(:on_connect_impl)
    end

    def disconnected
      @abort_controller.call(:abort)
      on_disconnect_impl if respond_to?(:on_disconnect_impl)
    end

    def attribute_changed(name, old_value, new_value)
      @state[name] = new_value
      render if @element[:isConnected]
    end

    def render
      template_block = self.class.get_template_block
      return unless template_block

      begin
        builder = DOMBuilder.new(@element, self)
        # Use instance_exec to pass builder while maintaining component context
        instance_exec(builder, &template_block)
        builder.apply
      rescue => e
        puts "Render error: #{e.message}"
        puts e.backtrace.first(5).join("\n")
      end
    end

    # State management
    def set_state(key, value)
      @state[key] = value
      render
    end

    # Attribute helpers
    def [](key)
      @element.call(:getAttribute, key.to_s)&.to_s
    end

    def []=(key, value)
      if value.nil?
        @element.call(:removeAttribute, key.to_s)
      else
        @element.call(:setAttribute, key.to_s, value.to_s)
      end
    end

    # Event helpers
    def on(event_name, selector = nil, &block)
      handler = ->(event) {
        target = event[:target]

        if selector
          # Event delegation
          element = target.call(:closest, selector)
          block.call(event) if element
        else
          block.call(event)
        end
      }.to_js

      options = { signal: @signal }.to_js
      @element.call(:addEventListener, event_name.to_s, handler, options)
    end

    # DOM query helpers
    def query(selector)
      @element.call(:querySelector, selector)
    end

    def query_all(selector)
      @element.call(:querySelectorAll, selector)
    end

    private

    def setup_observed_attributes
      self.class.observed_attrs&.each do |attr|
        value = @element.call(:getAttribute, attr)
        @state[attr] = value.to_s if value
      end
    end
  end
end
