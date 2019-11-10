require './compiler/fetcher'
require './compiler/ast_node'

module Elang
  class Lexer
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
