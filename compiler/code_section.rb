module Elang
  class CodeSection
    CODE    = 1
    DATA    = 2
    OTHER   = 3
    
    attr_reader   :name, :type
    attr_accessor :data
    
    def initialize(name, type, data)
      @name = name
      @type = type
      @data = data
    end
    def size
      @data.length
    end
  end
end
