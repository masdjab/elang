module Elang
  class MzHeader
    attr_reader   :signature
    attr_accessor \
      :extra_bytes, :num_of_pages, :relocation_items, :header_size, :min_alloc_paragraphs, 
      :max_alloc_paragraphs, :initial_ss, :initial_sp, :checksum, :initial_ip, :initial_cs, 
      :relocation_table, :overlay, :overlay_info
      
    def initialize
      @signature = "MZ"
      @extra_bytes = nil
      @num_of_pages = nil
      @relocation_items = nil
      @header_size = nil
      @min_alloc_paragraphs = nil
      @max_alloc_paragraphs = nil
      @initial_ss = nil
      @initial_sp = nil
      @checksum = nil
      @initial_ip = nil
      @initial_cs = nil
      @relocation_table = nil
      @overlay = nil
      @overlay_info = nil
    end
    def to_bin
      init_cmd = 
        [
          Converter.int2hex(@extra_bytes, :word, :be), 
          Converter.int2hex(@num_of_pages, :word, :be), 
          Converter.int2hex(@relocation_items, :word, :be), 
          Converter.int2hex(@header_size, :word, :be), 
          Converter.int2hex(@min_alloc_paragraphs, :word, :be), 
          Converter.int2hex(@max_alloc_paragraphs, :word, :be), 
          Converter.int2hex(@initial_ss, :word, :be), 
          Converter.int2hex(@initial_sp, :word, :be), 
          Converter.int2hex(@checksum, :word, :be), 
          Converter.int2hex(@initial_ip, :word, :be), 
          Converter.int2hex(@initial_cs, :word, :be), 
          Converter.int2hex(@relocation_table, :word, :be), 
          Converter.int2hex(@overlay, :word, :be), 
          @overlay_info
        ]
      
      @signature + Converter.hex2bin(init_cmd.join)
    end
  end
end
