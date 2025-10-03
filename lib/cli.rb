# lib/zephyr_rb/cli.rb
# frozen_string_literal: true

require 'fileutils'
require 'json'
require_relative 'version'

module ZephyrRb
  class CLI
    class << self
      def run(args)
        command = args[0]

        case command
        when 'build'
          build
        when 'version', '-v', '--version'
          puts "ZephyrRb v#{VERSION}"
        when 'help', '-h', '--help', nil
          show_help
        else
          puts "Unknown command: #{command}"
          show_help
        end
      end

      def build
        puts "🔨 Building ZephyrRb v#{VERSION}..."
        puts "📦 Bundling Ruby WASM #{RUBY_WASM_VERSION}..."

        Builder.new.build

        puts "✅ Build complete!"
      end

      def show_help
        puts <<~HELP
          ZephyrRb - Build reactive web components using Ruby and WebAssembly
          
          Usage:
            zephyr-rb <command> [options]
          
          Commands:
            build       Build the bundled zephyr.js distribution file
            version     Show version information
            help        Show this help message
          
          Examples:
            zephyr-rb build
            zephyr-rb version
        HELP
      end
    end
  end

  class Builder
    DIST_DIR = File.expand_path('../../../dist', __dir__)
    SRC_DIR = File.expand_path('../../../src', __dir__)

    def build
      ensure_directories
      download_ruby_wasm if needs_ruby_wasm?
      bundle_distribution
      generate_metadata
    end

    private

    def ensure_directories
      FileUtils.mkdir_p(DIST_DIR)
      FileUtils.mkdir_p(File.join(SRC_DIR, 'vendor'))
    end

    def needs_ruby_wasm?
      wasm_file = File.join(SRC_DIR, 'vendor', 'browser.script.iife.js')
      !File.exist?(wasm_file)
    end

    def download_ruby_wasm
      require 'open-uri'

      url = "https://cdn.jsdelivr.net/npm/@ruby/#{ZephyrRb::RUBY_WASM_VERSION}/dist/browser.script.iife.js"
      target = File.join(SRC_DIR, 'vendor', 'browser.script.iife.js')

      puts "⬇️  Downloading Ruby WASM from CDN..."

      URI.open(url) do |remote|
        File.write(target, remote.read)
      end

      file_size = (File.size(target) / 1024.0).round(1)
      puts "✓ Downloaded browser.script.iife.js (#{file_size} KB)"
    end

    def bundle_distribution
      output = []

      # 1. Add header comment
      output << build_header

      # 2. Embed Ruby WASM runtime
      wasm_path = File.join(SRC_DIR, 'vendor', 'browser.script.iife.js')
      output << "// Ruby WASM Runtime"
      output << File.read(wasm_path)

      # 3. Wait for Ruby VM to be ready
      output << ruby_vm_ready_wrapper

      # 4. Embed core Ruby files
      ruby_files = [
        'registry.rb',
        'dom_builder.rb',
        'component.rb',
        'zephyr_wasm.rb'
      ]

      output << "// Core ZephyrRb Ruby Files"
      ruby_files.each do |file|
        ruby_code = File.read(File.join(SRC_DIR, file))
        output << wrap_ruby_code(file, ruby_code)
      end

      # 5. Embed the JavaScript bridge
      output << "// JavaScript Bridge"
      output << File.read(File.join(SRC_DIR, 'zephyr-bridge.js'))

      # 6. Add initialization code
      output << initialization_code

      # Write bundled file
      dist_file = File.join(DIST_DIR, 'zephyr.js')
      File.write(dist_file, output.join("\n\n"))

      file_size = (File.size(dist_file) / 1024.0).round(1)
      puts "✓ Generated dist/zephyr.js (#{file_size} KB)"

      # Also create minified version info
      puts "ℹ️  Tip: Use a tool like terser to minify for production"
    end

    def build_header
      <<~JS
        /*!
         * ZephyrRb v#{ZephyrRb::VERSION}
         * Build reactive web components using Ruby and WebAssembly
         * 
         * Ruby WASM: #{ZephyrRb::RUBY_WASM_VERSION}
         * 
         * https://github.com/RPDevJesco/ZephyrRb
         * Released under the MIT License
         */
      JS
    end

    def ruby_vm_ready_wrapper
      <<~JS
        // Wait for Ruby VM to initialize
        (function() {
          const waitForRuby = () => {
            return new Promise((resolve) => {
              if (window.RubyVM) {
                resolve();
              } else {
                const checkInterval = setInterval(() => {
                  if (window.RubyVM) {
                    clearInterval(checkInterval);
                    resolve();
                  }
                }, 50);
              }
            });
          };
          
          window.ZephyrRbReady = waitForRuby();
        })();
      JS
    end

    def wrap_ruby_code(filename, code)
      escaped_code = code.gsub('\\', '\\\\\\\\').gsub('`', '\\`').gsub('${', '\\${')

      <<~JS
        // Embedded: #{filename}
        (async function() {
          await window.ZephyrRbReady;
          const rubyCode = `#{escaped_code}`;
          
          try {
            window.RubyVM.eval(rubyCode);
          } catch (error) {
            console.error('Error loading #{filename}:', error);
          }
        })();
      JS
    end

    def initialization_code
      <<~JS
        // ZephyrRb Initialization
        (async function() {
          await window.ZephyrRbReady;
          console.log('✅ ZephyrRb v#{ZephyrRb::VERSION} loaded');
          
          // Dispatch ready event for user code
          window.dispatchEvent(new CustomEvent('zephyr:ready', {
            detail: { version: '#{ZephyrRb::VERSION}' }
          }));
        })();
      JS
    end

    def generate_metadata
      metadata = {
        version: ZephyrRb::VERSION,
        ruby_wasm_version: ZephyrRb::RUBY_WASM_VERSION,
        built_at: Time.now.utc.iso8601,
        files: {
          main: 'zephyr.js',
          size_kb: (File.size(File.join(DIST_DIR, 'zephyr.js')) / 1024.0).round(2)
        }
      }

      metadata_file = File.join(DIST_DIR, 'metadata.json')
      File.write(metadata_file, JSON.pretty_generate(metadata))
      puts "✓ Generated dist/metadata.json"
    end
  end
end