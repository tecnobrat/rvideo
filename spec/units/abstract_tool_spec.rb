require File.dirname(__FILE__) + '/../spec_helper'

module RVideo
  module Tools
    describe AbstractTool, "#assign" do
      
      before do
        @command = "ffmpeg -i $input_file$ $output_file$"
        @options = {:input_file => "foo", :output_file => "bar"}
      end
      
      it "should assign commands properly with options - ffmpeg" do
        Ffmpeg.should_receive(:new).with(@command, @options)
        AbstractTool.assign(@command, @options)
      end

      it "should assign properly without options - ffmpeg" do
        Ffmpeg.should_receive(:new).with(@command, {})
        AbstractTool.assign(@command)
      end
      
      it "should return an instance of the specified tool" do
        tool = AbstractTool.assign(@command, @options)
        tool.class.should == Ffmpeg
      end
    end
    
    describe AbstractTool, " when building a command" do
      
      before do
        @options = {:input_file => "foo", :output_file => "bar", :resolution => "baz"}
        @simple_avi = "ffmpeg -i $input_file$ -ar 44100 -ab 64 -vcodec xvid -acodec mp3 -r 29.97 -s $resolution$ -y $output_file$"  
      end
      
      it "should set supported options successfully" do
        ffmpeg = Ffmpeg.new(@simple_avi, @options)
        ffmpeg.options['resolution'].should == @options[:resolution]
        ffmpeg.options['input_file'].should == @options[:input_file]
        ffmpeg.options['output_file'].should == @options[:output_file]
      end
      
      it "should work if options defined as strings, but referenced as symbols" do
        options = {'input_file' => "foo", 'output_file' => "bar", 'resolution' => "baz"}
        ffmpeg = Ffmpeg.new(@simple_avi, options)
        ffmpeg.options[:resolution].should == options['resolution']
        ffmpeg.options[:input_file].should == options['input_file']
        ffmpeg.options[:output_file].should == options['output_file']
      end
      
      it "should ignore extra options (not needed by the recipe)" do
        Ffmpeg.new(@simple_avi, @options.merge(:foo => "bar"))
      end
      
      it "should interpolate variables successfully" do
        ffmpeg = Ffmpeg.new(@simple_avi, @options)
        ffmpeg.command.should == "ffmpeg -i #{@options[:input_file]} -ar 44100 -ab 64 -vcodec xvid -acodec mp3 -r 29.97 -s #{@options[:resolution]} -y #{@options[:output_file]}"
      end
      
      it "the matched_variable method should reference the variable without $" do
        ffmpeg = Ffmpeg.new(@simple_avi, @options)
        ffmpeg.matched_variable("$resolution$").should == "baz"
      end

      it "the matched_variable method should raise an error when the variable is not found" do
        ffmpeg = Ffmpeg.new(@simple_avi, @options)
        lambda {
          ffmpeg.matched_variable("$foo$")
        }.should raise_error(TranscoderError::ParameterError)
      end
      
      it "should raise an exception when a required variable isn't set (1)" do
        lambda {
          ffmpeg = Ffmpeg.new(@simple_avi, {:input_file => "baz"})
        }.should raise_error(TranscoderError::ParameterError)
      end
      
      it "the should raise an error when a recipe includes a variable not supplied (2)" do
        lambda {
          ffmpeg = Ffmpeg.new(@simple_avi + " $novar$", @options)
        }.should raise_error(TranscoderError::ParameterError)
      end
      
      it "the should not raise an error when a variable is supplied but nil" do
        ffmpeg = Ffmpeg.new(@simple_avi, @options.merge(:resolution => nil))
        ffmpeg.command.should == "ffmpeg -i #{@options[:input_file]} -ar 44100 -ab 64 -vcodec xvid -acodec mp3 -r 29.97 -s  -y #{@options[:output_file]}"
      end
      
      it 'should ignore escaped leading \$' do
        ffmpeg = Ffmpeg.new('ffmpeg -i $input_file$ -ar 44100 -ab 64 -fakeoptions \$foo$ -vcodec xvid -acodec mp3 -r 29.97 -s $resolution$ -y $output_file$', @options)
        ffmpeg.command.should == "ffmpeg -i #{@options[:input_file]} -ar 44100 -ab 64 -fakeoptions $foo$ -vcodec xvid -acodec mp3 -r 29.97 -s #{@options[:resolution]} -y #{@options[:output_file]}"
      end

      it 'should ignore escaped trailing \$' do
        ffmpeg = Ffmpeg.new('ffmpeg -i $input_file$ -ar 44100 -ab 64 -fakeoptions $foo\$ -vcodec xvid -acodec mp3 -r 29.97 -s $resolution$ -y $output_file$', @options)
        ffmpeg.command.should == "ffmpeg -i #{@options[:input_file]} -ar 44100 -ab 64 -fakeoptions $foo$ -vcodec xvid -acodec mp3 -r 29.97 -s #{@options[:resolution]} -y #{@options[:output_file]}"
      end

      it 'should ignore two escaped \$' do
        ffmpeg = Ffmpeg.new('ffmpeg -i $input_file$ -ar 44100 -ab 64 -fakeoptions \$foo\$ -vcodec xvid -acodec mp3 -r 29.97 -s $resolution$ -y $output_file$', @options)
        ffmpeg.command.should == "ffmpeg -i #{@options[:input_file]} -ar 44100 -ab 64 -fakeoptions $foo$ -vcodec xvid -acodec mp3 -r 29.97 -s #{@options[:resolution]} -y #{@options[:output_file]}"
      end
      
      it 'should access the original fps' do
        @mock_inspector = mock("inspector")
        Inspector.stub!(:new).and_return(@mock_inspector)
        @mock_inspector.stub!(:fps).and_return 23.98
        ffmpeg = Ffmpeg.new("ffmpeg -i $input_file$ -ar 44100 -ab 64 -vcodec xvid -acodec mp3 $original_fps$ -s $resolution$ -y $output_file$", @options)
        ffmpeg.command.should == "ffmpeg -i #{@options[:input_file]} -ar 44100 -ab 64 -vcodec xvid -acodec mp3 -r 23.98 -s #{@options[:resolution]} -y #{@options[:output_file]}"
      end
    end
  end
end
