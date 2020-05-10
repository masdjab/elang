module Elang
  class CodeSection
    attr_reader   :name, :type
    attr_accessor :data
    
    def initialize(name, type, data = "")
      @name = name
      @type = type
      @data = data
    end
    def size
      @data.length
    end
  end
end
