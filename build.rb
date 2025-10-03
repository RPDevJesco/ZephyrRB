# build.rb
require 'fileutils'

class ZephyrBuilder
  def self.build
    output = []

    # 1. Embed ruby.wasm runtime
    output << File.read('src/browser.script.iife.js')

    # 2. Embed core Ruby files as inline <script type="text/ruby">
    ruby_files = [
      'registry.rb',
      'dom_builder.rb',
      'component.rb',
      'zephyr_wasm.rb'
    ]

    ruby_files.each do |file|
      ruby_code = File.read("src/#{file}")
      output << wrap_ruby_code(ruby_code)
    end

    # 3. Embed the JavaScript bridge
    output << File.read('src/zephyr-bridge.js')

    # Write bundled file
    File.write('dist/zephyrRB.js', output.join("\n\n"))
    puts "✅ Built dist/zephyrRB.js (#{File.size('dist/zephyrRB.js')} bytes)"
  end

  def self.wrap_ruby_code(code)
    # Inject Ruby code into the WASM VM at runtime
    <<~JS
      (function() {
        const rubyCode = `#{code.gsub('`', '\\`')}`;
        if (window.rubyVM) {
          window.rubyVM.eval(rubyCode);
        } else {
          document.addEventListener('ruby:ready', () => {
            window.rubyVM.eval(rubyCode);
          });
        }
      })();
    JS
  end
end

ZephyrBuilder.build