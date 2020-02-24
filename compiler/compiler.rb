# compiler
# class responsibility:
# - convert source code to codeset

require './compiler/exception'
require './compiler/source_code'
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
    
    def compile(source, codeset)
      parser = Elang::Parser.new
      lexer = Elang::Lexer.new
      tokens = parser.parse(source)
      
      if nodes = lexer.to_sexp_array(tokens, source)
        codegen = Elang::CodeGenerator.new
        codegen.generate_code(nodes, codeset, source)
      else
        false
      end
    end
  end
end
