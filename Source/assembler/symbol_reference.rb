module Elang
  module Assembler
    class SymbolReference
      SIZE_BYTE = 1
      SIZE_WORD = 2
      SIZE_DWORD = 3
      
      attr_accessor :context, :identifier, :byte_size, :location, :origin
      def initialize(context, identifier, byte_size, location, origin = 0)
        @context = context
        @identifier = identifier
        @byte_size = byte_size
        @location = location
        @origin = origin
      end
    end
  end
end
