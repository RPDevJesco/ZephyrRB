# frozen_string_literal: true

require 'js'
require 'json'

# Zephyr WASM - Ruby Web Components compiled to WebAssembly
# This runs entirely in the browser using ruby.wasm
module ZephyrWasm
  @@instance_map = ObjectSpace::WeakMap.new

  class << self
    def component(tag_name, &block)
      raise ArgumentError, "Tag name must contain a hyphen" unless tag_name.include?('-')

      component_class = Class.new(Component)
      component_class.tag_name = tag_name
      component_class.class_eval(&block) if block_given?

      Registry.register(tag_name, component_class)

      # Define the custom element in the browser
      define_custom_element(tag_name, component_class)

      component_class
    end

    def define_custom_element(tag_name, component_class)
      # Store observed attributes for this component
      observed_attrs = component_class.observed_attrs || []

      # Initialize registry if needed (safe operation)
      unless JS.global[:ZephyrWasmRegistry]
        JS.global[:ZephyrWasmRegistry] = {}.to_js
      end

      # Store component metadata (safe - just property assignment)
      JS.global[:ZephyrWasmRegistry][tag_name] = {
        observedAttributes: observed_attrs
      }.to_js

      # JavaScript will poll this registry and register the custom elements
      # This avoids nested VM operations during initialization
    end

    def init_component(element, tag_name)
      component_class = Registry.get(tag_name)
      return unless component_class

      # Create Ruby component instance
      instance = component_class.new(element)

      # Store in weak map instead of on element
      @@instance_map[element] = instance

      # Call lifecycle method
      instance.connected

      # Initial render
      instance.render
    end

    def disconnect_component(element)
      instance = @@instance_map[element]
      instance.disconnected if instance
      @@instance_map.delete(element)
    end

    def attribute_changed_component(element, name, old_value, new_value)
      instance = @@instance_map[element]
      instance.attribute_changed(name, old_value, new_value) if instance
    end
  end
end

# Expose to JavaScript
JS.global[:ZephyrWasm] = {
  initComponent: ->(element, tag_name) {
    ZephyrWasm.init_component(element, tag_name.to_s)
  }.to_js,
  disconnectComponent: ->(element) {
    ZephyrWasm.disconnect_component(element)
  }.to_js,
  attributeChangedComponent: ->(element, name, old_value, new_value) {
    ZephyrWasm.attribute_changed_component(element, name.to_s, old_value, new_value)
  }.to_js
}.to_js