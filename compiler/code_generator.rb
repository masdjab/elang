require_relative 'converter'
require_relative 'name_detector'
require_relative 'lex'
require_relative 'shunting_yard'
require_relative 'symbol/_load'


module Elang
  class CodeGenerator
    attr_reader   :symbols
    attr_accessor :error_formatter
    
    private
    def initialize(language)
      @symbols = language.symbols
      @language = language
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
    def generate_code(nodes)
      begin
        @language.handle_any nodes
        true
      rescue Exception => e
        ExceptionHelper.show e, @error_formatter
        false
      end
    end
  end
end
