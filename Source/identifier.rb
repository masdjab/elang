class Identifier
  attr_accessor :scope, :name, :type, :value
  def initialize(scope, name, type, value)
    @scope = scope
    @name = name
    @type = type
    @value = value
  end
end
