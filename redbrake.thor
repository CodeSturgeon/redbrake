require 'redbrake'
require 'ftools'

class Rip < Thor
  defaults = {:source => '/dev/rdisk1',
              :llevel => 'debug',
              :out_path => '~/Desktop/redbrake'}

  desc 'listing', 'listing of source'
  method_options defaults
  def listing
    say RedBrake.clean_scan options[:source]
  end

  desc 'title TITLE_NUMBER', 'rip an entire title to a single file'
  method_options defaults
  def title(t_no)
    src = get_src
    dest = get_dest
    say "ripping title: '#{t_no}'"
    src.titles[t_no].encode :output_path => dest
  end

  desc 'chapters TITLE_NUMBER', 'rip chapters of a title to seperate files'
  method_options defaults
  def chapters(t_no)
    src = get_src
    dest = get_dest
    src.titles[t_no].chapters.each do |c_no, c|
      next if c.duration =~ /00:00:0/
      c.encode :output_path => dest
    end
  end

  desc 'preview', 'rip a single title\'s chapters to previews'
  method_options defaults
  def preview(t_no)
    src = get_src
    dest = get_dest
    src.titles[t_no].chapters.each do |c_no, c|
      next if c.duration =~ /00:00:0/
      c.encode :output_path => dest, :preset => RedBrake::Presets::FAST
    end
  end

  desc 'previews', 'rip all the chapters of all the titles to previews'
  method_options defaults
  def previews
    src = get_src
    dest = get_dest
    src.titles.each do |t_no, t|
      t.chapters.each do |c_no, c|
        next if c.duration =~ /00:00:0/
        c.encode :output_path => dest, :preset => RedBrake::Presets::FAST
      end
    end
  end

  no_tasks do
    def get_src
      say 'Getting source information'
      RedBrake::Source.new options[:source]
    end
    def get_dest
      dest = File.expand_path(options[:out_path])
      File.makedirs dest unless File.directory? dest
    end
  end

  def initialize(args, options, config)
    super(args, options, config)
    # NOTE I use self to get the parsed options rather than the passed one
    RedBrake::LOG.level = Logger.const_get self.options[:llevel].upcase
  end

end
# vim: set filetype=ruby:
