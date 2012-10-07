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

    def parse_options
      optparse = OptionParser.new do |opts|
        opts.on('-p', '--path PATH', 'Use [PATH] as dotfiles directory (instead of current directory)') { |path| @options[:path] = File.expand_path(path) }
        opts.on_tail('-u', '--unlink', 'Unlink mode') { @options[:unlink_mode] = true }
        opts.on_tail('-v', '--version', 'Show version') { puts VERSION; exit }
        opts.on_tail('-h', '--help', 'Show this message') { puts opts; exit }
      end
      optparse.parse!
    end

      def each_dotfile(dirname)
        Dir.foreach(dirname) { |filename| yield filename if filename =~ /^\./ }
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
        raise InvalidDotfilesDir, "#{ dotfiles_dir } is not a valid dotfiles directory. Please specify your dotfiles directory by running `link_dotfiles` from that path, or providing a --path flag".red
      end
    end

    def user_response(message, choices)
      puts "#{message} #{choices}"
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
        user_response("Please enter a valid response", choices)
      end
    end

    def user_response_or_exit(message, choices)
      response = user_response(message, choices)
      if response == :quit
        puts "Exiting"
        exit
      end
      response
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
        case user_response_or_exit("move and link #{ home_dir_file_path.human_filename.magenta } -> #{ dotfiles_dir_file_path.human_filename.cyan }?", " (y/n/i[gnore]/q)")
        when :yes
          FileUtils.mv(home_dir_file_path, dotfiles_dir_file_path, :verbose => true)
          FileUtils.ln_s(dotfiles_dir_file_path, home_dir_file_path, :verbose => true)
        when :ignore
          ignore_file(filename)
          puts "added #{filename.cyan} to ignore file"
        end
      end
    end

    def link_files
      each_dotfile(home_dir) { |filename| link_file(filename) }
    end

    def unlink_file(filename)
      home_dir_symlink_path = File.expand_path("~/#{ filename }")
      dotfiles_dir_file_path = File.expand_path("#{ dotfiles_dir }/#{ filename }")
      if File.symlink?(home_dir_symlink_path)
        case user_response_or_exit("unlink #{ home_dir_symlink_path.human_filename.magenta } and restore #{ dotfiles_dir_file_path.human_filename.cyan }?", " (y/n/q)")
        when :yes
          FileUtils.rm(home_dir_symlink_path, :verbose => true)
          FileUtils.mv(dotfiles_dir_file_path, home_dir_symlink_path, :verbose => true)
        end
      end
    end

    def unlink_files
      each_dotfile(dotfiles_dir) { |filename| unlink_file(filename) }
    end

    def start
      parse_options
      raise_if_home_and_dotfiles_dir_match
      if @options[:unlink_mode]
        unlink_files
      else
        link_files
      end
      puts 'Finished'
    rescue Interrupt
      # do nothing
    rescue InvalidDotfilesDir => e
      puts e.message
    end
  end
end
