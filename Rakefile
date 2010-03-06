require 'rake'
require 'rake/testtask'

task :default => [:test_units]

desc "Run basic tests"
Rake::TestTask.new("test") do |t|
  t.pattern = 'tests/test_*.rb'
  t.verbose = true
  t.warning = true
end

task :env_setup do
  require 'redbrake'
  INPUT = ENV['INPUT'] || RedBrake::DEFAULT_INPUT
  OUTPUT = ENV['OUTPUT'] || RedBrake::DEFAULT_OUTPATH
  RedBrake::LOG.level = Logger.const_get ENV['LLEVEL'].upcase if ENV['LLEVEL']
end

task :make_source do
  SRC = RedBrake::Source.new INPUT
end

desc "Display a scan result"
task :scan, :needs=>:env_setup do |t, args|
  puts RedBrake.clean_scan INPUT
end

namespace :rip do
  desc "Rip an entire title."
  task :title, :title_number, :needs=>[:env_setup, :make_source] do |t, args|
    SRC.titles[args[:title_number].to_i].encode
  end
  desc "Rip chapters from a title individually."
  task :chapters, :title_number, :needs=>[:env_setup, :make_source] do |t, args|
    SRC.titles[args[:title_number].to_i].chapters.each do |chapter_no, chapter|
      chapter.encode
    end
  end
  desc "Rip every chapter of every title to preview."
  task :previews=>[:env_setup, :make_source] do
    SRC.titles.each do |title_number, title|
      title.chapters.each{|cn,c|c.encode :preset => RedBrake::Presets::FAST}
    end
  end
end
