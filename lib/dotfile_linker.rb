require 'dotfile_linker/version'
require 'optparse'
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
      opts.on('-d', '--delete', 'Delete symlinks') { @@options[:delete_mode] = true }
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
    unless exclude_file?(filename)
      symlink_path = File.expand_path("~/#{ filename }")
      actual_file_path = File.expand_path(filename)
      if @@options[:delete_mode]
        if File.symlink?(symlink_path)
          File.delete(symlink_path) if positive_user_response?("delete symlink #{ symlink_path.human_filename.magenta }? (y/n)")
        end
      else
        unless File.symlink?(symlink_path)
          if positive_user_response?("link #{ symlink_path.human_filename.magenta } -> #{ actual_file_path.human_filename.cyan }? (y/n)")
            if File.exist?(symlink_path)
              raise FileAlreadyExistsError.new("File already exists in #{ home_dir }. Please remove the file and try again.")
            end
            File.symlink(actual_file_path, symlink_path)
          end
        end
      end
    end
  end

  def self.link_files
    Dir.foreach(Dir.pwd) { |filename| link_file(filename) }
  end

  def self.start
    parse_options
    link_files
    puts 'Done'
  rescue Interrupt
    # do nothing
  end
end
