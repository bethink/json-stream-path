# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json/stream/path/version'

Gem::Specification.new do |spec|
  spec.name          = "json-stream-path"
  spec.version       = Json::Stream::Path::VERSION
  spec.authors       = ["Manojs"]
  spec.email         = ["manojs.nitt@gmail.com"]
  spec.description   = %q{Gem desc}
  spec.summary       = %q{Gem summary}
  spec.homepage      = "http://www.google.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
end
