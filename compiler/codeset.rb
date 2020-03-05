require './compiler/symbols'

module Elang
  class CodeSet
    attr_reader   :symbols, :symbol_refs, :main_code, :subs_code, :code_branch
    
    def initialize
      @symbols = Symbols.new
      @symbol_refs = []
      @main_code = ""
      @subs_code = ""
      
      enter_subs
      leave_subs
    end
    def enter_subs
      @code_branch = @subs_code
    end
    def leave_subs
      @code_branch = @main_code
    end
    def append_code(code)
      @code_branch << code if !code.empty?
    end
    def code_len
      @code_branch.length
    end
    def add_constant_ref(scope, symbol, location)
      @symbol_refs << ConstantRef.new(symbol, scope, location, code_type)
    end
    def add_variable_ref(scope, symbol, location)
      @symbol_refs << VariableRef.new(symbol, scope, location, code_type)
    end
    def add_function_ref(scope, symbol, location)
      @symbol_refs << FunctionRef.new(symbol, scope, location, code_type)
    end
    def add_function_id_ref(scope, symbol, location)
      @symbol_refs << FunctionIdRef.new(symbol, scope, location, code_type)
    end
    def register_variable(scope, name)
      receiver = Elang::Variable.new(scope, name)
      @symbols.add receiver
      receiver
    end
    def register_instance_variable(scope, name)
      scope = Scope.new(scope.cls)
      ivars = @symbols.items.select{|x|(x.scope.cls == scope.cls) && x.is_a?(InstanceVariable)}
      
      if (receiver = ivars.find{|x|x.name == name}).nil?
        index = ivars.inject(0){|a,b|b.index >= a ? b.index + 1 : a}
        receiver = InstanceVariable.new(scope, name, index)
        @symbols.add receiver
      end
      
      receiver
    end
    def register_class(name, parent)
      scope = Scope.new
      clist = @symbols.items.select{|x|x.is_a?(Class)}
      
      if (cls = clist.find{|x|x.name == name}).nil?
        idx = clist.inject(0){|a,b|b.index >= a ? b.index + 1 : a}
        @symbols.add(cls = Class.new(scope, name, parent, idx))
      end
      
      cls
    end
    def register_class_variable(scope, name)
      receiver = ClassVariable.new(scope, name)
      @symbols.add receiver
      receiver
    end
    def register_function(scope, rcvr_name, func_name, func_args)
      if (fun = @symbols.items.find{|x|(x.name == func_name) && x.is_a?(Function) && (x.scope.to_s == scope.to_s)}).nil?
        fun = Function.new(scope, rcvr_name, func_name, func_args, 0)
        @symbols.add(fun)
      end
      
      fun
    end
  end
end
