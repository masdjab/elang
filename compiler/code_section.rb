module Elang
  class CodeSection
    attr_reader   :name, :type
    attr_accessor :data
    
    def initialize(name, type, data = "")
      @name = name
      @type = type
      @data = data
    end
    def length
      @data.length
    end
    def size
      @data.length
    end
    def <<(data)
      @data << data
    end
    def to_s
      @data
    end
  end
end
