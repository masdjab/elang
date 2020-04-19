module Elang
  module Language
    class Base
      attr_reader :symbols, :symbol_refs, :codeset
      
      def initialize(kernel, symbols, symbol_refs, codeset)
        @sys_functions = 
          kernel.functions.map{|k,v|SystemFunction.new(v[:name])} \
          + [SystemFunction.new("_send_to_object")]
        @symbols = symbols
        @symbol_refs = symbol_refs
        @codeset = codeset
        @scope_stack = ScopeStack.new
        @break_stack = []
      end
      def raize(msg, node = nil)
        if node
          raise ParsingError.new(msg, node.row, node.col, node.source)
        else
          raise ParsingError.new(msg)
        end
      end
      def current_scope
        @scope_stack.current_scope
      end
      def enter_scope(scope)
        @codeset.enter_subs
        @scope_stack.enter_scope scope
      end
      def leave_scope
        @scope_stack.leave_scope
        @codeset.leave_subs
      end
      def code_type
        !current_scope.to_s.empty? ? :subs : :main
      end
      def get_sys_function(name)
        @sys_functions.find{|x|x.name == name}
      end
      def add_constant_ref(symbol, location)
        @symbol_refs << ConstantRef.new(symbol, current_scope, location, code_type)
      end
      def add_variable_ref(symbol, location)
        @symbol_refs << VariableRef.new(symbol, current_scope, location, code_type)
      end
      def add_function_ref(symbol, location)
        @symbol_refs << FunctionRef.new(symbol, current_scope, location, code_type)
      end
      def add_function_id_ref(symbol, location)
        @symbol_refs << FunctionIdRef.new(symbol, current_scope, location, code_type)
      end
      def register_instance_variable(name)
        @symbols.register_instance_variable(Scope.new(current_scope.cls), name)
      end
      def enter_breakable_block
        @break_stack << []
      end
      def leave_breakable_block
        @break_stack.pop
      end
      def append_break
        @break_stack.last << code_len
      end
      def break_requests
        @break_stack.last
      end
      def resolve_breaks
        break_requests.each do |b|
          jmp_distance = code_len - (b + 3)
          @codeset.code[@codeset.branch][b + 1, 2] = Converter.int2bin(jmp_distance, :word)
        end
      end
      
      public
      def handle_send(node)
      end
      def handle_function_def(node)
      end
      def handle_class_def(node)
      end
      def handle_array(node)
      end
      def handle_if(node)
      end
      def handle_loop(node)
      end
      def handle_while(node)
      end
      def handle_for(node)
      end
      def handle_break(node)
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
              register_instance_variable node.text
              get_value node
            elsif get_sys_function(node.text)
              handle_function_call Lex::Send.new(nil, node, [])
            else
              if (smbl = @symbols.find_nearest(current_scope, node.text)).nil?
                raize "Call to undefined function '#{node.text}' from scope '#{current_scope.to_s}'", node
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
