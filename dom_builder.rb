# frozen_string_literal: true

require 'js'

module ZephyrWasm
  class DOMBuilder
    attr_reader :root, :current

    def initialize(root)
      @root = root
      @current = root
      @elements = []
    end

    def method_missing(method_name, *args, **attrs, &block)
      tag(method_name.to_s, *args, **attrs, &block)
    end

    def tag(name, *args, **attrs, &block)
      element = JS.global[:document].call(:createElement, name)

      # Set attributes
      attrs.each do |key, value|
        next if value.nil?
        
        if key.to_s.start_with?('on_')
          # Event handler
          event_name = key.to_s.sub('on_', '')
          handler = value.to_js
          element.call(:addEventListener, event_name, handler)
        elsif key == :class || key == :classes
          element[:className] = value.to_s
        elsif key == :style && value.is_a?(Hash)
          value.each { |k, v| element[:style][k.to_s.gsub('_', '-')] = v }
        else
          element.call(:setAttribute, key.to_s, value.to_s)
        end
      end

      # Set text content if provided
      if args.any?
        element[:textContent] = args.first.to_s
      end

      # Process children
      if block
        old_current = @current
        @current = element
        instance_eval(&block)
        @current = old_current
      end

      @elements << element
      @current.call(:appendChild, element)

      element
    end

    def text(content)
      text_node = JS.global[:document].call(:createTextNode, content.to_s)
      @current.call(:appendChild, text_node)
      text_node
    end

    def apply
      # Clear existing content
      @root[:innerHTML] = ''
      
      # Append all built elements
      @elements.each do |element|
        @root.call(:appendChild, element)
      end
    end

    # Helper for conditional rendering
    def render_if(condition, &block)
      instance_eval(&block) if condition
    end

    # Helper for list rendering
    def render_each(collection, &block)
      collection.each do |item|
        block.call(item)
      end
    end
  end
end
