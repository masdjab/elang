module Elang
  class NodeFetcher < Fetcher
    def check(count = 1, skip_space = true, skip_crlf = false, skip_comment = true)
      list = []
      fpos = @pos
      
      (1..count).each do |c|
        skip = true
        
        while skip && !(node = element(fpos)).nil?
          skip = false
          
          if node.is_a?(Lex::Node)
            if (node.type == :whitespace) && skip_space && (list.empty? || (list.last.is_a?(Lex::Node) && (list.last.type == :whitespace)))
              fpos = fpos + 1
              skip = true
            end
            if [:cr, :lf, :crlf].include?(node.type) && skip_crlf
              fpos = fpos + 1
              skip = true
            end
            if (node.type == :comment) && skip_comment
              fpos = fpos + 1
              skip = true
            end
          end
        end
        
        fpos += 1
        
        list << node
      end
      
      count == 1 ? list.first : list
    end
    def fetch(count = 1, skip_space = true, skip_crlf = false, skip_comment = true)
      list = []
      node = nil
      
      (1..count).each do |c|
        skip = true
        node = super()
        
        while skip && !node.nil?
          skip = false
          
          if node.is_a?(Lex::Node)
            if (node.type == :whitespace) && skip_space && (list.empty? || (list.last.is_a?(Lex::Node) && (list.last.type == :whitespace)))
              node = super()
              skip = true
            end
            if [:cr, :lf, :crlf].include?(node.type) && skip_crlf
              node = super()
              skip = true
            end
            if (node.type == :comment) && skip_comment
              node = super()
              skip = true
            end
          end
        end
        
        list << node
      end
      
      count == 1 ? list.first : list
    end
    def skip(list)
      while (e = element) && e.is_a?(Lex::Node) && list.include?(e.type)
        fetch 1, false, false, false
      end
    end
  end
end
