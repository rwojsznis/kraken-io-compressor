# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kraken-io/compressor/version'

Gem::Specification.new do |spec|
  spec.name          = "kraken-io-compressor"
  spec.version       = Kraken::Compressor::VERSION
  spec.authors       = ["Rafal Wojsznis"]
  spec.email         = ["rafal.wojsznis@gmail.com"]

  spec.summary  = spec.description = "Kraken.io helper"
  spec.homepage = "https://github.com/emq/kraken-io-compressor"

  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency 'kraken-io'
end
