module Elang
  class EScope
    attr_accessor :scopes
    
    def initialize(name)
      @parent = nil
      @scopes = []
    end
  end
end
