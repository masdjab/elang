# resources:
# https://wiki.osdev.org/MZ
# https://board.flatassembler.net/topic.php?t=1736
# https://board.flatassembler.net/topic.php?t=15181

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
          @signature, 
          Converter.int2bin(@extra_bytes, :word), 
          Converter.int2bin(@num_of_pages, :word), 
          Converter.int2bin(@relocation_items, :word), 
          Converter.int2bin(@header_size, :word), 
          Converter.int2bin(@min_alloc_paragraphs, :word), 
          Converter.int2bin(@max_alloc_paragraphs, :word), 
          Converter.int2bin(@initial_ss, :word), 
          Converter.int2bin(@initial_sp, :word), 
          Converter.int2bin(@checksum, :word), 
          Converter.int2bin(@initial_ip, :word), 
          Converter.int2bin(@initial_cs, :word), 
          Converter.int2bin(@relocation_table, :word), 
          Converter.int2bin(@overlay, :word), 
          @overlay_info ? @overlay_info : ""
        ]
      
      init_cmd.join
    end
  end
end
