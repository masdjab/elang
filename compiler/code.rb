module Elang
  class Code
    def self.align(code, align_size = 16)
      if (extra_size = (code.length % 16)) > 0
        code = code + (0.chr * (16 - extra_size))
      end
      
      code
    end
  end
end
