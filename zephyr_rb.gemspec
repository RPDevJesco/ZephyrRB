# zephyr_rb.gemspec
Gem::Specification.new do |spec|
  spec.name          = "zephyr_rb"
  spec.version       = "1.0.0"
  spec.summary       = "Build reactive web components using Ruby and WebAssembly"
  spec.authors       = ["Jesse Glover"]
  spec.files         = Dir["lib/**/*", "dist/**/*", "README.md"]
  spec.require_paths = ["lib"]

  # No runtime dependencies - it's all bundled!
end