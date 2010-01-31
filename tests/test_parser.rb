require 'redbrake'
require 'test/unit'
require 'time'

SAMPLEFILE_PATH = 'tests/sample_scan.txt'

class ParserTest < Test::Unit::TestCase

  def test_sanity
    obj = RedBrake.output_to_hashes File.new(SAMPLEFILE_PATH).read
    assert_kind_of Hash, obj
  end

  def test_chapter_9
    obj = RedBrake.output_to_hashes File.new(SAMPLEFILE_PATH).read
    assert_equal obj[9]['angle(s)'], 1
    assert_equal obj[9]['chapters'].length, 2
    assert_equal obj[9]['subtitle tracks'].length, 3
    assert_equal obj[9]['pixel aspect'], '8/9'
    assert_equal obj[9]['display aspect'], 1.33
    assert_kind_of Time, Time.parse(obj[9]['duration'])
  end

  def test_source_generation
    src = RedBrake::Source.new File.new(SAMPLEFILE_PATH).read
    assert_kind_of RedBrake::Source, src
    assert_equal src.titles.length, 9
    assert_kind_of RedBrake::Title, src.titles[9]
    assert_equal src.titles[9].chapters.length, 2
    assert_kind_of RedBrake::Chapter, src.titles[9].chapters[1]
  end
end
