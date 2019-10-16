module Elang
  class AppSection
    CODE = 1
    TEXT = 2
    DATA = 3
    RELOCATION = 4
    IMPORT = 5
    EXPORT = 6
    APP_INFO = 7
    
    attr_accessor :name, :flag, :offset, :size, :body
    def initialize(name, flag = 0, body = "", offset = 0)
      @name = name
      @flag = flag
      @offset = offset
      @size = body.length
      @body = body
    end
  end
end
