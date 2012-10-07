require 'spec_helper'
require 'dotfile_linker'

describe DotfileLinker::Linker do
  before do
    ENV['HOME'] = '/Users/someuser'
  end

  before(:each) do
    @linker = DotfileLinker::Linker.new
    @linker.stub(:user_response).and_return(:yes)
  end

  describe "#user_response" do
    before do
      @linker = DotfileLinker::Linker.new
      @linker.stub(:puts)
    end

    it "returns expected symbols" do
      values = { :yes    => %w{y Y yes Yes},
                 :no     => %w{n N no No},
                 :ignore => %w{i I ignore Ignore},
                 :quit => %w{q Q quit Quit} }
      values.each do |k, v|
        v.each do |response|
          @linker.stub(:gets).and_return(response)
          @linker.user_response('fake message').should == k
        end
      end
    end
  end

  describe "#exclude_file?" do
    it "excludes files in blacklist" do
      %w{ . .. .git }.each { |filename| @linker.exclude_file?(filename).should be }
    end

    it "doesn't exclude files prefixed with dot" do
      %w{ .bash_profile .emacs .gitconfig .tmux.conf }.each { |filename| @linker.exclude_file?(filename).should_not be }
    end

    it "doesn't exclude files that aren't prefixed with dot" do
      ['my_script' 'sample.rb'].each { |filename| @linker.exclude_file?(filename).should_not be }
    end

    it "excludes files in ignore list" do
      @linker.stub(:ignore_list).and_return(%w{ignored_file .other_ignored_file})
      @linker.exclude_file?('ignored_file').should be
      @linker.exclude_file?('.other_ignored_file').should be
    end
  end

  describe "#ignore_list" do
    it "excludes files which are in the .dotfiles_ignore file" do
      File.should_receive(:open).with(File.expand_path("~/.dotfile_linker_ignore"), kind_of(String)).and_return(".ignored_file1\n.ignored_file2\n.ignored_file3\n")
      @linker.ignore_list.should == %w[.ignored_file1 .ignored_file2 .ignored_file3]
    end

    it "returns [] when file does not exist" do
      File.should_receive(:open).with(File.expand_path("~/.dotfile_linker_ignore"), kind_of(String)).and_raise(Errno::ENOENT)
      @linker.ignore_list.should == []
    end
  end

  describe "#ignore_file" do
    it "should write a new ignore entry" do
      file = mock('file')
      File.should_receive(:open).with(@linker.ignore_file_name, 'a').and_yield(file)
      file.should_receive(:puts).with('some_file')
      @linker.ignore_file('some_file')
    end
  end

  describe "#link_files" do
    it "raises exception when home dir and dotfiles dir are the same" do
      @linker.stub(:dotfiles_dir).and_return(@linker.home_dir)
      expect { @linker.link_files }.to raise_error(DotfileLinker::InvalidDotfilesDir)
    end
  end

  describe "#link_file" do
    before do
      @bad_filenames = %w{ . .. .git }
      @good_filenames = %w{.bash_profile .bashrc .dotrc  .emacs .gemrc .gitconfig .gitignore_global .irbrc .oh-my-zsh
                          .pryrc .rvmrc .ssh .tmux.conf .zshrc .zshrc.pre-oh-my-zsh}
    end

    describe "when the user ignores a file" do
      before do
        @linker.stub(:user_response).and_return(:ignore)
      end

      it "should call #ignore_file" do
        @linker.should_receive(:ignore_file).with("file I want to ignore")
        @linker.link_file("file I want to ignore")
      end
    end

    describe "when file exists in ~/" do
      before do
        File.stub(:exist?).with(/^#{ ENV['HOME'] }/).and_return(true)
      end

      describe "and is a symlink" do
        before do
          File.stub(:symlink?).and_return(true)
        end

        it "doesn't attempt to move or symlink any files" do
          FileUtils.should_not_receive(:ln_s)
          FileUtils.should_not_receive(:mv)

          @good_filenames.each do |filename|
            @linker.link_file(filename)
          end

          @bad_filenames.each do |filename|
            @linker.link_file(filename)
          end
        end
      end

      describe "and is not a symlink" do
        before do
          File.stub(:symlink?).and_return(false)
        end

        it "should move then symlinks accepted files" do
          @good_filenames.each do |filename|
            home_dir_file_path = "#{ ENV['HOME'] }/#{ filename }"
            dotfiles_dir_file_path = "#{ @linker.dotfiles_dir }/#{ filename }"
            FileUtils.should_receive(:mv).with(home_dir_file_path, dotfiles_dir_file_path, { :verbose => true }).ordered
            FileUtils.should_receive(:ln_s).with(dotfiles_dir_file_path, home_dir_file_path, { :verbose => true }).ordered
            @linker.link_file(filename)
          end
        end

        it "shouldn't move or symlink blacklisted files" do
          FileUtils.should_not_receive(:ln_s)
          FileUtils.should_not_receive(:mv)
          @bad_filenames.each do |filename|
            @linker.link_file(filename)
          end
        end
      end
    end
  end

  describe "String#human_filename" do
    it "replaces home dir for short path" do
      File.expand_path("~/.bash_rc").human_filename.should == '~/.bash_rc'
    end

    it "replaces home dir for long path" do
      File.expand_path("~/some/test/dir/.gitignore").human_filename.should == '~/some/test/dir/.gitignore'
    end
  end
end
