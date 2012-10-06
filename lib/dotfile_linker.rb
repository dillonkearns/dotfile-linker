require 'dotfile_linker/version'
require 'optparse'
require 'fileutils'
require 'colorize'

class String
  def human_filename
    self.sub(/^#{ DotfileLinker.home_dir }/, '~')
  end
end

module DotfileLinker
  BLACKLIST = %w{ .git }
  @@options = {}
  class FileAlreadyExistsError < RuntimeError; end

  def self.parse_options
    optparse = OptionParser.new do |opts|
      opts.on('-p', '--path PATH', String, 'Use [PATH] as dotfiles directory (instead of current directory)') { |path| @@options[:path] = File.expand_path(path) }
      opts.on_tail('-v', '--version', 'Show version') { puts VERSION; exit }
      opts.on_tail('-h', '--help', 'Show this message') { puts opts; exit }
    end
    optparse.parse!
  end

  def self.exclude_file?(filename)
    filename =~ /^\.\.?$/ or BLACKLIST.include?(filename)
  end

  def self.home_dir
    @@home_dir ||= ENV['HOME']
  end

  def self.dotfiles_dir
    @@dotfiles_dir ||= @@options[:path] || Dir.pwd
  end

  def self.positive_user_response?(message)
    puts message
    case gets.strip
    when /^y/i
      true
    when /^n/i
      false
    else
      puts 'Exiting'
      exit
    end
  end

  def self.link_file(filename)
    home_dir_file_path = File.expand_path("~/#{ filename }")
    dotfiles_dir_file_path = File.expand_path("#{ dotfiles_dir }/#{ filename }")
    unless File.symlink?(home_dir_file_path) || exclude_file?(filename)
      if positive_user_response?("move and link #{ home_dir_file_path.human_filename.magenta } -> #{ dotfiles_dir_file_path.human_filename.cyan }? (y/n)")
        FileUtils.mv(home_dir_file_path, dotfiles_dir_file_path, :verbose => true)
        FileUtils.ln_s(dotfiles_dir_file_path, home_dir_file_path, :verbose => true)
      end
    end
  end

  def self.link_files
    Dir.foreach(home_dir) { |filename| link_file(filename) }
  end

  def self.start
    parse_options
    link_files
    puts 'Done'
  rescue Interrupt
    # do nothing
  end
end
