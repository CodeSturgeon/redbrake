require 'redbrake'
SAMPLEFILE_PATH = 'tests/sample_scan.txt'
RedBrake::LOG.level = 999 # Turn off log messages

class NegativeRegex
  def initialize(regex)
    @regex = regex
  end
  def description
    "string is not supposed to match #{@regex}"
  end
  def ==(string)
    string =~ @regex ? false : true
  end
end

def negative_re(regex)
  NegativeRegex.new(regex)
end

describe RedBrake::Source do
  before(:all) do
    RedBrake.stub!(:run_cmd).and_return(File.new(SAMPLEFILE_PATH).read)
    @src = RedBrake::Source.new()
  end
  it('Should have 9 titles'){@src.should have(9).titles}
  describe 'Title 7' do
    before(:each){@title = @src.titles[7]}
    it('Should have 9 chapters'){@title.should have(9).chapters}
    it('Should not be interlaced'){@title.interlaced.should be_false}
    it 'Should not pass deinterlace to encode' do
      @title.should_receive(:base_encode).with(
                                      hash_not_including(:deinterlace => true))
      @title.encode
    end
    it 'Should encode without DEINTERLACE' do
      @title.should_receive(:run_cmd).with(negative_re(/.*-d /))
      @title.encode
    end
  end
  describe 'Title 9' do
    before(:each){@title = @src.titles[9]}
    it('Should have 2 chapters'){@title.should have(2).chapters}
    it('Should be interlaced'){@title.interlaced.should be_true}
    it 'Should pass deinterlace to encode' do
      @title.should_receive(:base_encode).with(
                                          hash_including(:deinterlace => true))
      @title.encode
    end
    it 'Should encode with DEINTERLACE' do
      @title.should_receive(:run_cmd).with(/.*-d slower/)
      @title.encode
    end
  end
end

describe 'Parser output' do
  before(:all) do
    @yaml = YAML::load(RedBrake.restructure(File.new(SAMPLEFILE_PATH).read))
  end
  it('Should be a hash'){@yaml.should be_a Hash}
  it('Should have 9 titles'){@yaml.should have(9).titles}
end
