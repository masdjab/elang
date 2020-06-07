module Elang
  class Code
    def self.align(code, align_size = 16, pad_char = nil)
      pc = pad_char ? pad_char[0, 1] : 0.chr
      
      if (extra_size = (code.length % align_size)) > 0
        code = code + (pc * (align_size - extra_size))
      end
      
      code
    end
  end
end
