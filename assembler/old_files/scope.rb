module Elang
  module Assembler
    class Scope
      attr_accessor :scope, :name, :type
      def initialize(scope, name, type)
        @scope = scope
        @name = name
        @type = type
      end
    end
  end
end
