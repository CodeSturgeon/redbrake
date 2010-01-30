require 'redbrake'
require 'test/unit'

class ParserTest < Test::Unit::TestCase
  def test_sanity
    sample_output = File.new('tests/sample_scan.txt').read
    obj = RedBrake.output_to_hashes sample_output
    assert_kind_of Hash, obj
    assert_equal obj[9]['angle(s)'], 1
    assert_equal obj[9]['chapters'].length, 2
    assert_equal obj[9]['subtitle tracks'].length, 3
    assert_equal obj[9]['pixel aspect'], '8/9'
    assert_equal obj[9]['display aspect'], 1.33
  end
end
