#!/usr/bin/env ruby

require 'yaml'
require 'time'
require 'logger'

LOG = Logger.new(STDOUT)
LOG.datetime_format = '%H:%M:%S'

module RedBrake

  # Encoding presets
  module Presets
    STANDARD = ' -e x264 -b 1500 -f mp4 -I -X 640 -Y 352 -m -2 -T '\
              ' -x level=30:bframes=0:cabac=0:ref=1:vbv-maxrate=768'\
              ':vbv-bufsize=2000:analyse=all:me=umh:no-fast-pskip=1'
    FAST = ' -e ffmpeg -q 0.0 -b 500 -r 15 -w 160 -6 mono'
  end

  module Encoder
    def base_encode(args)
      raise 'Missing input path' unless args[:input_path]
      raise 'Missing title number' unless args[:title_number]

      args[:output_path] = '/Users/fish/Desktop' unless args[:output_path]

      preset = args[:preset] || RedBrake::Presets::STANDARD

      unless args[:filename] then
        args[:filename] = "t#{args[:title_number]}"
        args[:filename] += "_c#{args[:chapters]}"
      end

      cmd = "HandBrakeCli -t #{args[:title_number]} -i '#{args[:input_path]}'"
      cmd += " -c #{args[:chapters]}" if args[:chapters]
      cmd += ' -d slower' if args[:deinterlace]
      cmd += " -o '#{args[:output_path]}/#{args[:filename]}.m4v'"
      cmd += " #{preset}"
      #cmd += ' 2>&1 >/dev/null'

      LOG.debug cmd
      #system cmd
    end
  end

  class Source
    def initialize path
      LOG.debug path
      if File.exist? path
        raw = RedBrake.scan path
      else
        LOG.debug 'Bogus source detected'
        raw = RedBrake.output_to_hashes path
      end
      #LOG.debug raw
      self.path = path
      self.titles = {}
      raw.each do |title_number, title_data|
        #puts "t #{title_number}"
        title = self.add_title title_number, Time.parse(title_data['duration'])
        title_data['chapters'].each do |chapter_number, chapter_data|
          #puts "  c #{chapter_number}"
          title.add_chapter chapter_number, chapter_data['duration']
        end
      end
    end
    def add_title number, duration
      new_title = Title.new self, number, duration
      self.titles[number] = new_title
      new_title
    end
    attr_accessor :titles, :path
  end

  class Title
    include Encoder
    def initialize source, number, duration
      self.source = source
      self.chapters = {}
      self.number = number
      self.duration = duration
    end
    def add_chapter number, duration
      new_chapter = Chapter.new self, number, duration
      self.chapters[number] = new_chapter
      new_chapter
    end
    def encode filename
      base_encode :input_path => self.source.path,
                  :filename => filename,
                  :title_number => self.number
    end
    attr_accessor :number, :duration, :chapters, :source
  end

  class Chapter
    include Encoder
    def initialize title, number, duration
      self.title = title
      self.number = number
      self.duration = duration
      self.srouce = title.source
    end
    def encode filename
      base_encode :input_path => self.title.source.path,
                  :filename => filename,
                  :title_number => self.title.number,
                  :chapters => self.number
    end
    attr_accessor :number, :duration, :title, :source
  end

  def self.scan input_path
    LOG.debug 'starting scan'
    output = self.read_source input_path
    LOG.debug 'scan done'
    self.output_to_hashes output
  end

  def self.read_source(input_path, quiet = true)
    unless quiet
      print 'Reading input... '
      STDOUT.flush
    end
    output = `HandBrakeCli -t 0 -i '#{input_path}' 2>&1`
    unless quiet
      puts 'DONE'
      STDOUT.flush
    end
    output
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
