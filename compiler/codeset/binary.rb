module Elang
  module Codeset
    class Binary < Base
      attr_reader :symbol_refs
      
      def initialize
        @symbol_refs = []
        super
      end
      def add_constant_ref(scope, symbol, location, code_type)
        @symbol_refs << ConstantRef.new(symbol, scope, location, code_type)
      end
      def add_variable_ref(scope, symbol, location, code_type)
        @symbol_refs << VariableRef.new(symbol, scope, location, code_type)
      end
      def add_function_ref(scope, symbol, location, code_type)
        @symbol_refs << FunctionRef.new(symbol, scope, location, code_type)
      end
      def add_function_id_ref(scope, symbol, location, code_type)
        @symbol_refs << FunctionIdRef.new(symbol, scope, location, code_type)
      end
    end
  end
end
