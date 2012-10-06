require 'rspec'
require 'dotfile_linker'

describe DotfileLinker do
  before do
    ENV['HOME'] = '/Users/someuser'
  end

  describe ".exclude_file?" do
    it "excludes files in blacklist" do
      %w{ . .. .git }.each { |filename| DotfileLinker.exclude_file?(filename).should be }
    end

    it "doesn't exclude files prefixed with dot" do
      %w{ .bash_profile .emacs .gitconfig .tmux.conf }.each { |filename| DotfileLinker.exclude_file?(filename).should_not be }
    end

    it "doesn't exclude files that aren't prefixed with dot" do
      ['my_script' 'sample.rb'].each { |filename| DotfileLinker.exclude_file?(filename).should_not be }
    end
  end

  describe ".link_file" do
    before do
      DotfileLinker.stub!(:positive_user_response?).and_return(true)

      @bad_filenames = %w{ . .. .git }
      @good_filenames = %w{.bash_profile .bashrc .dotrc  .emacs .gemrc .gitconfig .gitignore_global .irbrc .oh-my-zsh
                          .pryrc .rvmrc .ssh .tmux.conf .zshrc .zshrc.pre-oh-my-zsh}
    end

    describe "when file exists in ~/" do
      before do
        File.stub!(:exist?).with(/^#{ ENV['HOME'] }/).and_return(true)
      end

      describe "and is a symlink" do
        before do
          File.stub!(:symlink?).and_return(true)
        end

        it "doesn't attempt to move or symlink any files" do
          FileUtils.should_not_receive(:ln_s)
          FileUtils.should_not_receive(:mv)

          @good_filenames.each do |filename|
            DotfileLinker.link_file(filename)
          end

          @bad_filenames.each do |filename|
            DotfileLinker.link_file(filename)
          end
        end
      end

      describe "and is not a symlink" do
        before do
          File.stub!(:symlink?).and_return(false)
        end

        it "should move then symlinks accepted files" do
          @good_filenames.each do |filename|
            home_dir_file_path = "#{ ENV['HOME'] }/#{ filename }"
            dotfiles_dir_file_path = "#{ DotfileLinker.dotfiles_dir }/#{ filename }"
            FileUtils.should_receive(:mv).with(home_dir_file_path, dotfiles_dir_file_path, { :verbose => true }).ordered
            FileUtils.should_receive(:ln_s).with(dotfiles_dir_file_path, home_dir_file_path, { :verbose => true }).ordered
            DotfileLinker.link_file(filename)
          end
        end

        it "shouldn't move or symlink blacklisted files" do
          FileUtils.should_not_receive(:ln_s)
          FileUtils.should_not_receive(:mv)
          @bad_filenames.each do |filename|
            DotfileLinker.link_file(filename)
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
