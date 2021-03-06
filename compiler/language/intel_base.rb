module Elang
  module Language
    class IntelBase
      attr_reader :codeset
      
      private
      def initialize(build_config)
        @build_config = build_config
        @sys_functions = @build_config.kernel.functions
        @symbols = @build_config.symbols
        @symbol_refs = @build_config.symbol_refs
        @codeset = @build_config.codeset
        @codepad = Elang::CodePad.new(@symbols, @symbol_refs)
        @break_stack = []
        
        @codeset["main"] = CodeSection.new("main", :code, "")
        @codeset["subs"] = CodeSection.new("subs", :code, "")
        @codeset["cons"] = CodeSection.new("cons", :data, "")
        
        @current_section = "main"
        @codepad.set_code_page @codeset[@current_section]
      end
      def intobj(value)
        (value << 1) | 1
      end
      def make_int(value)
        (value << 1) | (value < 0 ? 0x80000000 : 0) | 1
      end
      #def section_name
      #  !current_scope.to_s.empty? ? "subs" : "main"
      #end
      def code_len
        @codepad.code_len
      end
      def append_bin(code)
        @codepad.append_bin code
      end
      def append_hex(code)
        @codepad.append_hex code
      end
      def append_break
        @break_stack.last << code_len
      end
      def break_requests
        @break_stack.last
      end
      def enter_scope(scope)
        @current_section = "subs"
        @codepad.set_code_page @codeset[@current_section]
        @codepad.enter_scope scope
      end
      def leave_scope
        @codepad.leave_scope
        @current_section = "main"
        @codepad.set_code_page @codeset[@current_section]
      end
      
      public
      def current_scope
        @codepad.current_scope
      end
      def get_sys_function(name)
        @sys_functions.find{|x|x.name == name}
      end
      def register_constant(scope, name, value)
        @codepad.register_constant scope, name, value
      end
      def register_variable(scope, name)
        @codepad.register_variable scope, name
      end
      def register_instance_variable(scope, name)
        @codepad.register_instance_variable scope, name
      end
      def add_constant_ref(symbol, location)
        @codepad.add_constant_ref symbol, location
      end
      def add_variable_ref(symbol, location)
        @codepad.add_variable_ref symbol, location
      end
      def add_function_ref(symbol, location)
        @codepad.add_function_ref symbol, location
      end
      def add_function_id_ref(name, location)
        @codepad.add_function_id_ref name, location
      end
      def load_immediate(value)
      end
      def load_str(text)
      end
      def get_global_variable(symbol)
      end
      def set_global_variable(symbol)
      end
      def get_local_variable(symbol)
      end
      def set_local_variable(symbol)
      end
      def get_instance_variable(symbol)
      end
      def set_instance_variable(symbol)
      end
      def get_parameter_by_index(index)
      end
      def get_parameter_by_symbol(symbol)
      end
      def get_class(symbol)
      end
      def set_class(symbol)
      end
      def get_method_id(func_name)
      end
      def new_jump_source(condition = nil)
      end
      def set_jump_target(offset)
      end
      def new_jump_target
      end
      def set_jump_source(target, condition = nil)
      end
      def push_argument
      end
      def call_function(symbol)
      end
      def call_sys_function(func_name)
      end
      def create_object(cls)
      end
      def define_function(scope, params_count, variables)
      end
      def begin_array
      end
      def array_append_item
      end
      def end_array
      end
      def jump(target)
      end
      def enter_breakable_block
      end
      def leave_breakable_block
      end
      def break_block
      end
      def resolve_breaks
      end
    end
  end
end
