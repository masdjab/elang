module Elang
  class CodeGenerator
    attr_accessor :error_formatter
    
    private
    def initialize
      @error_formatter = ParsingExceptionFormatter.new
    end
    def raize(msg, node = nil)
      if node
        raise ParsingError.new(msg, node.row, node.col, node.source)
      else
        raise ParsingError.new(msg)
      end
    end
    
    public
    def generate_code(nodes, language)
      begin
        language.handle_any nodes
        true
      rescue Exception => e
        ExceptionHelper.show e, @error_formatter
        false
      end
    end
  end
end
