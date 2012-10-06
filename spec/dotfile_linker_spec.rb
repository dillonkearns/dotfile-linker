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
    end

    describe "when symlink doesn't already exist" do
      before do
        File.stub!(:symlink?).and_return(false)
        File.stub!(:exist?).with(/^#{ ENV['HOME'] }/).and_return(false)

        @bad_filenames = %w{ . .. .git }
        @good_filenames = %w{.bash_profile .bashrc .dotrc  .emacs .gemrc .gitconfig .gitignore_global .irbrc .oh-my-zsh
                            .pryrc .rvmrc .ssh .tmux.conf .zshrc .zshrc.pre-oh-my-zsh}
      end

      it "links accepted files to home directory" do
        @good_filenames.each do |filename|
          home_dir_file_path = "#{ ENV['HOME'] }/#{ filename }"
          dotfiles_dir_file_path = "#{ DotfileLinker.dotfiles_dir }/#{ filename }"
          FileUtils.should_receive(:ln_s).with(dotfiles_dir_file_path, home_dir_file_path, { :verbose => true })
          DotfileLinker.link_file(filename)
        end
      end

      it "doesn't link blacklisted files" do
        FileUtils.should_not_receive(:ln_s)
        FileUtils.should_not_receive(:mv)
        @bad_filenames.each do |filename|
          DotfileLinker.link_file(filename)
        end
      end
    end

    describe "when file of same name exists in ~" do
      it "raises a FileAlreadyExists error" do
        File.should_receive(:exist?).with(/^#{ ENV['HOME'] }/).and_return(true)
        filename = File.expand_path("~/.test_dotfile")
        expect { DotfileLinker.link_file(filename) }.to raise_error(DotfileLinker::FileAlreadyExistsError)
      end

      describe "when user gives negative response" do
        before do
          DotfileLinker.stub!(:positive_user_response?).and_return(false)
        end

        it "doesn't raise a FileAlreadyExists error" do
          File.stub!(:exist?).with(/^#{ ENV['HOME'] }/).and_return(true)
          filename = File.expand_path("~/.test_dotfile")
          expect { DotfileLinker.link_file(filename) }.not_to raise_error(DotfileLinker::FileAlreadyExistsError)
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
