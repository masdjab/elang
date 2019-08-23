module Lexer
  class Parser
    OPERATOR_PRIORITIES = 
      {
        "+" => 1, 
        "-" => 2, 
        "*" => 3, 
        "/" => 4, 
        "^" => 5
      }
    
    def initialize(source)
      @fetcher = Fetcher.new(source)
    end
    def fetch_token
      while token = @fetcher.fetch
        break if ![:space, :comment].include?(token.type)
      end
      
      token
    end
    def fetch_condition
    end
    def handle_if
    end
    def handle_elsif
    end
    def handle_else
    end
    def handle_def
    end
    def handle_end
    end
    def handle_expression
    end
    def parse
      while token = self.fetch_token
        type = token.type
        
        if type == :if
        elsif [:elsif, :elseif].include?(type)
        elsif type == :else
        elsif type == :def
        elsif type == :end
        else
          handle_expression
        end
      end
    end
  end
end
