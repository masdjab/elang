# compiler
# class responsibility:
# - convert source code to codeset

require './compiler/exception'
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
      clines = parser.code_lines
      
      lexer = Elang::Lexer.new
      nodes = lexer.to_sexp_array(tokens, clines)
      
      codegen = Elang::CodeGenerator.new
      codeset = codegen.generate_code(nodes, clines)
      
      if codeset
        codeset.code_lines = clines
      end
      
      codeset
    end
  end
end
