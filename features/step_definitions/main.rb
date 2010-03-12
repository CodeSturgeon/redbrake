require 'redbrake'
SAMPLEFILE_PATH = 'tests/sample_scan.txt'
RedBrake::LOG.level = 999 # Turn off log messages

When /^I restructure a scan result$/ do
  @output = RedBrake.restructure File.new(SAMPLEFILE_PATH).read
end

Then /^the output should be parsable as YAML$/ do
  @yaml = YAML.load(@output)
end
