require_relative 'name_detector'
require_relative 'lex'
require_relative 'shunting_yard'
require_relative 'symbol/_load'
require_relative '../utils/converter'


module Elang
  class CodeGenerator
    SYS_FUNCTIONS = 
      [
        SystemFunction.new("_int_pack"), 
        SystemFunction.new("_int_unpack"), 
        SystemFunction.new("_int_add"), 
        SystemFunction.new("_int_subtract"), 
        SystemFunction.new("_int_multiply"), 
        SystemFunction.new("_int_divide"), 
        SystemFunction.new("_int_and"), 
        SystemFunction.new("_int_or"), 
        SystemFunction.new("_is_equal"), 
        SystemFunction.new("_is_not_equal"), 
        SystemFunction.new("_is_true"), 
        SystemFunction.new("_get_obj_var"), 
        SystemFunction.new("_set_obj_var"), 
        SystemFunction.new("_send_to_object"), 
        SystemFunction.new("_mem_block_init"), 
        SystemFunction.new("_mem_alloc"), 
        SystemFunction.new("_mem_dealloc"), 
        SystemFunction.new("_mem_get_data_offset"), 
        SystemFunction.new("_alloc_object"), 
        SystemFunction.new("_load_str"), 
        SystemFunction.new("_int_to_h8"), 
        SystemFunction.new("_int_to_h16"), 
        SystemFunction.new("_int_to_s"), 
        SystemFunction.new("_str_length"), 
        SystemFunction.new("_str_lcase"), 
        SystemFunction.new("_str_ucase"), 
        SystemFunction.new("_str_concat"), 
        SystemFunction.new("_str_append"), 
        SystemFunction.new("_str_substr"), 
        SystemFunction.new("_unassign_object"), 
        SystemFunction.new("_collect_garbage"), 
        SystemFunction.new("print"), 
        SystemFunction.new("puts")
      ]
    
    
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
    def get_sys_function(name)
      SYS_FUNCTIONS.find{|x|x.name == name}
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
