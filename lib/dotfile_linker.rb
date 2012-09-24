require 'dotfile_linker/version'
require 'optparse'
require 'colorize'

class String
  def human_filename
    self.gsub(%r{^(/[^/]+){2}}, '~')
  end
end

module DotfileLinker
  BLACKLIST = %w{ .git }
  @@options = {}

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

  def self.positive_user_response?
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
      symlink_file = File.expand_path("~/#{ filename }")
      actual_file = File.expand_path(filename)
      if @@options[:delete_mode]
        if File.symlink?(symlink_file)
          puts "delete symlink #{ symlink_file.human_filename.magenta }? (y/n)"
          File.delete(symlink_file) if positive_user_response?
        end
      else
        unless File.symlink?(symlink_file)
          puts "link %s -> %s? (y/n)" % [symlink_file.human_filename.magenta, actual_file.human_filename.cyan]
          File.symlink(actual_file, symlink_file) if positive_user_response?
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
