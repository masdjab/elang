module Elang
  class ImportFunction
    attr_reader   :scope, :library, :original_name, :name
    def initialize(scope, library, original_name, name = nil)
      @library = library
      @original_name = original_name
      @name = name ? name : original_name
    end
  end
end
