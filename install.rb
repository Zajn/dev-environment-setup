#!/usr/bin/env ruby
require 'yaml'
require 'tmpdir'

class DotFiles
  GITHUB_URL   = "git://github.com"
  GIT_FILE_EXT = '.git'
  EMACS_DIR = File.join(Dir.home, '.emacs.d')
  LISP_DIR = File.join(EMACS_DIR, 'lisp')
  LINUX_FONT_DIR = File.join(Dir.home, '.fonts')
  OSX_FONT_DIR = File.join(Dir.home, "/Library/Fonts")
  
  # TODO: Maybe only declare OS specific constants when running on that OS?
  
  attr_accessor :directory
  
  def self.install_in(directory, &block)
    raise "Block is required!" unless block_given?
    DotFiles.new(directory, &block)
  end
  
  def initialize(directory, &block)
    @directory = directory
    
    if Dir.exist?(@directory)
      instance_eval(&block)
    end
  end
  
  # WARNING: This is very unsafe since we are just trusting anything that comes
  # from the user. Maybe switch this out for an actual ruby git client?
  
  # By default, will clone git repositories into the directory passed
  # into the `install_in` method.
  def clone(repository, destination = nil)
    destination ||= @directory
    repository = File.join(GITHUB_URL, repository)
    
    filename = File.basename(repository, GIT_FILE_EXT)
    destination = File.join(destination, filename)
    puts `git clone #{repository} #{destination}`
  end
  
  # Installs lisp libraries from Github that are not available in ELPA, MELPA Stable
  def install_lisp(repositories)
    unless Dir.exist?(LISP_DIR)
      puts "Creating #{LISP_DIR}"
      Dir.mkdir(LISP_DIR)
    end

    repositories.each do |repo| 
      clone(repo, LISP_DIR)
    end
  end
  
  def install_font(fonts)
    install_fonts_linux(fonts) if OS.linux?
    install_fonts_mac(fonts) if OS.mac?
    
    puts "Installing fonts on Windows not supported yet. Skipping." if OS.windows?
  end
  
  def install_fonts_linux(fonts)
    puts "Linux font dir #{LINUX_FONT_DIR}"
    unless Dir.exist?(LINUX_FONT_DIR)
      puts "Creating #{LINUX_FONT_DIR}"
      Dir.mkdir(LINUX_FONT_DIR) 
    end
    
    tmpdir = Dir.mktmpdir
    
    begin
      fonts.each do |font|
        clone(font, tmpdir)
      end
    
      glob = File.join(tmpdir, '**', '*.ttf')
      puts Dir.glob(glob)
    ensure
      FileUtils.remove_entry(tmpdir)
    end
  end
  
  module OS 
    class << self
      def mac?
        !!(/darwin/ =~ RUBY_PLATFORM)
      end
      
      def linux?
        !!(/linux/ =~ RUBY_PLATFORM)
      end
      
      def windows?
        !!(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM)
      end
      
    end
  end
end

DotFiles.install_in "/home/zach/test" do
  config = YAML.load_file("./repos.yml")
  lisp_repositories = config["repositories"]["lisp"]
  font_repositories = config["repositories"]["font"]
  lisp_repositories.each do |repo| 
    clone repo
  end
 
  install_font font_repositories
end