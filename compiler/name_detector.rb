require_relative 'scope'

module Elang
  class NameDetector
    def initialize(symbols)
      @symbols = symbols
      @scope_stack = ScopeStack.new
      #@context = CodeContext.new("subs")
      @context = nil
    end
    def get_context
      @context
    end
    def current_scope
      @scope_stack.current_scope
    end
    def enter_scope(type, name)
      cs = current_scope
      sc = type == :class ? name : cs.cls
      sf = type == :function ? name : nil
      @scope_stack.enter_scope(Scope.new(sc, sf))
    end
    def leave_scope
      @scope_stack.leave_scope
    end
    def register_variable(name)
      @symbols.register_variable(get_context, current_scope, name)
    end
    def register_instance_variable(name)
      @symbols.register_instance_variable(get_context, current_scope, name)
    end
    def register_class(name, parent)
      @symbols.register_class(get_context, name, parent)
    end
    def register_class_variable(name)
      @symbols.register_class_variable(get_context, current_scope, name)
    end
    def register_function(rcvr, name, args)
      active_scope = current_scope
      parent_scope = Scope.new(active_scope.cls, nil)
      
      @symbols.register_function get_context, parent_scope, rcvr, name, args
      
      (0...args.count).each do |i|
        @symbols.add FunctionParameter.new(active_scope, args[i].text, i)
      end
    end
    def import_function(library, original_name, name)
      @symbols.add ImportFunction.new(current_scope, library.text, original_name.text, name ? name.text : nil)
    end
    def register_identifier(name)
      if @symbols.items.find{|x|(x.scope.to_s == current_scope.to_s) && (x.name == name)}.nil?
        register_variable name
      end
    end
  end
end
