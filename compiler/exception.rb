module Elang
  class ParsingError < Exception
    attr_reader :row, :col, :source
    def initialize(msg, row = nil, col = nil, source = nil)
      @row, @col, @source = row, col, source
      super(msg)
    end
  end
  
  
  class DefaultExceptionFormatter
    def format(exception)
      "#{exception.message} (#{exception.class})"
    end
  end
  
  
  class ExceptionHelper
    def self.show(e, formatter = DefaultExceptionFormatter.new)
      puts e.backtrace.reverse
      puts
      puts formatter.format(e)
      puts
    end
  end
end
