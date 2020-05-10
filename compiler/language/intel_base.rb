module Elang
  module Language
    class IntelBase
      attr_reader :codeset
      
      private
      def initialize(build_config)
        @build_config = build_config
        @sys_functions = 
          @build_config.kernel.functions.map{|k,v|SystemFunction.new(v[:name])} \
          + [SystemFunction.new("_send_to_object")]
        @symbols = @build_config.symbols
        @symbol_refs = @build_config.symbol_refs
        @codeset = @build_config.codeset
        @scope_stack = ScopeStack.new
        @break_stack = []
        
        @codeset.create_section "main", :code
        @codeset.create_section "subs", :code
      end
      def hex2bin(h)
        Elang::Converter.hex2bin(h)
      end
      def intobj(value)
        (value << 1) | 1
      end
      def make_int(value)
        (value << 1) | (value < 0 ? 0x80000000 : 0) | 1
      end
      def section_name
        !current_scope.to_s.empty? ? "subs" : "main"
      end
      def code_len
        @codeset.length
      end
      def get_sys_function(name)
        @sys_functions.find{|x|x.name == name}
      end
      def append_code(code)
        @codeset.append code
      end
      def add_constant_ref(symbol, location)
        @symbol_refs << ConstantRef.new(symbol, current_scope, location, section_name)
      end
      def add_variable_ref(symbol, location)
        @symbol_refs << VariableRef.new(symbol, current_scope, location, section_name)
      end
      def add_function_ref(symbol, location)
        @symbol_refs << FunctionRef.new(symbol, current_scope, location, section_name)
      end
      def add_function_id_ref(symbol, location)
        @symbol_refs << FunctionIdRef.new(symbol, current_scope, location, section_name)
      end
      def register_variable(scope, name)
        @symbols.register_variable(scope, name)
      end
      def append_break
        @break_stack.last << code_len
      end
      def break_requests
        @break_stack.last
      end
      
      public
      def code_len
        @codeset.length
      end
      def current_scope
        @scope_stack.current_scope
      end
      def enter_scope(scope)
        @codeset.select_section "subs"
        @scope_stack.enter_scope scope
      end
      def leave_scope
        @scope_stack.leave_scope
        @codeset.select_section "main"
      end
      def get_sys_function(name)
        @sys_functions.find{|x|x.name == name}
      end
      def add_constant_ref(symbol, location)
        @symbol_refs << ConstantRef.new(symbol, current_scope, location, section_name)
      end
      def add_variable_ref(symbol, location)
        @symbol_refs << VariableRef.new(symbol, current_scope, location, section_name)
      end
      def add_function_ref(symbol, location)
        @symbol_refs << FunctionRef.new(symbol, current_scope, location, section_name)
      end
      def add_function_id_ref(symbol, location)
        @symbol_refs << FunctionIdRef.new(symbol, current_scope, location, section_name)
      end
      def register_variable(scope, name)
        @symbols.register_variable(scope, name)
      end
      def register_instance_variable(name)
        @symbols.register_instance_variable(Scope.new(current_scope.cls), name)
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
