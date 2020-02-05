class Wagu
  def initialize(value)
    @value = value
  end
  def value
    @value
  end
  def value=(v)
    @value = v
  end
  def <<(v)
    1
  end
  def [](index)
    #@value[index]
    2
  end
  def []=(index, v)
    #@value[index] = v
    3
  end
  def empty!
    #@value = []
    4
  end
  def empty?
    #@value.empty?
    5
  end
end

#w = Wagu.new([1, 2, 3])
#puts "initial value: #{w.value.inspect}"
#w.value = [1, 2]
#puts "set value = [1, 2] => new value = #{w.value.inspect}"
#puts "w[0] = #{w[0].inspect}, w[1] = #{w[1].inspect}"
#w.value[0] = 5
#puts "set value[0] = 5 => new value[0] = #{w[0].inspect}"
#puts "empty? => #{w.empty?.inspect}"
#w.empty!
#puts "emptied => empty? = #{w.empty?.inspect}"
