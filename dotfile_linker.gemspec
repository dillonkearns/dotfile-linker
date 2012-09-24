# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dotfile_linker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dillon Kearns"]
  gem.email         = ["dillon@dillonkearns.com"]
  gem.description   = "This gem aims to provide a simple, unopinionated solution to managing symlinking your " \
                      "dotfiles, allowing you to save them in an isolated, versioned directory and keep your home " \
                      "directory clean. Similar tools exist, but tend to impose a structure on how you manage your dotfiles."
  gem.summary       = "A simple script to help you symlink your dotfiles to your home directory."
  gem.homepage      = "https://github.com/dillonkearns/dotfile-linker"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "dotfile_linker"
  gem.require_paths = ["lib"]
  gem.version       = DotfileLinker::VERSION
end
