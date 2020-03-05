require './compiler/compiler'
require './compiler/linker'

module Elang
  class Main
    def compile(source_file, output_file, language)
      compiler = Elang::Compiler.new(language)
      linker = Elang::Linker.new
      linker.load_library "#{ELANG_DIR}/libs/stdlib.bin"
      
      codeset = CodeSet.new
      lib_source = FileSourceCode.new("#{ELANG_DIR}/libs/libs.elang")
      usr_source = FileSourceCode.new(source_file)
      binary = ""
      result = nil
      
      if compiler.compile(lib_source, codeset)
        if compiler.compile(usr_source, codeset)
          binary = linker.link(codeset)
          result = codeset
        end
      end
      
      if !binary.empty?
        file = File.new(output_file, "wb")
        file.write binary
        file.close
      elsif File.exist?(output_file)
        File.delete output_file
      end
      
      result
    end
    def handle_request
      src_file = ARGV[0]
      out_file = ARGV[1]
      compile src_file, out_file
    end
  end
end
