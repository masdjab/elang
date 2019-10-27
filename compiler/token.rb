module Assembly
  class Token
    attr_accessor :column, :text
    def initialize(column, text)
      @column = column
      @text = text
    end
  end
end
