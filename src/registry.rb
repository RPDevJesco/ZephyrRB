# frozen_string_literal: true

module ZephyrWasm
  module Registry
    class << self
      def components
        @components ||= {}
      end

      def register(tag_name, component_class)
        if components.key?(tag_name)
          warn "Component '#{tag_name}' is already registered. Overwriting."
        end
        components[tag_name] = component_class
      end

      def get(tag_name)
        components[tag_name]
      end

      def all
        components
      end

      def clear
        @components = {}
      end
    end
  end
end
