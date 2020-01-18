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
        assign: 5
      }
    
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
      
      tokens.reject{|x|x.type == :whitespace}
    end
    def raise_error(node, msg)
      rowcol_info = node ? " at #{node.row}, #{node.col}" : ""
      raise "Error#{rowcol_info}: #{msg}"
    end
    def fetch_end(fetcher)
      if (func_end = fetcher.fetch).nil?
        raise_error fetcher.last, "Expected 'end' 1"
      elsif func_end.type != :identifier
        raise_error func_end, "Expected 'end' 2"
      elsif func_end.text != "end"
        raise_error func_end, "Expected 'end' 3"
      end
      
      func_end
    end
    def fetch_function_params(fetcher)
      params = []
      
      rbreak_found = false
      
      if (lbrk = fetcher.fetch).nil?
        raise_error lbrk, "Expected '('"
      elsif lbrk.type != :lbrk
        raise_error lbrk, "Expected '('"
      end
      
      while node = fetcher.fetch
        if node.type == :identifier
          params << node
        elsif node.type == :comma
          # do nothing
        elsif node.type == :rbrk
          rbreak_found = true
          break
        else
          raise_error node, "Expected parameter name"
        end
      end
      
      if !rbreak_found
        raise_error node, "Expected ')'"
      end
      
      params
    end
    def fetch_class_def(fetcher)
      if (identifier = fetcher.fetch).type != :identifier
        raise_error identifier, "Class definition must start with 'class'"
      elsif identifier.text != "class"
        raise_error identifier, "Class definition must start with 'class'"
      end
      
      classname = ""
      if (name_node = fetcher.fetch).nil?
        raise_error node, "Incomplete class definition"
      elsif name_node.type != :identifier
        raise_error node, "Expected class name"
      else
        class_name = name_node.text
      end
      
      supername = ""
      if test_node = fetcher.next
        if test_node.text == "<"
          x = fetcher.fetch
          if (super_node = fetcher.fetch).nil?
            raise_error "Expected superclass name"
          elsif super_node.type != :identifier
            raise_error "Expected superclass name"
          else
            supername = super_node.text
          end
        end
      end
      
      body_node = fetch_sexp(fetcher)
      
      fetch_end fetcher
      
      [identifier, name_node, super_node, body_node]
    end
    def fetch_function_def(fetcher)
      if (identifier = fetcher.fetch).type != :identifier
        raise_error identifier, "Function definition must start with 'def'"
      elsif identifier.text != "def"
        raise_error identifier, "Function definition must start with 'def'"
      end
      
      if (name_node = fetcher.fetch).nil?
        raise_error node, "Incomplete function definition"
      elsif name_node.type != :identifier
        raise_error node, "Expected function name"
      end
      
      rcvr_node = nil
      if (test_node = fetcher.element) && (test_node.text == ".")
        node1 = fetcher.fetch
        node2 = fetcher.fetch
        if node2.type != :identifier
          raise_error node2, "Expected function name"
        else
          rcvr_node, name_node = name_node, node2
        end
      end
      
      if (node = fetcher.element).nil?
        raise_error node, "Expected function body"
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
    def fetch_function_args(fetcher)
      #(todo)#fetch function args
    end
    def fetch_function_call(fetcher)
      #(todo)#fetch function call
    end
    def fetch_expression(fetcher)
      parent = nil
      priority = nil
      operations = []
      current = operations
      last_node = nil
      
      while node = fetcher.element
        begin
          if [:and, :star, :slash, :plus, :minus, :assign].include?(node.type)
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
            node = fetcher.fetch
            if !last_node.nil? && (last_node.type == :identifier)
              modified = [current.pop, fetch_expression(fetcher)]
              current << modified
            else
              current << fetch_expression(fetcher)
            end
          elsif node.type == :rbrk
            node = fetcher.fetch
            break
          elsif node.type == :comma
            node = fetcher.fetch
            # do nothing
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
          case node.text
          when "class"
            sexp << fetch_class_def(fetcher)
          when "def"
            sexp << fetch_function_def(fetcher)
          when "end"
            break
          else
            sexp << fetch_expression(fetcher)
          end
        elsif [:lf, :cr, :crlf].include?(node.type)
          fetcher.fetch
        else
          sexp << fetch_expression(fetcher)
        end
      end
      
      sexp
    end
    
    public
    def self.sexp_display(sexp_array)
      temp = 
        sexp_array.map do |x|
          if x.is_a?(Array)
            self.sexp_display x
          elsif x.is_a?(AstNode)
            if x.type == :string
              x.text[1...-1]
            else
              x.text
            end
          elsif x.nil?
            "nil"
          elsif x.is_a?(String)
            x
          else
            x.inspect
          end
        end
      
      "[" + temp.join(",") + "]"
    end
    def to_sexp_array(tokens)
      tokens = optimize(tokens)
      nodes = tokens.map{|x|AstNode.new(x.row, x.col, x.type, x.text)}
      fetch_sexp(FetcherV2.new(nodes))
    end
  end
end
