#!/usr/bin/env ruby

require 'yaml'

module RedBrake
  class Source < Struct.new :path
    def initilize
      raw = RedBrake.scan :path
      self.titles = {}
      raw.each do |title_number, title_data|
        self.titles['title_number'] = Title.new title_number,
                                              Time.new(title_data['duration'])
        title_data['chapters'].each do |chapter_number, chapter_data|
          self.titles['title_number'].chapters[chapter_number] = \
                                                  chapter_data['duration']
        end
      end
    end
  end
  class Title < Struct.new :number, :duration
    def initilize
      
    end
  end
  class Chapter < Struct.new :number, :duration
  end

  def self.scan input_path
    output = self.read_source input_path
    self.output_to_hashes output
  end

  def self.read_source(input_path, quiet = false)

    unless quiet
      print 'Reading input... '
      STDOUT.flush
    end
    output = `HandBrakeCli -t 0 -i #{input_path} 2>&1`
    unless quiet
      puts 'DONE'
      STDOUT.flush
    end
    output

  end

  def self.restructure output
    # FIXME - quote title duration!
    # FIXME - extract chapter duration!

    # Remove random output
    output.gsub!(/^(?![ ]*\+ ).*\n/, '')

    # Strip the '+ ' prefix off each line without loosing indent
    output.gsub!(/^([ ]*)\+ (\w)/, '\1\2')

    # Quote the duration
    output.gsub!(/(duration: )(\S+)/, '\1\'\2\'')

    # Make number of angles a property
    output.gsub!(/^  angle\(s\) (\d+)$/, '  angle(s): \1')

    # Make track listings to dicts
    output.gsub!(/^([ ]*)(\d+), (\w+ .*)/, '\1\2: \'\3\'')

    # Quote all chapter dictionary values
    output.gsub!(/^(    \d+: )(cells \d.*)/, '\1\'\2\'')

    # Make interlace detection in ot a property
    output.gsub!(/combing detected.*/, 'interlaced: true')

    # Split up that first line of stuff
    output.gsub!(/vts (\d+), ttn (\d+), (cells) (.*)/,
                    "vts: \\1\n  ttn: \\2\n  \\3: \\4")

    # Split up another long line
    output.gsub!(/, (pixel aspect: )(.*?),/, "\n  \\1'\\2'\n")
    output.gsub!(/ (display aspect: )(.*?),/, "  \\1\\2\n")
    output.gsub!(/ (.*?) (fps)/, "  \\2: \\1")

    # Quote autocrop value
    output.gsub!(/(autocrop: )(.*)/, '\1\'\2\'')

    # Remake the title as a straight number
    output.gsub!(/^title (\d+:)$/, '\1')
    output
  end

  def self.output_to_hashes output
    output = self.restructure output
    YAML::load(output)
  end
end
