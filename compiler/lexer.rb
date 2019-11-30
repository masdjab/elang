require './compiler/fetcher'
require './compiler/ast_node'

module Elang
  class Lexer
    # lexer
    # class responsibility:
    # convert from tokens into ast nodes
    
    # convert tokens into ast nodes
    
    private
    def optimize(tokens)
      
    end
    
    public
    def lex(tokens)
      tokens = optimize(tokens)
    end
  end
end
