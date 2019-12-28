require './application/app_section'

module Elang
  class ImageBuilder
    def build(app, format)
      sections = []
      
      app_code = (app.functions.map{|x|x.body} + [app.main]).join
      
      if !app_code.empty?
        sections << AppSection.new('CODE', AppSection::CODE, app_code)
      end
      
      if !app.constants.empty?
        data = app.constants.map{|x|"#{Utils::Converter.int_to_word(x.value.length)}#{x.value}"}.join
        sections << AppSection.new('DATA', AppSection::DATA, data)
      end
      
      format.build sections, app_code.length - app.main.length
      
      format
    end
  end
end
