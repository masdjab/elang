module Elang
  class Operation
    attr_accessor :cmd, :op1, :op2, :rec
    
    def initialize(cmd, op1, op2, rec = nil)
      @rec = rec
      @cmd = cmd
      @op1 = op1
      @op2 = op2
    end
  end
end
