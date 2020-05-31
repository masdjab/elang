module Elang
  class NameDetector
    def initialize(symbols)
      @symbols = symbols
      @scope_stack = ScopeStack.new
      @context = CodeContext.new("subs")
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
    def register_identifier(name)
      if @symbols.items.find{|x|(x.scope.to_s == current_scope.to_s) && (x.name == name)}.nil?
        register_variable name
      end
    end
=begin
    def detect_names_from_node(node)
      if node.is_a?(Array)
        node.each{|x|detect_names_from_node(x)}
      elsif node.is_a?(Lex::Function)
        active_scope = current_scope
        rcvr_name = node.receiver ? node.receiver.text : nil
        func_name = node.name.text
        func_args = node.params
        func_body = node.body
        
        if !active_scope.fun.nil?
          raize "Function cannot be nested", node
        else
          function = register_function(rcvr_name, func_name, func_args)
          enter_scope Scope.new(active_scope.cls, func_name)
          
          (0...func_args.count).each do |i|
            param = FunctionParameter.new(current_scope, func_args[i].text, i)
            @symbols.add param
          end
          
          detect_names_from_node func_body
          leave_scope
        end
      elsif node.is_a?(Lex::Class)
        cls_name = node.name.text
        cls_parent = node.parent ? node.parent.text : nil
        cls_body = node.body
        
        if !(active_scope = current_scope).cls.nil?
          raize "Class cannot be nested", node
        else
          cls_object = register_class(cls_name, cls_parent)
          enter_scope Scope.new(cls_name)
          detect_names_from_node cls_body
          leave_scope
        end
      elsif node.is_a?(Lex::Send)
        left_var = node.receiver
        active_scope = current_scope
        
        if left_var.is_a?(Elang::Lex::Node)
          if left_var.type == :identifier
            var_name = left_var.text
            
            if (receiver = @symbols.find_nearest(active_scope, var_name)).nil?
              if var_name.index("@@") == 0
                # #(todo)#class variable
                receiver = register_class_variable(var_name)
              elsif var_name.index("@") == 0
                # instance variable
                receiver = register_instance_variable(var_name)
              else
                # local variable
                receiver = register_variable(var_name)
              end
            end
          end
        end
        
        detect_names_from_node node.args
      elsif node.is_a?(Lex::IfBlock)
        detect_names_from_node node.body1
        detect_names_from_node node.body2 if node.body2
      elsif node.respond_to?(:body)
        detect_names_from_node node.body
      elsif node.is_a?(Lex::Node)
        # ignored
      else
        # puts "Skipped from name detection: #{node.class}"
      end
    end
    
    public
    def detect_names(nodes)
      detect_names_from_node nodes
    end
=end
  end
end
