module Elang
  class EClass
    attr_reader   :class_id, :name, :functions, :ivars
    
    @@class_id = 0
    
    def initialize(name)
      @@class_id += 1
      @class_id = @@class_id
      @name = name
      @functions = []
      @ivars = []
    end
  end
end
