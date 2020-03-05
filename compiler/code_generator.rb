require './compiler/al_composer'
require './compiler/il_composer'
require './compiler/ml_composer'
require './compiler/name_detector'
require './compiler/lex'
require './compiler/shunting_yard'
require './compiler/constant'
require './compiler/class'
require './compiler/function'
require './compiler/system_function'
require './compiler/function_parameter'
require './compiler/function_id'
require './compiler/variable'
require './compiler/instance_variable'
require './compiler/class_variable'
require './compiler/class_function'
require './compiler/scope'
require './compiler/scope_stack'
require './compiler/symbol_ref'
require './compiler/ast_node'
require './compiler/codeset'
require './compiler/codeset_tool'
require './utils/converter'


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
    
    
    attr_reader   :symbols, :symbol_refs
    attr_accessor :error_formatter
    
    private
    def initialize(language)
      @source = nil
      @language = language
      @scope_stack = []
      @error_formatter = ParsingExceptionFormatter.new
      @composer = nil
    end
    def create_composer
      if @language == "assembly"
        AssemblyLanguageComposer.new(@codeset)
      elsif @language == "machine"
        MachineLanguageComposer.new(@codeset)
      elsif @language == "intermediate"
        IntermediateLanguageComposer.new(@codeset)
      else
        raise "Invalid language '#{@language}'"
      end
    end
    def raize(msg, node = nil)
      if node
        raise ParsingError.new(msg, node.row, node.col, @source)
      else
        raise ParsingError.new(msg)
      end
    end
    def get_sys_function(name)
      SYS_FUNCTIONS.find{|x|x.name == name}
    end
    def code_type
      !current_scope.to_s.empty? ? :subs : :main
    end
    def handle_any(node)
      if node.is_a?(Array)
        node.each{|x|handle_any(x)}
      elsif node.is_a?(Lex::Send)
        @composer.handle_send node
      elsif node.is_a?(Lex::Function)
        @composer.handle_function_def node
      elsif node.is_a?(Lex::Class)
        @composer.handle_class_def node
      elsif node.is_a?(Lex::IfBlock)
        @composer.handle_if node
      elsif node.is_a?(Lex::Node)
        if node.type == :identifier
          @composer.handle_identifier node
        elsif node.type == :string
          @composer.handle_string node
        elsif node.type == :number
          @composer.handle_number node
        else
          raize "Unexpected node type for #{node.inspect}", node
        end
      elsif node.is_a?(Lex::Values)
        node.items.each{|i|handle_any(i)}
      else
        raise "Unexpected node: #{node.inspect}"
      end
    end
    
    public
    def generate_code(nodes, codeset, source = nil)
      @source = source
      @codeset = codeset
      
      begin
        @scope_stack = []
        @composer = create_composer
        NameDetector.new(@codeset).detect_names nodes
        handle_any nodes
        true
      rescue Exception => e
        ExceptionHelper.show e, @error_formatter
        false
      end
    end
  end
end
