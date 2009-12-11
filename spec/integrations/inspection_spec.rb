require File.dirname(__FILE__) + "/../spec_helper"

module RVideo
  describe RVideo::Inspector do
    before do
      @files = YAML::load(File.open("#{FIXTURE_PATH}/files.yml"))
      #return f[key.to_s]['response']
    end
    
    it "should parse properly" do
      
    end
    
  end
end