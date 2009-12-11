module RVideo
  class TranscoderError < RuntimeError
    class RecipeError < TranscoderError
    end
    
    class InvalidCommand < TranscoderError
    end
  
    class InvalidFile < TranscoderError
    end
    
    class InputFileNotFound < TranscoderError
    end
    
    class UnexpectedResult < TranscoderError
    end
    
    class ParameterError < TranscoderError
    end
    
    class UnknownError < TranscoderError
    end
  end
end
