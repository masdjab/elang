module Elang
  module Assembler
    class AppSection
      CODE = 1
      TEXT = 2
      DATA = 3
      RELOCATION = 4
      IMPORT = 5
      EXPORT = 6
      APP_INFO = 7
      
      attr_accessor :name, :flag, :offset, :size, :body
      def initialize
        @name = name
        @flag = flag
        @offset = offset
        @size = size
        @body = body
      end
    end
  end
end
