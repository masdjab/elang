module Elang
  module Language
    class Base
      attr_reader :symbols, :codeset
      
      def initialize(kernel, symbols, codeset)
        @sys_functions = 
          kernel.functions.map{|k,v|SystemFunction.new(v[:name])} \
          + [SystemFunction.new("_send_to_object")]
        @symbols = symbols
        @codeset = codeset
        @scope_stack = ScopeStack.new
      end
      def raize(msg, node = nil)
        if node
          raise ParsingError.new(msg, node.row, node.col, node.source)
        else
          raise ParsingError.new(msg)
        end
      end
      def get_sys_function(name)
        @sys_functions.find{|x|x.name == name}
      end
      def register_instance_variable(name)
        @symbols.register_instance_variable(Scope.new(current_scope.cls), name)
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
        elsif node.is_a?(Lex::Node)
          if node.type == :identifier
            if ["nil", "false", "true", "self"].include?(node.text)
              get_value node
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
