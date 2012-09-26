# DotfileLinker [![Build Status](https://secure.travis-ci.org/dillonkearns/dotfile-linker.png?branch=master)](http://travis-ci.org/dillonkearns/dotfile-linker?branch=master)

A simple command-line utility to help you symlink your dotfiles to your home directory. Just run `link_dotfiles` from
your dotfiles directory.

## Description

This gem aims to provide a simple, unopinionated solution to managing symlinking your dotfiles, allowing you to save
them in an isolated, versioned directory and keep your home directory clean. Similar tools exist, but tend to impose a
structure on how you manage your dotfiles.

## Installation

This gem is hosted on [rubygems.org](rubygems.org), so simply install with:

    $ gem install dotfile_linker

## Usage

Run `link_dotfiles` from your dotfiles directory. The script will then run through each file that isn't already
symlinked in your home directory and ask if you want to symlink it. The `-d` option cycles through existing symlinks in
your home directory and asks if you'd like to remove them.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
