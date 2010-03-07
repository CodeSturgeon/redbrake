require 'redbrake'
SAMPLEFILE_PATH = 'tests/sample_scan.txt'

describe RedBrake::Source do
  before(:all){@src = RedBrake::Source.new(File.new(SAMPLEFILE_PATH).read)}
  it('Should have 9 titles'){@src.should have(9).titles}
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
