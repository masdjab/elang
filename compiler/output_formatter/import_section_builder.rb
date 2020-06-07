module Elang
  class ImportSectionBuilder
    attr_reader :image
    def initialize(symbols)
      @symbols = symbols
      @image = ""
    end
    def build
      imports = {}
      image = ""
      
      @symbols.items.each do |f|
        if f.is_a?(ImportFunction)
          if !imports.keys.include?(f.library)
            imports[f.library] = []
          end
          
          imports[f.library] << {function: f, offset: 0}
        end
      end
      
      module_names = imports.keys.sort
      
      imports.each do |k, v|
        imports[k].sort!{|a,b|a[:function].original_name <=> b[:function].original_name}
      end
      
      # build header
      image << 0.chr * 0x3c
      
      # build import module name table
      temp = ""
      module_names.each do |m|
        temp << m.upcase + 0.chr + ((m.length % 2) > 0 ? "" : 0.chr)
      end
      image << Code.align(temp, 16)
      
      # build import lookup table
      module_names.each do |m|
        names = ""
        temp = ""
        imports[m].each do |f|
          ori_name = f[:function].original_name
          temp << Converter.int2bin(0x2070, :dword)
          names << 0.chr + 0.chr + ori_name + 0.chr + ((ori_name.length % 2) > 0 ? "" : 0.chr)
        end
        temp << Converter.int2bin(0, :dword)
        image << temp << temp << Code.align(names, 4)
      end
      
      @image = image
    end
  end
end
