lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "mock_collector/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mock_collector"
  s.version     = MockCollector::VERSION
  s.authors     = ["Martin Slemr"]
  s.email       = ["mslemr@redhat.com"]
  s.homepage    = "https://github.com/mslemr/mock-collector"
  s.summary     = "Mock collector for the Topological Inventory Service."
  s.description = "Mock collector for the Topological Inventory Service."
  s.license     = "Apache-2.0"

  s.files = Dir["{lib}/**/*"]

  s.add_dependency "activesupport"
  s.add_dependency "concurrent-ruby"
  s.add_dependency "kubeclient"
  s.add_dependency "optimist"
  s.add_dependency "config"
  s.add_dependency "recursive-open-struct"
end
