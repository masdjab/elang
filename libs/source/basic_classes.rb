class FalseClass
  def object_id
    self
  end
  def nil?
    false
  end
  def is_a?(cls)
  end
  def to_s
    "FalseClass"
  end
end

class TrueClass
  def object_id
    self
  end
  def nil?
    false
  end
  def is_a?(cls)
  end
  def to_s
    "TrueClass"
  end
end

class Nil
  def object_id
    self
  end
  def nil?
    true
  end
  def is_a?(cls)
    cls.nil?
  end
  def to_s
    ""
  end
end

class Integer
  def object_id
    self
  end
  def nil?
    false
  end
  def is_a?(cls)
  end
  def to_s
  end
end

class Object
  def initialize
  end
  def destroy
  end
  def nil?
    self
  end
  def is_a?(cls)
  end
  def to_s
  end
end

class Class < Object
  def self.allocate
  end
  def self.new
  end
end

class String
end

class MemoryBlock
  attr_accessor :flag, :size, :prev, :next
  def initialize
    @flag = 0
    @size = 0
    @prev = nil
    @next = nil
  end
end


memblock = Object.alloc(MemoryBlock)
