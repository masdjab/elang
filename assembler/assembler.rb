require './compiler/tokenizer'

module Assembler
  class Assembler
    def initialize(translator)
      @translator = translator
    end
=begin
    def fetch_whitespace(fetcher)
      fetcher.fetch{|px, cx|' \t'.index(cx)}
    end
    def fetch_identifier(fetcher)
      fetcher.fetch{|px, cx|Elang::Fetcher::IDENTIFIER.index(cx)}
    end
    def fetch_number(fetcher)
      fetcher.fetch{|px, cx|Elang::Fetcher::NUMBER.index(cx)}
    end
    def handle_put(cmd, fetcher)
      ws = fetch_whitespace(fetcher)
      # @translator.cmd_put()
    end
    def handle_get(cmd, fetcher)
    end
=end
    
    def parse(code)
      tokenizer = Elang::Tokenizer.new
      tokens = tokenizer.parse(code)
      translated = []
      
      puts tokens.map{|x|"[#{x.text.inspect}]"}.join(", ")
    end
  end
end
