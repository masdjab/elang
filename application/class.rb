module Elang
  class EClass
    attr_reader :parent, :name
    def initialize(parent, name)
      @parent = parent
      @name = name
    end
  end
end
