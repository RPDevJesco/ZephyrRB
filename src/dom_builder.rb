# dom_builder.rb
# frozen_string_literal: true

require 'js'

module ZephyrWasm
  class DOMBuilder
    attr_reader :root, :component

    def initialize(root, component)
      @root = root
      @component = component
      @doc = JS.global[:document]
      @fragment = @doc.call(:createDocumentFragment)
      @stack = [@fragment] # current parent stack
    end

    def method_missing(method_name, *args, **attrs, &block)
      tag(method_name.to_s, *args, **attrs, &block)
    end

    def tag(name, *args, **attrs, &block)
      el = @doc.call(:createElement, name)

      # attributes & event handlers
      attrs.each do |key, value|
        next if value.nil?

        key_str = key.to_s
        if key_str.start_with?('on_') # event handler
          event = key_str.sub('on_', '')
          handler =
            if value.respond_to?(:to_proc)
              # Ruby lambda/proc provided (common case before you call .to_js)
              value.to_js
            elsif value.respond_to?(:to_js)
              # Ruby object with .to_js (e.g., you passed ->{}.to_js explicitly)
              value.to_js
            else
              # Already a JS::Object / native function
              value
            end
          el.call(:addEventListener, event, handler)

        elsif key == :class || key == :classes
          el[:className] = value.to_s

        elsif key == :style && value.is_a?(Hash)
          value.each { |k, v| el[:style][k.to_s.tr('_', '-')] = v }

        elsif key == :checked || key == :disabled || key == :selected
          # boolean properties should be set on the property, not attribute
          el[key] = !!value

        else
          el.call(:setAttribute, key.to_s, value.to_s)
        end
      end

      el[:textContent] = args.first.to_s if args.any?

      # append to current parent; descend if block given
      parent = @stack.last
      parent.call(:appendChild, el)
      if block
        @stack.push(el)
        yield
        @stack.pop
      end

      el
    end

    def text(content)
      node = @doc.call(:createTextNode, content.to_s)
      @stack.last.call(:appendChild, node)
      node
    end

    def apply
      @root.call(:replaceChildren, @fragment)
      # reset for the next render
      @fragment = @doc.call(:createDocumentFragment)
      @stack = [@fragment]
    end

    # Helpers
    def render_if(condition, &block)
      yield if condition
    end
    def render_each(collection, &block)
      collection.each { |item| block.call(item) }
    end
  end
end
