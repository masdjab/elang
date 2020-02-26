require './compiler/ast_node'
require './compiler/operation'
require './compiler/shunting_yard'


module Elang
  class Lexer
    # class responsibility:
    # convert from tokens to ast nodes
    
    RESERVED_WORDS = 
      [
        "class", "def", "if", "elsif", "else", "end", "nil", "true", "false"
      ]
      
    OPERATORS = 
      ["+", "-", "*", "/", "&", "|", "+=", "-=", "*=", "/=", "&=", "|=", "==", "!=", "<", ">", "<=", ">=", "<<", ">>"]
    
    attr_accessor :error_formatter
    
    private
    def initialize
      @source = nil
      @shunting_yard = ShuntingYard.new
      @error_formatter = ParsingExceptionFormatter.new
    end
    def raize(msg, node = nil)
      if node
        raise ParsingError.new(msg, node.row, node.col, @source)
      else
        raise ParsingError.new(msg, nil, nil, @source)
      end
    end
    def skip_linefeed(fetcher)
      skipped = nil
      
      while (node = fetcher.element) && [:crlf, :lf, :cr].include?(node.type)
        skipped = fetcher.fetch
      end
      
      skipped
    end
    def skip_whitespace(fetcher)
      skipped = nil
      
      while (node = fetcher.element) && (node.type == :whitespace)
        skipped = fetcher.fetch
      end
      
      skipped
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
        raize "Incomplete class definition", name_node
      elsif name_node.type != :identifier
        raize "Expected class name", name_node
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
      elsif OPERATORS.include?(name_node.text)
        # accept function name
      elsif name_node.type == :identifier
        if node = fetcher.element
          if "?!=".index(node.text)
            node = fetcher.fetch
            name_node.text += node.text
          end
        end
      else
        raize "Expected function name, got #{name_node.inspect}", name_node
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
    def fetch_if(fetcher)
      if_lex = nil
      
      if (ifnode = fetcher.element) && ["if", "elsif"].include?(ifnode.text)
        fetcher.fetch
        skip_linefeed fetcher
      else
        raize "Expected 'if'", ifnode
      end
      
      if (cond_node = fetch_expressions(fetcher)).empty?
        raize "Expected boleean expression", cond_node
      end
      
      if (expr1 = fetch_expressions(fetcher)).empty?
        raise "Expected expression"
      else
        skip_linefeed fetcher
      end
      
      if (node = fetcher.element) && (node.text == "elsif")
        child_if = fetch_if(fetcher)
        if_lex = [ifnode, cond_node, expr1, [child_if]]
      elsif node.text == "else"
        fetcher.fetch
        
        if (node = fetcher.element).nil?
          raize "Expected expression", fetcher.last
        elsif [:lf, :cr, :crlf].include?(node.type)
          fetcher.fetch
        end
        
        expr2 = fetch_expressions(fetcher)
        skip_linefeed fetcher
        if_lex = [ifnode, cond_node, expr1, expr2]
      else
        if_lex = [ifnode, cond_node, expr1]
      end
      
      if_lex
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
        elsif cmd.type == :assign
          [cmd, op1, op2]
        else
          dot_node = AstNode.new(cmd.row, cmd.col, :dot, ".")
          cmd_node = AstNode.new(cmd.row, cmd.col, :identifier, cmd.text)
          [dot_node, op1, cmd, [op2]]
        end
      else
        expr
      end
    end
    def fetch_function_args(fetcher, prev_node)
      output = []
      types  = [:identifier, :number, :string]
      
      if !prev_node.nil? && prev_node.is_a?(AstNode) && (prev_node.type == :identifier) && !RESERVED_WORDS.include?(prev_node.text)
        if !(cn = fetcher.element).nil? && types.include?(cn.type)
          output << AstNode.new(nil, nil, :lbrk, "(")
          
          while node = fetcher.element
            if node.type == :identifier
              output << node = fetcher.fetch
              output += fetch_function_args(fetcher, node)
            elsif node.type == :comma
              # do nothing
              fetcher.fetch
            elsif [:cr, :lf, :crlf].include?(node.type)
              break
            else
              output << fetcher.fetch
            end
          end
          
          output << AstNode.new(nil, nil, :rbrk, ")")
        end
      end
      
      output
    end
    def prepare_nodes_1(fetcher)
      output = []
      
      while node = fetcher.fetch
        if node.type == :identifier
          output << node
          output += fetch_function_args(fetcher, node)
        else
          output << node
        end
      end
      
      output
    end
    def prepare_nodes_2(fetcher)
      output = []
      
      while node = fetcher.fetch
        if node.is_a?(Array)
          output << node
        elsif node.text == "@"
          if (n1 = fetcher.element).nil? || !n1.is_a?(AstNode) || (n1.type != :identifier)
            raize "Invalid syntax", node
          else
            n1 = fetcher.fetch
            node.type = n1.type
            node.text = node.text + n1.text
            output << node
          end
        elsif node.text == "."
          output << node
          
          if (n1 = fetcher.fetch).nil? || !n1.is_a?(AstNode) || (n1.type != :identifier)
            raize "Invalid syntax => n1: #{n1.inspect}", output.last 
          else
            if !(n2 = fetcher.element).nil? && n2.is_a?(AstNode) && (n2.type == :assign)
              n2 = fetcher.fetch
              n1.text += n2.text
            end
            
            output << n1
            output += fetch_function_args(fetcher, n1)
          end
        else
          output << node
        end
      end
      
      output
    end
    def fetch_expressions(fetcher)
      convert_expressions_to_nodes @shunting_yard.fetch_expressions(fetcher, @source)
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
          elsif node.text == "if"
            sexp << fetch_if(fetcher)
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
    def convert_tokens_to_ast_nodes(tokens)
      tokens.map{|x|AstNode.new(x.row, x.col, x.type, x.text)}
    end
    def find_tokens(tokens, text)
      pat = text.is_a?(Array) ? text : [text]
      cnt = pat.count
      pos = 0
      
      while pos <= (tokens.count - cnt)
        if (pos...(pos + cnt)).map{|x|tokens[x].text} == pat
          yield pos
        end
        pos += 1
      end
    end
    def prepare_nodes(tokens)
      nodes = convert_tokens_to_ast_nodes(tokens)
      nodes = nodes.reject{|x|[:whitespace, :comment].include?(x.type)}
      nodes = prepare_nodes_1(FetcherV2.new(nodes))
      nodes = prepare_nodes_2(FetcherV2.new(nodes))
      nodes
    end
    def to_sexp_array(tokens, source = nil)
      begin
        @source = source
        nodes = prepare_nodes(tokens)
        nodes = fetch_sexp(FetcherV2.new(nodes))
      rescue Exception => e
        ExceptionHelper.show e, @error_formatter
        nil
      end
    end
  end
end
