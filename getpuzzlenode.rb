require 'uri'
require 'net/http'
require 'nokogiri'
require 'tempfile'
require 'fileutils'

HOST = "http://puzzlenode.com"

GITIGNORE = "
*.gem
*.rbc
.bundle
.config
coverage
InstalledFiles
lib/bundler/man
pkg
rdoc
spec/reports
test/tmp
test/version_tmp
tmp
 
# YARD artifacts
.yardoc
_yardoc
doc/
 
# OS X stuff
.DS_Store
".strip

class Base
  def initialize(hash)
    hash.each {|k,v| self.send "#{k}=", v }
  end
  
  class << self
    alias_method :create, :new
  end
end

class WebSource < Base
  
  attr_accessor :url
  
  def download
    res = Net::HTTP.get_response URI(@url)
    yield(res.body) if block_given?
  end
  
  def self.download(url)
    ws = self.new url: url
    ws.download do |body|
      yield body if block_given?
    end
  end
  
end

class Puzzle < Base
  attr_accessor :name, :url
  
  def files
    @files ||= _files
  end
  
  private
  
  def _files
    files = []
    WebSource.download(@url) do |body|
      doc = Nokogiri::HTML(body)
      doc.css("#files > a").each do |node|
        name = node.text
        url = "#{HOST}#{node['href']}"
        
        WebSource.download(url) do |source_body|
          tmp = Tempfile.new(name)
          tmp.write(source_body)
          tmp.close
          
          files << {file: tmp, name: name}
        end
      end
    end
    
    files
  end
end

def go_dir(dir)
  old = Dir.pwd
  Dir.chdir(dir)
  yield
  Dir.chdir(old)
end

def copy(puzzles, location)
  if File.exists?(location) and File.directory?(location)
    puts "STARTING COPY"
    Dir.chdir(location)
    puzzles.each do |puzzle|
      pname = puzzle.name
      Dir.mkdir pname
      Dir.mkdir File.join(pname, 'data')
      Dir.mkdir File.join(pname, 'source')
      
      puzzle.files.each do |file|
        fname = File.join Dir.pwd, puzzle.name, 'data', file[:name]
        
        FileUtils.cp file[:file].path, fname
      end
      
      go_dir(File.join(pname, 'source')) do
        # GIT INIT
        `git init`
        
        # GIT IGNORE
        gf = File.new('.gitignore', 'w+')
        gf.write(GITIGNORE)
        gf.close
        
        # README.md
        gf = File.new('README.md', 'w+')
        gf.write("##{pname}")
        gf.close
      end
      
    end
    puts "FILES COPIED TO: #{location}"
  else
    Dir.mkdir(location)
    copy(puzzles, location)
  end
end

WebSource.download(HOST) do |body|
  doc = Nokogiri::HTML(body)
  
  puzzles = doc.css(".puzzle > a").map do |node|
    name = node.text
    url = "#{HOST}#{node['href']}"
    puzzle = Puzzle.new(name: name, url: url)
    puts "EXERCISE: #{name}"
    puzzle.files.map do |f|
      puts "- #{f[:name]}"
    end
    
    puzzle
  end
  
  copy puzzles, ARGV[0]
end

