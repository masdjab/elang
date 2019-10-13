require './utils/converter'

module Elang
  class BXFormat
    attr_reader :raw_image, :main_entry_point, :checksum, :sections
    
    def initialize
      @raw_image = ""
      @header = ""
      @checksum = 0
      @main_entry_point = 0
      @sections = []
    end
    def signature
      @raw_image.length >= 2 ? @raw_image[0..1] : nil
    end
    def main_entry_point
      @main_entry_point
    end
    def header_size
      @header.length
    end
    def load(image)
      msg_invalid_format = "Invalid BX format"
      
      if image.length < 32
        raise msg_invalid_format
      elsif (signature = image[0..1]) != "BX"
        raise msg_invalid_format
      else
        header_size = Utils::Converter.word_to_int(image[8..9])
        section_table_offset = Utils::Converter.word_to_int(image[12..13])
        section_table_size = Utils::Converter.word_to_int(image[14..15])
        @main_entry_point = Utils::Converter.dword_to_int(image[16..19])
        @checksum = Utils::Converter.dword_to_int(image[20..23])
        @header = image[header_size..-1]
        @raw_image = image
        
        sect_table = image[section_table_offset, section_table_size]
        sections = 
          (0...(sect_table.length / 16)).map do |s|
            crt_sect = sect_table[16 * s, 16]
            zr_pos = crt_sect.index(0.chr)
            name = zr_pos ? crt_sect[0...zr_pos] : crt_sect[0..4]
            flag = crt_sect[4].bytes[0]
            offset = Utils::Converter.dword_to_int(crt_sect[8, 4])
            size = Utils::Converter.dword_to_int(crt_sect[12, 4])
            body = image[section.offset, section.size]
            AppSection.new(name, flag, body, offset)
          end
        
        code_sect = sections.find{|x|x.flag == AppSection::CODE}
      end
    end
    def build(sections, main_offset)
      @raw_image = ""
      @checksum = 0
      @main_entry_point = main_offset
      
      msg_section_must_array = 
        "Parameter 'sections' must be array of AppSection type."
      
      if !sections.is_a?(Array)
        raise msg_section_must_array
      elsif !sections.select{|x|!x.is_a?(AppSection)}.empty?
        raise msg_section_must_array
      else
        @sections = sections
      end
      
      
      header_size = 32
      @raw_image = 0.chr * 32
      @raw_image[0..1] = "BX"
      
      sections_table = ""
      sections_data = ""
      
      if !@sections.empty?
        @sections.each do |section|
          section_location = sections_data.length
          
          if !section.body.empty?
            body_len = sections_data.length
            padding_len = body_len > 0 ? 16 - (body_len % 16) : 0
            section_location = section_location + padding_len
            sections_data << 0.chr * padding_len
            sections_data << section.body
          end
          
          name = section.name + (section.name.length < 4 ? 0.chr * (4 - section.name.length) : "")
          offset = Utils::Converter.int_to_dword(section_location)
          size = Utils::Converter.int_to_dword(section.size)
          sections_table << [name, section.flag.chr, 0.chr * 3, offset, size].join
        end
        
        @raw_image[12..13] = Utils::Converter.int_to_word(header_size)
        @raw_image[14..15] = Utils::Converter.int_to_word(sections_table.length)
      end
      
      @raw_image << (sections_table + sections_data)
      @raw_image[4..7] = Utils::Converter.int_to_dword(@raw_image.length)
      @raw_image[8..9] = Utils::Converter.int_to_word(header_size)
      @raw_image[16..19] = Utils::Converter.int_to_dword(@main_entry_point)
      @raw_image[20..23] = Utils::Converter.int_to_dword(@checksum)
      @header = @raw_image[0...header_size]
      
      self
    end
  end
end
