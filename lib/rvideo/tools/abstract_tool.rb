module RVideo # :nodoc:
  module Tools # :nodoc:
    class AbstractTool
      
      #
      # AbstractTool is an interface to every transcoder tool class (e.g. 
      # ffmpeg, flvtool2). Called by the Transcoder class.
      #
      
      def self.assign(cmd, options = {})
        tool_name = cmd.split(" ").first
        tool = "RVideo::Tools::#{tool_name.classify}".constantize.send(:new, cmd, options)
      end
      
      
      module InstanceMethods
        attr_reader :options, :command, :raw_result
        
        def initialize(raw_command, options = {})
          @raw_command = raw_command
          @options = HashWithIndifferentAccess.new(options)
          @command = interpolate_variables(raw_command)
        end
        
        #
        # Look for variables surrounded by $, and interpolate with either 
        # variables passed in the options hash, or special methods provided by
        # the tool class (e.g. "$original_fps$" with ffmpeg).
        #
        # $foo$ should match
        # \$foo or $foo\$ or \$foo\$ should not

        def interpolate_variables(raw_command)
          raw_command.scan(/[^\\]\$[-_a-zA-Z]+\$/).each do |match|
            match.strip!
            raw_command.gsub!(match, matched_variable(match))
          end
          raw_command.gsub("\\$", "$")
        end
        
        #
        # Strip the $s. First, look for a supplied option that matches the
        # variable name. If one is not found, look for a method that matches.
        # If not found, raise ParameterError exception.
        # 
        
        def matched_variable(match)
          variable_name = match.gsub("$","")
          if @options.key?(variable_name) 
            @options[variable_name] || ""
          elsif self.respond_to? variable_name
            self.send(variable_name)
          else
            raise TranscoderError::ParameterError, "command is looking for the #{variable_name} parameter, but it was not provided. (Command: #{@raw_command})"
          end
        end
    
        #
        # Execute the command and parse the result.
        #
        
        def execute
          final_command = "#{@command} 2>&1"
          Transcoder.logger.info("\nExecuting Command: #{final_command}\n")
          @raw_result = `#{final_command}`
          Transcoder.logger.info("Result: \n#{@raw_result}")
          parse_result(@raw_result)
        end

        private
        
        def inspect_original
          @original = Inspector.new(:file => options[:input_file])
        end
      end
    
    end
  end
end
