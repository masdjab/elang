# compiler
# class responsibility:
# - build EApplication from code string

# elang linker

=begin
require './utils/converter'
#require './compiler/identifier'
#require './compiler/scope'
require './compiler/token'
require './application/application'
require './application/com_format'
require './application/image_builder'
#require './compiler/symbol_request'
#require './compiler/converter'
#require './compiler/app_section'
##require './compiler/app_image'
require './compiler/lib_loader'
#require './compiler/object_file'
require './compiler/parser'


src_file = ARGV[0]
parser = Assembly::Parser.new
parser.load_lib "compiler/stdlib.bin"
app = parser.parse File.read(src_file)
relocator = Elang::RelocationInitializer.new.init(app)
com_format = Elang::ImageBuilder.new.build(app, Elang::ComFormat.new)
file = File.new("output.com", "wb")
file.write com_format.raw_image
file.close
=end

require './compiler/parser'
require './compiler/lexer'
require './compiler/code_generator'
require './compiler/linker'

module Elang
  class Compiler
    # class responsibility: convert source code to executable binary codes
    # - convert source code to tokens
    # - convert tokens to ast nodes using lexer
    # - create codeset from ast nodes using code generator
    # - resolve symbol references add build final binary code
    
    def compile(source)
      parser = Elang::Parser.new
      tokens = parser.parse(source)
      
      lexer = Elang::Lexer.new
      nodes = lexer.to_sexp_array(tokens)
      
      codegen = Elang::CodeGenerator.new
      codeset = codegen.generate_code(nodes)
      
      codeset
      
      #linker = Elang::Linker.new
      #binary = linker.link(codeset)
      
      #binary
    end
  end
end
