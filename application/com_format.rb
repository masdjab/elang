require './utils/converter'
require './application/app_section'

module Elang
  class ComFormat
    attr_reader :raw_image, :main_entry_point, :checksum, :sections
    
    def initialize
      @raw_image = ""
      @header = ""
      @checksum = 0
      @main_entry_point = 0
      @sections = []
    end
    def signature
      nil
    end
    def main_entry_point
      @main_entry_point
    end
    def header_size
      @header.length
    end
    def load(image)
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
      
      code_bin = 
        @sections.select{|x|x.flag == Elang::AppSection::CODE}
        .map{|x|x.body}.join
      data_bin = 
        @sections.select{|x|x.flag == Elang::AppSection::DATA}
        .map{|x|x.body}.join
      code_bin = 
        0xe9.chr \
        + Elang::Utils::Converter.int_to_word(@main_entry_point) \
        + code_bin
      @raw_image = code_bin + data_bin
      
      self
    end
  end
end
