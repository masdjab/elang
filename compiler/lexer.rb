require './compiler/ast_node'
require './compiler/operation'
require './compiler/shunting_yard'


module Elang
  class Lexer
    # class responsibility:
    # convert from tokens to ast nodes
    
    attr_reader :code_lines
    
    private
    def initialize
      @shunting_yard = ShuntingYard.new
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
    def fetch_function_params(fetcher)
      params = []
      
      if (node = fetcher.element) && (node.type == :lbrk)
        rbracket = false
        fetcher.fetch
        
        while node = fetcher.element
          if node.type == :rbrk
            fetcher.fetch
            rbracket = true
            break
          elsif node.type == :comma
            fetcher.fetch
          else
            params << fetcher.fetch
          end
        end
        
        if !rbracket
          raize "Expected ')'", fetcher.last
        end
      end
      
      params
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
        args_node = fetch_function_params(fetcher)
      end
      
      body_node = fetch_sexp(fetcher)
      
      fetch_end(fetcher)
      
      [identifier, rcvr_node, name_node, args_node, body_node]
    end
    def convert_expressions_to_nodes(expr)
      if expr.is_a?(Array)
        expr.map{|x|convert_expressions_to_nodes(x)}
      elsif expr.is_a?(Operation)
        rec = convert_expressions_to_nodes(expr.rec)
        op1 = convert_expressions_to_nodes(expr.op1)
        op2 = convert_expressions_to_nodes(expr.op2)
        
        if (cmd = expr.cmd).type == :dot
          [cmd, rec, op1, op2]
        else
          [cmd, op1, op2]
        end
      else
        expr
      end
    end
    def fetch_expressions(fetcher)
      convert_expressions_to_nodes @shunting_yard.fetch_expressions(fetcher)
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
          else
            sexp += fetch_expressions(fetcher)
          end
        elsif [:lf, :cr, :crlf].include?(node.type)
          fetcher.fetch
        elsif node.type == :rbrk
          break
        else
          sexp += fetch_expressions(fetcher)
        end
      end
      
      sexp
    end
    
    public
    def self.convert_tokens_to_ast_nodes(tokens)
      tokens.map{|x|AstNode.new(x.row, x.col, x.type, x.text)}
    end
    def self.optimize(tokens)
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
    def self.sexp_display(sexp)
      if sexp.nil?
        "nil"
      elsif sexp.is_a?(Array)
        "[#{sexp.map{|x|sexp_display(x)}.join(",")}]"
      elsif sexp.is_a?(AstNode)
        if sexp.type == :string
          sexp.text[1...-1]
        else
          sexp.text
        end
      elsif sexp.is_a?(Operation)
        if sexp.cmd.type != :dot
          oo = [sexp.cmd, sexp.op1, sexp.op2].map{|x|sexp_display(x)}
          "[#{oo[0]},#{oo[1]},#{oo[2]}]"
        else
          oo = [sexp.cmd, sexp.rec, sexp.op1, sexp.op2].map{|x|sexp_display(x)}
          "[#{oo[0]},#{oo[1]},#{oo[2]},#{oo[3]}]"
        end
      elsif sexp.is_a?(String)
        sexp
      elsif sexp.respond_to?(:to_s)
        sexp.to_s
      else
        sexp.inspect
      end
    end
    def to_sexp_array(tokens, code_lines = [])
      @code_lines = code_lines
      tokens = self.class.optimize(tokens)
      nodes = self.class.convert_tokens_to_ast_nodes(tokens)
      nodes = fetch_sexp(FetcherV2.new(nodes))
    end
  end
end
