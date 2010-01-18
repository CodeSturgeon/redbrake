#!/usr/bin/env ruby

require 'yaml'

module RedBrake
  def self.scan(input_path, quiet = false)

    unless quiet
      print 'Reading input... '
      STDOUT.flush
    end
    output = `HandBrakeCli -t 0 -i #{input_path} 2>&1`
    unless quiet
      puts 'DONE'
      STDOUT.flush
    end

    # Remove random output
    output.gsub! /^(?![ ]*\+ ).*\n/, ''

    # Strip the '+ ' prefix off each line without loosing indent
    output.gsub! /^([ ]*)\+ (\w)/, '\1\2'

    # Make number of angles a property
    output.gsub! /^  angle\(s\) (\d+)$/, '  angle(s): \1'

    # Make track listings to dicts
    output.gsub! /^([ ]*)(\d+), (\w+ .*)/, '\1\2: \'\3\''

    # Quote all chapter dictionary values
    output.gsub! /^(    \d+: )(cells \d.*)/, '\1\'\2\''

    # Make interlace detection in ot a property
    output.gsub! /combing detected.*/, 'interlaced: true'

    # Split up that first line of stuff
    output.gsub! /vts (\d+), ttn (\d+), cells (.*)/,
                    "vts: \\1\n  ttn: \\2\n  cells: \\3"

    # Split up another long line
    output.gsub! /, (pixel aspect: )(.*?), (display aspect: )(.*?), (.*?) (fps)/,
                    "\n  \\1'\\2'\n  \\3\\4\n  \\6: \\5"

    # Quote autocrop value
    output.gsub! /(autocrop: )(.*)/, '\1\'\2\''

    # Remake the title as a straight number
    output.gsub! /^title (\d+:)$/, '\1'

    YAML::load(output)
  end
end
