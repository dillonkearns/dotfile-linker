require 'dotfile_linker/version'
require 'optparse'
require 'fileutils'
require 'colorize'

class String
  def human_filename
    self.sub(/^#{ ENV['HOME'] }/, '~')
  end
end

module DotfileLinker
  class InvalidDotfilesDir < RuntimeError; end

  class Linker
    BLACKLIST = %w{ .git }

    def initialize
      @options = {}
    end

    def dotfiles_dir
      @options[:path] || Dir.pwd
    end

    def home_dir
      ENV['HOME']
    end

    def ignore_file_name
      File.expand_path("~/.dotfile_linker_ignore")
    end

    def raise_if_home_and_dotfiles_dir_match
      if File.expand_path(home_dir) == File.expand_path(dotfiles_dir)
        raise InvalidDotfilesDir, "Please specify your dotfiles directory by running `link_dotfiles` from that path, or providing a --path flag".red
      end
    end

    def user_response(message)
      puts message
      case gets.strip
      when /^y/i
        :yes
      when /^n/i
        :no
      when /^i/i
        :ignore
      when /^q/i
        :quit
      else
        user_response("Please enter a valid response")
      end
    end

    def parse_options
      optparse = OptionParser.new do |opts|
        opts.on('-p', '--path PATH', String, 'Use [PATH] as dotfiles directory (instead of current directory)') { |path| @options[:path] = File.expand_path(path) }
        opts.on_tail('-v', '--version', 'Show version') { puts VERSION; exit }
        opts.on_tail('-h', '--help', 'Show this message') { puts opts; exit }
      end
      optparse.parse!
    end

    def ignore_list
      @ignore_list ||=
        begin
          File.open(ignore_file_name, 'rb').lines.to_a.map(&:chomp)
        rescue Errno::ENOENT
          []
        end
    end

    def ignore_file(filename)
      File.open(ignore_file_name, 'a') do |f|
        f.puts filename
      end
    end

    def exclude_file?(filename)
      filename =~ /^\.\.?$/ or BLACKLIST.include?(filename) or ignore_list.include?(filename)
    end

    def link_file(filename)
      home_dir_file_path = File.expand_path("~/#{ filename }")
      dotfiles_dir_file_path = File.expand_path("#{ dotfiles_dir }/#{ filename }")
      unless File.symlink?(home_dir_file_path) || exclude_file?(filename)
        case user_response("move and link #{ home_dir_file_path.human_filename.magenta } -> #{ dotfiles_dir_file_path.human_filename.cyan }? (y/n/i[gnore])")
        when :yes
          FileUtils.mv(home_dir_file_path, dotfiles_dir_file_path, :verbose => true)
          FileUtils.ln_s(dotfiles_dir_file_path, home_dir_file_path, :verbose => true)
        when :ignore
          ignore_file(filename)
          puts "ignored #{filename.cyan}"
        when :no
          # do nothing
        when :quit
          puts "Exiting"
          exit
        end
      end
    end

    def link_files
      raise_if_home_and_dotfiles_dir_match
      Dir.foreach(home_dir) { |filename| link_file(filename) }
    end

    def start
      parse_options
      link_files
      puts 'Done'
    rescue Interrupt
      # do nothing
    rescue InvalidDotfilesDir => e
      puts e.message
    end
  end
end
