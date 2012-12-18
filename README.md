# DotfileLinker [![Build Status](https://secure.travis-ci.org/dillonkearns/dotfile-linker.png?branch=master)](http://travis-ci.org/dillonkearns/dotfile-linker?branch=master) [![Dependency Status](https://gemnasium.com/dillonkearns/dotfile-linker.png)](https://gemnasium.com/dillonkearns/dotfile-linker) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/dillonkearns/dotfile-linker)

A simple command-line utility to help you symlink your dotfiles to your home directory. Just run `dotfile_linker` from
your dotfiles directory.

## Description

This gem aims to provide a simple, unopinionated solution to managing symlinking your dotfiles, allowing you to save
them in an isolated, versioned directory and keep your home directory clean. Similar tools exist, but tend to impose a
structure on how you manage your dotfiles.

## Installation

This gem is hosted on [rubygems.org](https://rubygems.org/gems/dotfile_linker), so simply install with:

    $ gem install dotfile_linker

## Usage

Run `dotfile_linker` from your dotfiles directory. The script will then run through each file that isn't already
symlinked in your home directory and ask if you want to symlink it. The `-u` option unlinks and restores files to your
home directory.

![Link example](http://i.imgur.com/k4O1z.jpg)



![Unlink example](http://i.imgur.com/7JUY9.png)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
