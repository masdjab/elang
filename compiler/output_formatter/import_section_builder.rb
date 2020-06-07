module Elang
  class ImportSectionBuilder
    attr_reader   :image, :imports
    attr_accessor :image_base
    
    def initialize(symbols)
      @symbols = symbols
      @imports = nil
      @image_base = nil
      @image = nil
    end
    def build
      imports = {}
      image_base = @image_base ? @image_base : 0
      image = ""
      
      @symbols.items.each do |f|
        if f.is_a?(ImportFunction)
          if !imports.keys.include?(f.library)
            imports[f.library] = []
          end
          
          if imports[f.library].find{|x|x[:function].original_name == f.original_name}.nil?
            imports[f.library] << {function: f, offset: 0}
          end
        end
      end
      
      module_names = imports.keys.sort
      module_name_offsets = {}
      
      imports.each do |k, v|
        imports[k].sort!{|a,b|a[:function].original_name <=> b[:function].original_name}
      end
      
      
      # create blank directory table
      num_of_entries = module_names.map{|x|imports[x].count}.sum + 1
      directory_entry_size = 5 * 4
      directory_size = num_of_entries * directory_entry_size
      image << 0.chr * directory_size
      
      # create list of imported module names
      temp = ""
      offset = image_base + image.length
      module_names.each do |m|
        module_name_offsets[m] = offset + temp.length
        temp << m.upcase + 0.chr + ((m.length % 2) > 0 ? "" : 0.chr)
      end
      image << Code.align(temp, 4)
      
      # build import lookup table
      (0...module_names.count).each do |i|
        m = module_names[i]
        offset = image.length
        table_base = image_base + image.length
        entry_count = imports[m].count
        lookup_size = (entry_count + 1) * 4
        lookup_data = 0.chr * lookup_size
        proc_names = ""
        
        (0...entry_count).each do |j|
          f = imports[m][j]
          ori_name = f[:function].original_name
          name_offset = table_base + 2 * lookup_size + proc_names.length
          lookup_data[j * 4, 4] = Converter.int2bin(name_offset, :dword)
          f[:offset] = table_base + j * 4
          proc_names << 0.chr + 0.chr + ori_name + 0.chr + ((ori_name.length % 2) > 0 ? "" : 0.chr)
        end
        
        write_offset = directory_entry_size * i
        timestamp = 0
        forwarder_chain = 0
        file_name_offset = module_name_offsets[m]
        image[write_offset + 0, 4] = Converter.int2bin(table_base, :dword)
        image[write_offset + 4, 4] = Converter.int2bin(timestamp, :dword)
        image[write_offset + 8, 4] = Converter.int2bin(forwarder_chain, :dword)
        image[write_offset + 12, 4] = Converter.int2bin(file_name_offset, :dword)
        image[write_offset + 16, 4] = Converter.int2bin(table_base + lookup_size, :dword)
        image << lookup_data << lookup_data << Code.align(proc_names, 4)
      end
      
      @imports = imports.keys.inject([]){|a,b|a += imports[b]; a}
      @image = image
    end
  end
end
