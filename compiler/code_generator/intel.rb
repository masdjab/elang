module Elang
  module CodeGenerator
    class Intel
      attr_accessor :error_formatter
      
      private
      def initialize(symbols, language)
        @error_formatter = ParsingExceptionFormatter.new
        @symbols = symbols
        @language = language
      end
      def raize(msg, node = nil)
        if node
          raise ParsingError.new(msg, node.row, node.col, @source)
        else
          raise ParsingError.new(msg)
        end
      end
      def get_value(node)
        active_scope = @language.current_scope
        
        if node.type == :identifier
          if (name = node.text) == "nil"
            @language.load_immediate Class::ROOT_CLASS_IDS["NilClass"]
          elsif name == "false"
            @language.load_immediate Class::ROOT_CLASS_IDS["FalseClass"]
          elsif name == "true"
            @language.load_immediate Class::ROOT_CLASS_IDS["TrueClass"]
          elsif name == "self"
            if active_scope.cls.nil?
              raize "Symbol 'self' accessed outside class", node
            else
              @language.get_parameter_by_index 0
            end
          elsif (symbol = @symbols.find_nearest(active_scope, name)).nil?
            raize "Cannot get value from '#{name}' , symbol not defined in scope '#{active_scope.to_s}'", node
          elsif symbol.is_a?(FunctionParameter)
            @language.get_parameter_by_symbol symbol
          elsif symbol.is_a?(InstanceVariable)
            # #(todo)#resolve object id, class id, and instance variable getter address
            if active_scope.cls.nil?
              raize "Instance variable '#{name}' accessed in scope '#{active_scope.to_s}' which is not instance method", node
            elsif (cls = @symbols.find_exact(Scope.new, active_scope.cls)).nil?
              raize "Class #{active_scope.cls} is not defined", name
            else
              @language.get_instance_variable symbol
            end
          elsif symbol.is_a?(ClassVariable)
            @language.get_class symbol
          elsif symbol.scope.root?
            @language.get_global_variable symbol
          elsif symbol.is_a?(Variable)
            @language.get_local_variable symbol
          else
            raize "Cannot get value from '#{name}', symbol type '#{symbol.class}' unknown", node
          end
        elsif node.type == :number
          @language.load_int node.text.index("0x") ? node.text.hex : node.text.to_i
        elsif node.type == :string
          @language.load_str node.text
        end
      end
      def set_value(name)
        if (symbol = @symbols.find_nearest(active_scope = @language.current_scope, name)).nil?
          raize "Cannot set value to '#{name}' , symbol not defined in scope '#{active_scope.to_s}'"
        elsif symbol.is_a?(FunctionParameter)
          @language.set_local_variable symbol
        elsif symbol.is_a?(InstanceVariable)
          # #(todo)#fix binary command
          if active_scope.cls.nil?
            raize "Attempted to write to instance variable '#{name}' in scope '#{active_scope.to_s}' which is not instance method"
          elsif (cls = @symbols.find_exact(Scope.new, active_scope.cls)).nil?
            raize "Class #{active_scope.cls} is not defined"
          else
            @language.set_instance_variable symbol
          end
        elsif symbol.is_a?(ClassVariable)
          @language.set_class symbol
        elsif symbol.scope.root?
          @language.set_global_variable symbol
        elsif symbol.is_a?(Variable)
          @language.set_local_variable symbol
        else
          raize "Cannot set value to '#{name}', symbol type '#{symbol.class}' unknown"
        end
      end
      def prepare_operand(node)
        active_scope = @language.current_scope
        
        if node.is_a?(Array)
          handle_any([node])
        elsif node.type == :string
          @language.load_str node.text
        else
          get_value node
        end
      end
      def prepare_arguments(arguments)
        (0...arguments.count).map{|x|x}.reverse.each do |i|
          handle_any arguments[i]
          @language.push_argument
        end
      end
      def handle_function_call(node)
        name_node = node.cmd
        func_name = name_node.text
        func_args = node.args
        
        if @language.get_sys_function(func_name)
          prepare_arguments func_args
          @language.call_sys_function func_name
        elsif function = @symbols.find_function(func_name)
          prepare_arguments func_args
          @language.call_function function
        else
          raize "Call to undefined function '#{func_name}'", name_node
        end
      end
      def handle_send(node)
        # [., receiver, name, args]
        
        active_scope = @language.current_scope
        rcvr_node = node.receiver
        cmnd_node = node.cmd
        args_node = node.args
        
        if cmnd_node.type == :assign
          if @symbols.find_nearest(active_scope, rcvr_node.text).nil?
            @language.register_variable active_scope, rcvr_node.text
          end
          
          handle_any args_node
          set_value rcvr_node.text
        else
          if (cmnd_node.type == :identifier) && (cmnd_node.text == "new")
            cls_name = rcvr_node.text
            
            if (cls = @symbols.items.find{|x|x.is_a?(Class) && (x.name == cls_name)}).nil?
              raize "Class '#{cls_name}' not defined", rcvr_node
            else
              @language.create_object cls
            end
          else
            func_name = cmnd_node.text
            func_args = args_node ? args_node : []
            
            if rcvr_node.nil?
              func_sym = @symbols.find_nearest(active_scope, func_name)
              
              if func_sym.nil? 
                func_sym = @language.get_sys_function(func_name)
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
              @language.load_immediate args_count
              @language.push_argument
              
              # push object method id
              @language.get_method_id func_name
              @language.push_argument
              
              # push receiver object
              if rcvr_node.nil?
                if active_scope.cls.nil?
                  raize "Send without receiver", rcvr_node
                else
                  @language.get_parameter_by_index 0
                  @language.push_argument
                end
              else
                handle_any rcvr_node
                @language.push_argument
              end
              
              # call _send_to_object
              @language.call_sys_function "_send_to_object"
            end
          end
        end
      end
      def handle_function_def(node)
        active_scope = @language.current_scope
        
        rcvr_name = node.receiver ? node.receiver.text : active_scope.cls
        func_name = node.name.text
        func_args = node.params
        func_body = node.body
        
        function = @symbols.find_exact(active_scope, func_name)
        function.offset = @language.code_len
        params_count = func_args.count + (rcvr_name ? 2 : 0)
        
        @language.define_function(func_name, params_count) do
          handle_any func_body
        end
      end
      def handle_class_def(node)
        cls_name = node.name.text
        cls_prnt = node.parent ? node.parent.text : nil
        
        @language.define_class(cls_name) do
          handle_any node.body
        end
      end
      def handle_array(node)
        @language.begin_array
        
        node.values.each do |v|
          handle_any v
          @language.array_append_item
        end
        
        @language.end_array
      end
      def handle_if(node)
        cond_node = node.condition
        exp1_node = node.body1
        exp2_node = node.body2
        
        handle_any cond_node
        
        @language.push_argument
        @language.call_sys_function "_is_true"
        offset1 = @language.new_jump_source(:nz)
        
        handle_any exp1_node
        
        if !exp2_node.nil?
          offset2 = @language.new_jump_source(nil)
          @language.set_jump_target offset1
          handle_any exp2_node
          @language.set_jump_target offset2
        else
          @language.set_jump_target offset1
        end
      end
      def handle_loop(node)
        @language.enter_breakable_block
        offset = @language.new_jump_target
        node.body.each{|b|handle_any(b)}
        @language.set_jump_source offset, nil
        @language.resolve_breaks
        @language.leave_breakable_block
      end
      def handle_while(node)
        @language.enter_breakable_block
        target1 = @language.new_jump_target
        handle_any node.condition
        @language.push_argument
        @language.call_sys_function "_is_true"
        source2 = @language.new_jump_source(:nz)
        handle_any node.body
        @language.set_jump_source target1, nil
        @language.set_jump_target source2
        @language.resolve_breaks
        @language.leave_breakable_block
      end
      def handle_for(node)
        raize "Syntax for is not supported yet", node
        #@language.enter_breakable_block
        #offset = @language.code_len
        #jmp_target = Converter.int2hex(offset - (@language.code_len + 3), :word, :be)
        #append_code hex2bin("E9#{jmp_target}")
        #@language.resolve_breaks
        #@language.leave_breakable_block
      end
      def handle_break(node)
        @language.break_block
      end
      def handle_any(node)
        if node.is_a?(Array)
          node.each{|x|handle_any(x)}
        elsif node.is_a?(Lex::Send)
          handle_send node
        elsif node.is_a?(Lex::Function)
          handle_function_def node
        elsif node.is_a?(Lex::Class)
          handle_class_def node
        elsif node.is_a?(Lex::Array)
          handle_array node
        elsif node.is_a?(Lex::IfBlock)
          handle_if node
        elsif node.is_a?(Lex::LoopBlock)
          handle_loop node
        elsif node.is_a?(Lex::WhileBlock)
          handle_while node
        elsif node.is_a?(Lex::ForBlock)
          handle_for node
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
              @language.register_instance_variable node.text
              get_value node
            elsif @language.get_sys_function(node.text)
              handle_function_call Lex::Send.new(nil, node, [])
            else
              if (smbl = @symbols.find_nearest(@language.current_scope, node.text)).nil?
                raize "Call to undefined function '#{node.text}' from scope '#{@language.current_scope.to_s}'", node
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
      
      public
      def generate_code(nodes)
        begin
          handle_any nodes
          true
        rescue Exception => e
          ExceptionHelper.show e, @error_formatter
          false
        end
      end
    end
  end
end
