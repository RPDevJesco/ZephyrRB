# frozen_string_literal: true

# Main entry point for Zephyr WASM
# This file is loaded by ruby.wasm in the browser

puts "🚀 Initializing Zephyr WASM..."

# Load the framework
require_relative 'zephyr_wasm'

# Load all components
require_relative 'components'

puts "✅ Zephyr WASM loaded successfully!"
puts "📦 Registered components: #{ZephyrWasm::Registry.all.keys.join(', ')}"

# Signal to the browser that Ruby is ready
JS.global[:ZephyrWasmReady] = true
JS.global[:document].call(:dispatchEvent,
                          JS.global[:CustomEvent].new('zephyr-wasm-ready')
)