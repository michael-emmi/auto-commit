#!/usr/bin/env ruby

require 'optparse'
require 'set'

destination = nil

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename $0} [options] ROOTS"
  opts.on("--dest DIR") do |d|
    destination = d
  end
end.parse!(ARGV)

abort "Must specify root directories." unless ARGV.size > 0
roots = ARGV
roots.each do |dir|
  abort "#{dir} is not a directory." unless File.directory? dir
end
abort "Must specify destination directory." unless destination

$time = Time.now.strftime "%F-%Hh%M"

METHODS = [
  { 
    name: 'Git',
    pattern: '.git',
    status: proc {|d| `cd #{d} && git status -s` =~ /^[AMD ][AMD ]/},
    diff_cmd: 'git diff' 
  },
  {
    name: 'Subversion',
    pattern: '.svn',
    status: proc {|d| `cd #{d} && svn status -q` =~ /^[AMD ][AMD ]/},
    diff_cmd: 'svn diff'
  }
]

def make_diff(diffs_dir, root, method)
  dirs = []
  Dir.glob("#{root}/**/#{method[:pattern]}").each do |md|
    d = File.dirname md
    next if dirs.any? {|base| d.include? base }
    next if File.symlink? d
    dirs << d
    next unless method[:status].call(d)
    puts "uncommitted #{method[:name]} changes in #{d}"
    diff_file = "#{diffs_dir}/#{File.basename d}-#{$time}.diff"
    `cd #{d} && #{method[:diff_cmd]} > #{diff_file}`
  end
end

def make_zip(diffs_dir)
  `cd #{diffs_dir} && zip uncommitted-#{$time}.zip *.diff && rm *.diff`
end

roots.each do |r|
  METHODS.each do |m|
    make_diff(destination, r, m)
  end
end
make_zip(destination)




