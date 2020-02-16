require './compiler/parsing_error'
require './compiler/ast_node'

module Elang
  class Lexer
    # class responsibility:
    # convert from tokens to ast nodes
    
    PRIORITY = 
      {
        and:    1, 
        or:     2, 
        star:   3, 
        slash:  3, 
        plus:   4, 
        minus:  4, 
        assign: 5, 
        dot:    6
      }
    
    attr_reader :code_lines
    
    private
    def optimize(tokens)
      loop do
        if index = tokens.index{|x|x.text == "@"}
          if next_token = tokens[index + 1]
            tokens.delete next_token
            token = tokens[index]
            token.type = next_token.type
            token.text = token.text + next_token.text
          end
        end
        
        break if index.nil?
      end
      
      tokens.reject{|x|[:whitespace, :comment].include?(x.type)}
    end
    def raize(msg, node = nil)
      raise ParsingError.new(msg, node, @code_lines)
    end
    def fetch_end(fetcher)
      if (func_end = fetcher.fetch).nil?
        raize "Expected 'end' 1", fetcher.last
      elsif func_end.type != :identifier
        raize "Expected 'end' 2", func_end
      elsif func_end.text != "end"
        raize "Expected 'end' 3", func_end
      end
      
      func_end
    end
    def fetch_function_params(fetcher)
      lbrk = fetcher.element
      
      if lbrk.nil?
        []
      elsif [:cr, :lf, :crlf, :dot].include?(lbrk.type)
        []
      elsif lbrk.type == :lbrk
        params = []
        rbrk = nil
        lbrk = fetcher.fetch
        
        while node = fetcher.element
          if node.type == :identifier
            nn = fetcher.next
            
            if !nn.nil? && [:dot, :lbrk].include?(nn.type)
              params << node = fetch_function_call(fetcher)
            else
              params << node = fetcher.fetch
            end
          elsif [:number, :string].include?(node.type)
            params << node = fetcher.fetch
          elsif node.type == :comma
            node = fetcher.fetch
          elsif node.type == :rbrk
            rbrk = node = fetcher.fetch
            break
          else
            raize "Expected identifier, comma, or rbreak, #{node.type.inspect} found", node
          end
        end
        
        if rbrk.nil?
          raize "Expected ')'", node 
        end
        
        params
      end
    end
    def fetch_class_def(fetcher)
      if (identifier = fetcher.fetch).type != :identifier
        raize "Class definition must start with 'class'", identifier
      elsif identifier.text != "class"
        raize "Class definition must start with 'class'", identifier
      end
      
      classname = ""
      if (name_node = fetcher.fetch).nil?
        raize "Incomplete class definition", node
      elsif name_node.type != :identifier
        raize "Expected class name", node
      else
        class_name = name_node.text
      end
      
      super_node = nil
      if (test_node = fetcher.element).text == "<"
        x = fetcher.fetch
        if (super_node = fetcher.fetch).nil?
          raize "Expected superclass name"
        elsif super_node.type != :identifier
          raize "Expected superclass name"
        end
      end
      
      body_node = fetch_sexp(fetcher)
      
      fetch_end fetcher
      
      [identifier, name_node, super_node, body_node]
    end
    def fetch_function_def(fetcher)
      if (identifier = fetcher.fetch).type != :identifier
        raize "Function definition must start with 'def'", identifier
      elsif identifier.text != "def"
        raize "Function definition must start with 'def'", identifier
      end
      
      if (name_node = fetcher.fetch).nil?
        raize "Incomplete function definition", node
      elsif name_node.text == "["
        if (node = fetcher.fetch).nil?
          raize "Expected ']'", node
        elsif node.text != "]"
          raize "Expected ']'", node
        else
          name_node.type = :identifier
          name_node.text += node.text
          
          if node = fetcher.element
            if node.text == "="
              node = fetcher.fetch
              name_node.text += node.text
            end
          end
        end
      elsif name_node.text == "<"
        if (node = fetcher.fetch).nil?
          raize "Expected '<<', found '<'", node
        elsif node.text != "<"
          raize "Expected '<<', found '<'", node
        else
          name_node.type = :identifier
          name_node.text += node.text
        end
      elsif name_node.type == :identifier
        if node = fetcher.element
          if "?!=".index(node.text)
            node = fetcher.fetch
            name_node.text += node.text
          end
        end
      else
        raize "Expected function name", name_node
      end
      
      rcvr_node = nil
      if (test_node = fetcher.element) && (test_node.text == ".")
        node1 = fetcher.fetch
        node2 = fetcher.fetch
        if node2.type != :identifier
          raize "Expected function name", node2
        else
          rcvr_node, name_node = name_node, node2
        end
      end
      
      if (node = fetcher.element).nil?
        raize "Expected function body", node
      else
        if node.type == :lbrk
          # fetch function arguments
          args_node = fetch_function_params(fetcher)
        else
          args_node = []
        end
      end
      
      body_node = fetch_sexp(fetcher)
      
      fetch_end(fetcher)
      
      [identifier, rcvr_node, name_node, args_node, body_node]
    end
    def fetch_function_call(fetcher)
      first_node = fetcher.fetch
      name_node = first_node
      rcvr_node = nil
      
      if (dn = fetcher.element) && (dn.type == :dot)
        dn = fetcher.fetch
        fn = fetcher.fetch
        rcvr_node, name_node = name_node, fn
      end
      
      [AstNode.new(first_node.row, first_node.col, :dot, "."), rcvr_node, name_node, fetch_function_params(fetcher)]
    end
    def fetch_expression(fetcher)
      parent = nil
      priority = nil
      operations = []
      current = operations
      last_node = nil
      
      while node = fetcher.element
        begin
          if [:and, :star, :slash, :plus, :minus, :assign, :dot].include?(node.type)
            node = fetcher.fetch
            priority2 = PRIORITY[node.type]
            
            if priority
              if !parent.nil? && (priority2 >= priority)
                current = parent
                current << [node, current.pop]
                current = current.last
              else
                parent = current
                current << [node, current.pop]
                current = current.last
              end
            else
              current.insert(0, node)
            end
            
            priority = priority2
          elsif node.type == :lbrk
            fetcher.fetch
            current << node = fetch_expression(fetcher)
          elsif node.type == :rbrk
            node = fetcher.fetch
            break
          elsif node.type == :comma
            node = fetcher.fetch
            # do nothing
          elsif (node.type == :identifier) && (lbrk = fetcher.next) && (lbrk.type == :lbrk)
            fn_call = fetch_function_call(fetcher)
            
            if !current.nil? && current.first.is_a?(AstNode) && (current.first.type == :dot)
              current << fn_call[2]
              current << fn_call[3]
            else
              current << node = fn_call
            end
          elsif [:lf, :cr, :crlf].include?(node.type)
            break
          elsif (node.type == :identifier) && (node.text == "end")
            break
          else
            node = fetcher.fetch
            current << node
          end
          
          last_node = node
        rescue Exception => ex
          puts "current: #{self.class.sexp_display(operations)}"
          raise ex
        end
      end
      
      operations
    end
    def fetch_sexp(fetcher)
      sexp = []
      
      while node = fetcher.element
        if node.type == :identifier
          if node.text == "class"
            sexp << fetch_class_def(fetcher)
          elsif node.text == "def"
            sexp << fetch_function_def(fetcher)
          elsif node.text == "end"
            break
          elsif (dot = fetcher.next) && (dot.type == :dot)
            sexp << fetch_function_call(fetcher)
          elsif (lbrk = fetcher.next) && (lbrk.type == :lbrk)
            sexp << fetch_function_call(fetcher)
          else
            sexp << fetch_expression(fetcher)
          end
        elsif [:lf, :cr, :crlf].include?(node.type)
          fetcher.fetch
        elsif node.type == :rbrk
          break
        else
          sexp << fetch_expression(fetcher)
        end
      end
      
      sexp
    end
    
    public
    def self.sexp_display(sexp)
      if sexp.nil?
        "nil"
      elsif sexp.is_a?(Array)
        temp = sexp.map{|x|sexp_display(x)}
        "[" + temp.join(",") + "]"
      elsif sexp.is_a?(AstNode)
        if sexp.type == :string
          sexp.text[1...-1]
        else
          sexp.text
        end
      elsif sexp.is_a?(String)
        sexp
      else
        sexp.inspect
      end
    end
    def to_sexp_array(tokens, code_lines = [])
      @code_lines = code_lines
      tokens = optimize(tokens)
      nodes = tokens.map{|x|AstNode.new(x.row, x.col, x.type, x.text)}
      nodes = fetch_sexp(FetcherV2.new(nodes))
    end
  end
end
