module Elang
  module Language
    class IntelCodeGenerator
      def initialize(symbols, machinery)
        @symbols = symbols
        @machinery = machinery
      end
      def raize(msg, node = nil)
        if node
          raise ParsingError.new(msg, node.row, node.col, @source)
        else
          raise ParsingError.new(msg)
        end
      end
      def get_value(node)
        active_scope = @machinery.current_scope
        
        if node.type == :identifier
          if (name = node.text) == "nil"
            @machinery.load_immediate Class::ROOT_CLASS_IDS["NilClass"]
          elsif name == "false"
            @machinery.load_immediate Class::ROOT_CLASS_IDS["FalseClass"]
          elsif name == "true"
            @machinery.load_immediate Class::ROOT_CLASS_IDS["TrueClass"]
          elsif name == "self"
            if active_scope.cls.nil?
              raize "Symbol 'self' accessed outside class", node
            else
              @machinery.get_parameter_by_index 0
            end
          elsif (symbol = @symbols.find_nearest(active_scope, name)).nil?
            raize "Cannot get value from '#{name}' , symbol not defined in scope '#{active_scope.to_s}'", node
          elsif symbol.is_a?(FunctionParameter)
            @machinery.get_parameter_by_symbol symbol
          elsif symbol.is_a?(InstanceVariable)
            # #(todo)#resolve object id, class id, and instance variable getter address
            if active_scope.cls.nil?
              raize "Instance variable '#{name}' accessed in scope '#{active_scope.to_s}' which is not instance method", node
            elsif (cls = @symbols.find_exact(Scope.new, active_scope.cls)).nil?
              raize "Class #{active_scope.cls} is not defined", name
            else
              @machinery.get_instance_variable symbol
            end
          elsif symbol.is_a?(ClassVariable)
            @machinery.get_class symbol
          elsif symbol.scope.root?
            @machinery.get_global_variable symbol
          elsif symbol.is_a?(Variable)
            @machinery.get_local_variable symbol
          else
            raize "Cannot get value from '#{name}', symbol type '#{symbol.class}' unknown", node
          end
        elsif node.type == :number
          @machinery.load_immediate node.text.index("0x") ? node.text.hex : node.text.to_i
        elsif node.type == :string
          @machinery.load_str node.text
        end
      end
      def set_value(name)
        if (symbol = @symbols.find_nearest(active_scope = @machinery.current_scope, name)).nil?
          raize "Cannot set value to '#{name}' , symbol not defined in scope '#{active_scope.to_s}'"
        elsif symbol.is_a?(FunctionParameter)
          @machinery.set_local_variable symbol
        elsif symbol.is_a?(InstanceVariable)
          # #(todo)#fix binary command
          if active_scope.cls.nil?
            raize "Attempted to write to instance variable '#{name}' in scope '#{active_scope.to_s}' which is not instance method"
          elsif (cls = @symbols.find_exact(Scope.new, active_scope.cls)).nil?
            raize "Class #{active_scope.cls} is not defined"
          else
            @machinery.set_instance_variable symbol
          end
        elsif symbol.is_a?(ClassVariable)
          @machinery.set_class symbol
        elsif symbol.scope.root?
          @machinery.set_global_variable symbol
        elsif symbol.is_a?(Variable)
          @machinery.set_local_variable symbol
        else
          raize "Cannot set value to '#{name}', symbol type '#{symbol.class}' unknown"
        end
      end
      def prepare_operand(node)
        active_scope = @machinery.current_scope
        
        if node.is_a?(Array)
          handle_any([node])
        elsif node.type == :string
          @machinery.load_str node.text
        else
          get_value node
        end
      end
      def prepare_arguments(arguments)
        (0...arguments.count).map{|x|x}.reverse.each do |i|
          handle_any arguments[i]
          @machinery.push_argument
        end
      end
      def handle_function_call(node)
        name_node = node.cmd
        func_name = name_node.text
        func_args = node.args
        
        if @machinery.get_sys_function(func_name)
          prepare_arguments func_args
          @machinery.call_sys_function func_name
        elsif function = @symbols.find_function(func_name)
          prepare_arguments func_args
          @machinery.call_function function
        else
          raize "Call to undefined function '#{func_name}'", name_node
        end
      end
      def handle_send(node)
        # [., receiver, name, args]
        
        active_scope = @machinery.current_scope
        rcvr_node = node.receiver
        cmnd_node = node.cmd
        args_node = node.args
        
        if cmnd_node.type == :assign
          if @symbols.find_nearest(active_scope, rcvr_node.text).nil?
            @machinery.register_variable active_scope, rcvr_node.text
          end
          
          handle_any args_node
          set_value rcvr_node.text
        else
          if (cmnd_node.type == :identifier) && (cmnd_node.text == "new")
            cls_name = rcvr_node.text
            
            if (cls = @symbols.items.find{|x|x.is_a?(Class) && (x.name == cls_name)}).nil?
              raize "Class '#{cls_name}' not defined", rcvr_node
            else
              @machinery.create_object cls
            end
          else
            func_name = cmnd_node.text
            func_args = args_node ? args_node : []
            
            if rcvr_node.nil?
              func_sym = @symbols.find_nearest(active_scope, func_name)
              
              if func_sym.nil? 
                func_sym = @machinery.get_sys_function(func_name)
              end
              
              if active_scope.cls.nil?
                is_obj_method = false
              elsif func_sym.nil?
                raize "Undefined function '#{func_name}' in scope '#{active_scope.to_s}'", node[2]
              elsif func_sym.is_a?(Function)
                is_obj_method = func_sym.scope.cls == active_scope.cls
              elsif func_sym.is_a?(SystemFunction)
                is_obj_method = false
              else
                raize "Unknown error when handling handle_send for function '#{func_name}' in scope '#{active_scope.to_s}'.", node[2]
              end
            else
              is_obj_method = true
            end
            
            if !is_obj_method
              handle_function_call node
            else
              prepare_arguments func_args
              
              # push args count
              args_count = func_args.count
              @machinery.load_immediate args_count
              @machinery.push_argument
              
              # push object method id
              @machinery.get_method_id func_name
              @machinery.push_argument
              
              # push receiver object
              if rcvr_node.nil?
                if active_scope.cls.nil?
                  raize "Send without receiver", rcvr_node
                else
                  @machinery.get_parameter_by_index 0
                  @machinery.push_argument
                end
              else
                handle_any rcvr_node
                @machinery.push_argument
              end
              
              # call _send_to_object
              @machinery.call_sys_function "_send_to_object"
            end
          end
        end
      end
      def handle_function_def(node)
        active_scope = @machinery.current_scope
        
        rcvr_name = node.receiver ? node.receiver.text : active_scope.cls
        func_name = node.name.text
        func_args = node.params
        func_body = node.body
        
        #(todo)#count local_var_count
        @machinery.enter_scope Scope.new(active_scope.cls, func_name)
        
        function = @symbols.find_exact(active_scope, func_name)
        function.offset = @machinery.code_len
        local_variables = @symbols.items.select{|x|(x.scope.to_s == @machinery.current_scope.to_s) && x.is_a?(Variable)}
        local_var_count = local_variables.count
        params_count = func_args.count + (rcvr_name ? 2 : 0)
        
        @machinery.define_function(active_scope, params_count, local_variables) do
          handle_any func_body
        end
        
        @machinery.leave_scope
      end
      def handle_class_def(node)
        cls_name = node.name.text
        cls_prnt = node.parent ? node.parent.text : nil
        
        @machinery.enter_scope Scope.new(cls_name)
        handle_any node.body
        @machinery.leave_scope
      end
      def handle_array(node)
        @machinery.begin_array
        
        node.values.each do |v|
          handle_any v
          @machinery.array_append_item
        end
        
        @machinery.end_array
      end
      def handle_if(node)
        cond_node = node.condition
        exp1_node = node.body1
        exp2_node = node.body2
        
        handle_any cond_node
        
        @machinery.push_argument
        @machinery.call_sys_function "_is_true"
        offset1 = @machinery.new_jump_source(:nz)
        
        handle_any exp1_node
        
        if !exp2_node.nil?
          offset2 = @machinery.new_jump_source(nil)
          @machinery.set_jump_target offset1
          handle_any exp2_node
          @machinery.set_jump_target offset2
        else
          @machinery.set_jump_target offset1
        end
      end
      def handle_loop(node)
        @machinery.enter_breakable_block
        offset = @machinery.new_jump_target
        node.body.each{|b|handle_any(b)}
        @machinery.set_jump_source offset, nil
        @machinery.resolve_breaks
        @machinery.leave_breakable_block
      end
      def handle_while(node)
        @machinery.enter_breakable_block
        target1 = @machinery.new_jump_target
        handle_any node.condition
        @machinery.push_argument
        @machinery.call_sys_function "_is_true"
        source2 = @machinery.new_jump_source(:nz)
        handle_any node.body
        @machinery.set_jump_source target1, nil
        @machinery.set_jump_target source2
        @machinery.resolve_breaks
        @machinery.leave_breakable_block
      end
      def handle_for(node)
        raize "Syntax for is not supported yet", node
        #@machinery.enter_breakable_block
        #offset = @machinery.code_len
        #jmp_target = Converter.int2hex(offset - (@machinery.code_len + 3), :word, :be)
        #append_code hex2bin("E9#{jmp_target}")
        #@machinery.resolve_breaks
        #@machinery.leave_breakable_block
      end
      def handle_break(node)
        @machinery.break_block
      end
      def handle_any(node)
        if node.is_a?(Array)
          node.each{|x|handle_any(x)}
        elsif node.is_a?(Lex::Send)
          self.handle_send node
        elsif node.is_a?(Lex::Function)
          self.handle_function_def node
        elsif node.is_a?(Lex::Class)
          self.handle_class_def node
        elsif node.is_a?(Lex::Array)
          self.handle_array node
        elsif node.is_a?(Lex::IfBlock)
          self.handle_if node
        elsif node.is_a?(Lex::LoopBlock)
          self.handle_loop node
        elsif node.is_a?(Lex::WhileBlock)
          self.handle_while node
        elsif node.is_a?(Lex::ForBlock)
          self.handle_for node
        elsif node.is_a?(Lex::Node)
          if node.type == :identifier
            if ["nil", "false", "true", "self"].include?(node.text)
              get_value node
            elsif ["break"].include?(node.text)
              handle_break node
            elsif node.text.index("@@")
              register_class_variable node.text
              get_value node
            elsif node.text.index("@")
              @machinery.register_instance_variable node.text
              get_value node
            elsif @machinery.get_sys_function(node.text)
              handle_function_call Lex::Send.new(nil, node, [])
            else
              if (smbl = @symbols.find_nearest(@machinery.current_scope, node.text)).nil?
                raize "Call to undefined function '#{node.text}' from scope '#{@machinery.current_scope.to_s}'", node
              elsif smbl.is_a?(Function)
                handle_function_call node
              else
                get_value node
              end
            end
          elsif [:string, :number].include?(node.type)
            get_value node
          end
        elsif node.is_a?(Lex::Values)
          node.items.each{|i|handle_any(i)}
        else
          raise "Unexpected node: #{node.inspect}"
        end
      end
    end
  end
end
