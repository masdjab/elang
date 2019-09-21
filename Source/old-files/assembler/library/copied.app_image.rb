module Elang
  module Library
    class AppImage
      attr_accessor \
        :signature, :file_size, :header_size, :section_table_offset, 
        :section_table_size, :main_entry_point, :checksum, :raw_image, 
        :sections, :symbol_hash
      
      def initialize
        @signature = ""
        @file_size = 0
        @header_size = 0
        @section_table_offset = 0
        @section_table_size = 0
        @main_entry_point = 0
        @checksum = 0
        @raw_image = ""
        @sections = []
        @symbol_hash = {}
      end
      def self.load(filename)
        file = File.new(filename, "rb")
        content = file.read
        file.close
        
        library = self.new
        library.signature = content[0..2]
        library.file_size = Converter.dword_to_int(content[4..7])
        library.header_size = Converter.word_to_int(content[8..9])
        library.section_table_offset = Converter.word_to_int(content[12..13])
        library.section_table_size = Converter.word_to_int(content[14..15])
        library.main_entry_point = Converter.dword_to_int(content[16..19])
        library.checksum = Converter.dword_to_int(content[20..23])
        
        sect_table = content[library.section_table_offset, library.section_table_size]
        library.sections = 
          (0...(sect_table.length / 16)).map do |s|
            crt_sect = sect_table[16 * s, 16]
            section = AppSection.new
            zr_pos = crt_sect.index(0.chr)
            section.name = zr_pos ? crt_sect[0...zr_pos] : crt_sect[0..4]
            section.flag = crt_sect[4].bytes[0]
            section.offset = Converter.dword_to_int(crt_sect[8, 4])
            section.size = Converter.dword_to_int(crt_sect[12, 4])
            section.body = content[section.offset, section.size]
            section
          end
        
        code_sect = library.sections.find{|x|x.flag == AppSection::CODE}
        library.raw_image = code_sect ? code_sect.body : ""
        
        library
      end
      def format(formatter)
      end
      def save(filename, formatter)
        f = File.new(filename, "wb")
        f.write self.format(formatter)
        f.close
      end
      def generate_code(offset = 0)
        @raw_image
      end
    end
  end
end
