require 'rake'
require 'rake/testtask'

task :default => [:test_units]

desc "Run basic tests"
Rake::TestTask.new("test") do |t|
  t.pattern = 'tests/test_*.rb'
  t.verbose = true
  t.warning = true
end

desc "Scan the source"
task :scan, :source_path do |t, args|
  require 'PP'
  require 'redbrake'
  puts RedBrake.restructure(RedBrake.read_source(args[:source_path]))
end
