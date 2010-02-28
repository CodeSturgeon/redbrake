require 'rake'
require 'rake/testtask'

task :default => [:test_units]

desc "Run basic tests"
Rake::TestTask.new("test") do |t|
  t.pattern = 'tests/test_*.rb'
  t.verbose = true
  t.warning = true
end

task :redbrake do
  require 'redbrake'
   #FIXME set logging level based on LLEVEL
   #FIXME how can I output info at the head of 'rake -T'
end

desc "Display a scan result (Default source is DVD)"
task :scan, :source_path, :needs=>:redbrake do |t, args|
  puts RedBrake.clean_scan(args[:source_path])
end

namespace :rip do
  desc "Rip an entire title."
  task :title, :title_number, :needs=>:redbrake do |t, args|
    src = RedBrake::Source.new
    src.titles[args[:title_number].to_i].encode
  end
  desc "Rip chapters from a title individually."
  task :chapters, :title_number, :needs=>:redbrake do |t, args|
    src = RedBrake::Source.new
    src.titles[args[:title_number].to_i].chapters.each do |chapter_no, chapter|
      chapter.encode
    end
  end
  desc "Rip every chapter of every title to preview."
  task :previews=>:redbrake do
    src = RedBrake::Source.new
    src.titles.each do |title_number, title|
      title.chapters.each{|cn,c|c.encode :preset => RedBrake::Presets::FAST}
    end
  end
end
