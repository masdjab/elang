module Elang
  class RelocationInitializer
    def init(app)
      app.relocations.each do |relocation|
        if (function = app.functions.find{|x|x.name == relocation.function}).nil?
          raise "Cannot relocate function '#{relocation.function}'. Function not found."
        else
          code_length = 2
          ext_distance = relocation.code_set == app.main ? app.subs.code.length : 0
          distance = function.offset - relocation.location - ext_distance - code_length
          code = Elang::Utils::Converter.int_to_word(distance)
          relocation.code_set.code[relocation.location, code.length] = code
        end
      end
    end
  end
end
