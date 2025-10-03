# frozen_string_literal: true

require 'js'
require 'json'  # Added for to_json support
require_relative 'component'
require_relative 'dom_builder'
require_relative 'registry'

# Zephyr WASM - Ruby Web Components compiled to WebAssembly
# This runs entirely in the browser using ruby.wasm
module ZephyrWasm
  @@instance_map = ObjectSpace::WeakMap.new  # Added for storing instances without assigning to JS properties

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
      # Create a JavaScript class that wraps our Ruby component
      js_class = JS.eval(<<~JAVASCRIPT)
        (function() {
          class RubyComponent extends HTMLElement {
            constructor() {
              super();
              this._abortController = new AbortController();
            }

            connectedCallback() {
              // This will be called from Ruby
              if (window.ZephyrWasm && window.ZephyrWasm.initComponent) {
                window.ZephyrWasm.initComponent(this, '#{tag_name}');
              }
            }

            disconnectedCallback() {
              this._abortController.abort();
              if (window.ZephyrWasm && window.ZephyrWasm.disconnectComponent) {
                window.ZephyrWasm.disconnectComponent(this);
              }
            }

            attributeChangedCallback(name, oldValue, newValue) {
              if (window.ZephyrWasm && window.ZephyrWasm.attributeChangedComponent) {
                window.ZephyrWasm.attributeChangedComponent(this, name, oldValue, newValue);
              }
            }

            static get observedAttributes() {
              return #{component_class.observed_attrs.to_json};
            }
          }
          
          customElements.define('#{tag_name}', RubyComponent);
          return RubyComponent;
        })()
      JAVASCRIPT

      js_class
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

    # Added: Handle disconnection via global method
    def disconnect_component(element)
      instance = @@instance_map[element]
      instance.disconnected if instance
      @@instance_map.delete(element)  # Optional cleanup
    end

    # Added: Handle attribute changes via global method
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