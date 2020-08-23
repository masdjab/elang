module Elang
  class Code
    def self.pad_size(size, align)
      if (extra_size = (size % align)) > 0
        align - extra_size
      else
        0
      end
    end
    def self.size_align(size, align)
      size + self.pad_size(size, align)
    end
    def self.code_align(code, align_size = 16, pad_char = nil)
      pc = pad_char ? pad_char[0, 1] : 0.chr
      
      #if (extra_size = (code.length % align_size)) > 0
      #  code = code + (pc * (align_size - extra_size))
      #end
      code = code + (pc * self.pad_size(code.length, align_size))
      
      code
    end
    def self.align(code, align_size = 16, pad_char = nil)
      # deprecated, use code_align instead
      self.code_align code, align_size, pad_char
    end
  end
end
