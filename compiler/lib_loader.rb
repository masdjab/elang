# require utils/converter

module Elang
  class LibraryFunction
    attr_reader :name, :offset
    def initialize(name, offset)
      @name = name
      @offset = offset
    end
  end
  
  
  class LibraryInfo
    attr_reader :functions, :code
    
    def initialize(functions, code)
      @functions = functions
      @code = code
    end
  end
  
  
  class LibraryFileLoader
    def load(libfile)
      file = File.new(libfile, "rb")
      text = file.read
      file.close
      
      header_size = Elang::Utils::Converter.dword_to_int(text[0..3])
      library_code = text[header_size..-1]
      
      functions = []
      current_entry = 4
      while (4...header_size).include?(current_entry) do
        zero_pos = text.index(0.chr, current_entry)
        name = text[current_entry...zero_pos]
        offset = Elang::Utils::Converter.dword_to_int(text[(zero_pos + 1), 4])
        functions << LibraryFunction.new(name, offset)
        current_entry = zero_pos + 5
      end
      
      LibraryInfo.new(functions, library_code)
    end
  end
end
