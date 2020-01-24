# compiler
# class responsibility:
# - convert source code to codeset

require './compiler/parser'
require './compiler/lexer'
require './compiler/code_generator'

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
    end
  end
end
