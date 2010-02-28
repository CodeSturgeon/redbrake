#!/usr/bin/env ruby

require 'yaml'
require 'time'
require 'logger'

LOG = Logger.new(STDOUT)
LOG.datetime_format = '%H:%M:%S'

module RedBrake

  DVD = '/dev/disk1'
  DEFAULT_OUTPATH = File.expand_path '~/Desktop'

  # Encoding presets
  module Presets
    STANDARD = ' -e x264 -b 1500 -f mp4 -I -X 640 -Y 352 -m -2 -T '\
              ' -x level=30:bframes=0:cabac=0:ref=1:vbv-maxrate=768'\
              ':vbv-bufsize=2000:analyse=all:me=umh:no-fast-pskip=1'
    FAST = ' -e ffmpeg -q 0.0 -b 500 -r 15 -w 160 -6 mono'
  end

  module Encoder
    def base_encode(args)
      raise 'Missing title number' unless args[:title_number]

      args[:input_path] ||= DVD
      args[:output_path] ||= DEFAULT_OUTPATH
      args[:preset] ||= RedBrake::Presets::STANDARD
      args[:ext] ||= 'm4v'

      unless args[:filename] then
        args[:filename] = "t%02d" % args[:title_number]
        args[:filename] << "_c%02d" % args[:chapters] if args[:chapters]
      end

      # Build filename
      full_filename = args[:filename]+'.'+args[:ext]
      full_out_path = File.join(args[:output_path],full_filename)

      # Build main command
      cmd = "HandBrakeCli -t #{args[:title_number]} -i '#{args[:input_path]}'"
      cmd << " -o '#{full_out_path}'"
      cmd << " #{args[:preset]}"

      # Add options
      cmd << " -c #{args[:chapters]}" if args[:chapters]
      cmd << ' -d slower' if args[:deinterlace]

      # Mute noisy output
      cmd << ' 2>/dev/null'

      LOG.info 'Ripping to %s' % full_filename
      LOG.debug cmd
      system cmd
    end
  end

  class Source
    attr_reader :titles, :path
    def initialize path=DVD
      # FIXME this is very wrong...
      LOG.debug "Initializing on #{path}"
      if File.exist? path
        raw = RedBrake.scan path
      else
        LOG.debug 'Bogus source detected'
        raw = RedBrake.output_to_hashes path
      end
      #LOG.debug raw
      @path = path
      # FIXME titles should enumerate (each) as an ordered list
      @titles = {}
      raw.each do |title_number, title_data|
        title = self.add_title title_number, Time.parse(title_data['duration'])
        title_data['chapters'].each do |chapter_number, chapter_data|
          title.add_chapter chapter_number, chapter_data['duration']
        end
      end
    end
    protected
    def add_title number, duration
      new_title = Title.new self, number, duration
      @titles[number] = new_title
      new_title
    end
  end

  class Title
    include Encoder
    attr_reader :number, :duration, :chapters, :source
    def initialize source, number, duration
      @source = source
      # FIXME chapters should enumerate (each) as an ordred list
      @chapters = {}
      @number = number
      @duration = duration
    end
    def encode args={}
      args[:input_path] ||= @source.path
      args[:title_number] ||= @number
      base_encode args
    end
    def add_chapter number, duration
      new_chapter = Chapter.new self, number, duration
      @chapters[number] = new_chapter
      new_chapter
    end
  end

  class Chapter
    include Encoder
    attr_reader :number, :duration, :title, :source
    def initialize title, number, duration
      @title = title
      @number = number
      @duration = duration
      @source = title.source
    end
    def encode args={}
      args[:input_path] ||= @title.source.path
      args[:title_number] ||= @title.number
      args[:chapters] ||= @number
      base_encode args
    end
  end

  def self.scan input_path
    LOG.info 'starting scan %s' % input_path
    output = self.read_source input_path
    LOG.info 'scan done'
    self.output_to_hashes output
  end

  def self.read_source(input_path=DVD)
    `HandBrakeCli -t 0 -i '#{input_path}' 2>&1`
  end

  def self.restructure output
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
