require 'rspec'
require 'dotfile_linker'

describe DotfileLinker do
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

  describe ".link_file when symlink doesn't already exist" do
    before do
      DotfileLinker.stub!(:positive_user_response?).and_return(true)
      File.stub!(:symlink?).and_return(false)

      @bad_filenames = %w{ . .. .git }
      @good_filenames = %w{.bash_profile .bashrc .dotrc  .emacs .gemrc .gitconfig .gitignore_global .irbrc .oh-my-zsh
                          .pryrc .rvmrc .ssh .tmux.conf .zshrc .zshrc.pre-oh-my-zsh}
    end

    it "links accepted files to home directory" do
      @good_filenames.each do |filename|
        File.should_receive(:symlink).with("#{ Dir.pwd }/#{ filename }", "#{ Dir.home }/#{ filename }")
        DotfileLinker.link_file(filename)
      end
    end

    it "doesn't link blacklisted files" do
      @bad_filenames.each do |filename|
        File.should_not_receive(:symlink)
        DotfileLinker.link_file(filename)
      end
    end
  end

  describe "String#human_filename" do
    it "replaces home dir for short path" do
      File.expand_path("~/.bash_rc").human_filename.should == '~/.bash_rc'
    end

    it "replaces home dir for long path" do
      File.expand_path("#{ Dir.home }/some/test/dir/.gitignore").human_filename.should == '~/some/test/dir/.gitignore'
    end
  end
end
