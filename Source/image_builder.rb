require './app_section'
require './bx_format'

module Elang
  class ImageBuilder
    def build(app)
      sections = []
      
      raw_codes = [app.subs.code, app.main.code]
      app_code = raw_codes.join
      
      
      bx_format = BXFormat.new
      
      if !app_code.empty?
        sections << AppSection.new('CODE', AppSection::CODE, app_code)
      end
      
      if !app.constants.empty?
        data = app.constants.map{|x|"#{Utils::Converter.int_to_word(x.value.length)}#{x.value}"}.join
        sections << AppSection.new('DATA', AppSection::DATA, data)
      end
      
      bx_format.build sections, app_code.length - app.main.code.length
      
      bx_format
    end
  end
end
