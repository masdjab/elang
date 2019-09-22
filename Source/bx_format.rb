module Elang
  class BXFormat
    attr_accessor \
      :signature, :file_size, :header_size, :section_table_offset, 
      :section_table_size, :main_entry_point, :checksum, :sections
    
    def initialize
      @signature = "BX"
      @file_size = 0
      @header_size = 0
      @section_table_offset = 0
      @section_table_size = 0
      @main_entry_point = 0
      @checksum = 0
      @sections = []
    end
  end
end
