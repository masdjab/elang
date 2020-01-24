require './compiler/compiler'
require './compiler/linker'

module Elang
  class Main
    def compile(source_file, output_file)
      compiler = Elang::Compiler.new
      linker = Elang::Linker.new
      
      codeset = compiler.compile(File.read(source_file))
      binary = linker.link(codeset)
      
      file = File.new(output_file, "wb")
      file.write binary
      file.close
    end
    def handle_request
      src_file = ARGV[0]
      out_file = ARGV[1]
      compile src_file, out_file
    end
  end
end
