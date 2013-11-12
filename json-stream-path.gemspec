# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json/stream/path/version'

Gem::Specification.new do |spec|
  spec.name          = "json-stream-path"
  spec.version       = Json::Stream::Path::VERSION
  spec.authors       = ["Manojs"]
  spec.email         = ["manojs.nitt@gmail.com"]
  spec.description   = %q{A streaming JSON parser (generates SAX-like events) and "JSON Path" like implementation to parse small amount of data in a large JSON file.}
  spec.summary       = %q{A parser best suited for huge JSON documents that don't fit in memory and to parse small amount of data in a large JSON file.}
  spec.homepage      = "https://github.com/bethink/json-stream-path"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
end
