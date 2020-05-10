module Elang
  class CodePad
    attr_reader   :symbols, :symbol_refs
    attr_accessor :binary_code
    
    private
    def initialize(symbols = Symbols.new, symbol_refs = [], binary_code = "")
      @symbols = symbols
      @symbol_refs = symbol_refs
      @binary_code = binary_code
      @scope_stack = ScopeStack.new
    end
    
    public
    def hex2bin(h)
      Elang::Converter.hex2bin(h)
    end
    def code_len
      @binary_code.length
    end
    def append_bin(code)
      @binary_code << code
    end
    def append_hex(code)
      append_bin hex2bin(code)
    end
    def register_variable(scope, name)
      @symbols.register_variable(scope, name)
    end
    def register_instance_variable(scope, name)
      @symbols.register_instance_variable(scope, name)
    end
    def register_label(scope, name, ref_context = nil)
      @symbols.register_label(scope, name, code_len, ref_context)
    end
    def add_constant_ref(symbol, location, ref_context = nil)
      @symbol_refs << ConstantRef.new(symbol, current_scope, location, ref_context)
    end
    def add_variable_ref(symbol, location, ref_context = nil)
      @symbol_refs << VariableRef.new(symbol, current_scope, location, ref_context)
    end
    def add_function_ref(symbol, location, ref_context = nil)
      @symbol_refs << FunctionRef.new(symbol, current_scope, location, ref_context)
    end
    def add_function_id_ref(symbol, location, ref_context = nil)
      @symbol_refs << FunctionIdRef.new(symbol, current_scope, location, ref_context)
    end
    def add_short_code_ref(symbol, location, ref_context = nil)
      @symbol_refs << ShortCodeRef.new(symbol, current_scope, location, ref_context)
    end
    def add_near_code_ref(symbol, location, ref_context = nil)
      @symbol_refs << NearCodeRef.new(symbol, current_scope, location, ref_context)
    end
    def add_far_code_ref(symbol, location, ref_context = nil)
      @symbol_refs << FarCodeRef.new(symbol, current_scope, location, ref_context)
    end
    def current_scope
      @scope_stack.current_scope
    end
    def enter_scope(scope)
      @scope_stack.enter_scope scope
    end
    def leave_scope
      @scope_stack.leave_scope
    end
  end
end
