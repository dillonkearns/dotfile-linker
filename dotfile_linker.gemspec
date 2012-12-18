# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dotfile_linker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dillon Kearns"]
  gem.email         = ["dillon@dillonkearns.com"]
  gem.description   = "A simple command-line utility to help you symlink your dotfiles to your home directory. Just run `dotfile_linker` from your dotfiles directory."
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/dillonkearns/dotfile-linker"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "dotfile_linker"
  gem.require_paths = ["lib"]
  gem.version       = DotfileLinker::VERSION

  gem.required_ruby_version = ">=1.8.7"

  gem.add_runtime_dependency "colorize", "~> 0.5.8"
  gem.add_development_dependency "rake", "~> 10.0.3"
  gem.add_development_dependency "rspec", "~> 2.12.0"
end
