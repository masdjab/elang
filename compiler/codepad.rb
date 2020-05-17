module Elang
  class CodePad
    attr_reader :symbols, :symbol_refs, :code_page
    
    private
    def initialize(symbols = Symbols.new, symbol_refs = [], code_page = nil)
      @symbols = symbols
      @symbol_refs = symbol_refs
      @scope_stack = ScopeStack.new
      @code_page = code_page
    end
    def hex2bin(h)
      Elang::Converter.hex2bin(h)
    end
    def get_context
      @code_page ? @code_page.context : nil
    end
    
    public
    def set_code_page(code_page)
      @code_page = code_page
    end
    def code_len
      @code_page ? @code_page.data.length : nil
    end
    def append_bin(code)
      @code_page.data << code
    end
    def append_hex(code)
      append_bin hex2bin(code)
    end
    def register_constant(scope, name, value)
      @symbols.register_constant(scope, name, value)
    end
    def register_variable(scope, name)
      @symbols.register_variable(get_context, scope, name)
    end
    def register_instance_variable(scope, name)
      @symbols.register_instance_variable(get_context, scope, name)
    end
    def register_label(scope, name)
      @symbols.register_label(get_context, scope, name, code_len)
    end
    def add_constant_ref(symbol, location)
      @symbol_refs << ConstantRef.new(symbol, get_context, location)
    end
    def add_variable_ref(symbol, location)
      @symbol_refs << VariableRef.new(symbol, get_context, location)
    end
    def add_function_ref(symbol, location)
      @symbol_refs << FunctionRef.new(symbol, get_context, location)
    end
    def add_function_id_ref(name, location)
      function_id = FunctionId.new(get_context, current_scope, name)
      @symbol_refs << FunctionIdRef.new(function_id, get_context, location)
    end
    def add_short_code_ref(symbol, location)
      @symbol_refs << ShortCodeRef.new(symbol, get_context, location)
    end
    def add_near_code_ref(symbol, location)
      @symbol_refs << NearCodeRef.new(symbol, get_context, location)
    end
    def add_far_code_ref(symbol, location)
      @symbol_refs << FarCodeRef.new(symbol, get_context, location)
    end
    def add_abs_code_ref(symbol, location)
      @symbol_refs << AbsCodeRef.new(symbol, get_context, location)
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
