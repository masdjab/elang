require_relative 'lex'
require_relative 'node_fetcher'
require_relative 'operation'
require_relative 'shunting_yard'


module Elang
  class Lexer
    # class responsibility:
    # convert from tokens to ast nodes
    
    RESERVED_WORDS = 
      ["class", "def", "if", "elsif", "else", "end", "do", "nil", "true", "false", "loop", "while", "for"]
      
    OPERATORS = 
      ["+", "-", "*", "/", "&", "|", "+=", "-=", "*=", "/=", "&=", "|=", "==", "!=", "<", ">", "<=", ">=", "<<", ">>"]
    
    attr_reader   :shunting_yard
    attr_accessor :error_formatter
    
    private
    def initialize(shunting_yard = nil)
      @shunting_yard = shunting_yard ? shunting_yard : ShuntingYard.new
      @error_formatter = ParsingExceptionFormatter.new
    end
    def raize(msg, node = nil)
      if node
        raise ParsingError.new(msg, node.row, node.col, node.source)
      else
        raise ParsingError.new(msg, nil, nil, nil)
      end
    end
    def shunt_yard(nodes)
      @shunting_yard.process(nodes)
    end
    def takeout(nodes)
      nodes.is_a?(Array) && (nodes.count == 1) ? nodes[0] : nodes
    end
    def create_send_node(receiver, command, args)
      values = args.items ? args.items : []
      
      if receiver.nil? && !args.encloser1.nil? && !args.encloser2.nil? && (args.encloser1.type == :lsbrk) && (args.encloser2.type == :rsbrk)
        if !args.assign.nil?
          Lex::Send.new(command, Lex::Node.new(0, 0, nil, :wbi, "[]="), values)
        else
          Lex::Send.new(command, Lex::Node.new(0, 0, nil, :rbi, "[]"), values)
        end
      else
        Lex::Send.new(receiver, command, values)
      end
    end
    def create_array(values)
      Lex::Array.new(values)
    end
    def create_hash(values)
      temp = values.map{|x|x}
      list = []
      
      while !temp.empty?
        k, a, v = temp.shift, temp.shift, temp.shift
        list << k << v
      end
      
      Lex::Hash.new(list)
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
          dot_node = Lex::Node.new(cmd.row, cmd.col, nil, :dot, ".")
          cmd_node = Lex::Node.new(cmd.row, cmd.col, nil, :identifier, cmd.text)
          [dot_node, op1, cmd, [op2]]
        end
      else
        expr
      end
    end
    def skip_whitespaces(fetcher)
      fetcher.skip [:whitespace, :comment]
    end
    def skip_linefeed(fetcher)
      fetcher.skip [:cr, :lf, :crlf, :whitespace, :comment]
    end
    def fetch_word(fetcher, text, required)
      if (node = fetcher.check).is_a?(Lex::Node) && (node.type == :identifier) && (node.text == text)
        fetcher.fetch
      elsif required
        if node.nil?
          raize "Expected '#{text}'", fetcher.last
        else
          raize "Expected '#{text}', found #{node.inspect}", node
        end
      end
    end
    def fetch_variable(fetcher)
      if (node = fetcher.fetch).nil?
        raize "Expected variable", fetcher.last
      elsif node.type != :identifier
        raize "Expected variable, found #{node.inspect}", node
      else
        node
      end
    end
    def fetch_values(fetcher)
      args = []
      lbrk = nil
      rbrk = nil
      asgn = nil
      wspc = nil
      ebrk = nil
      
      if (node = fetcher.check(1, false, false, false)) && node.is_a?(Lex::Node) && [:lbrk, :lsbrk, :lcbrk].include?(node.type)
        lbrk = fetcher.fetch
      elsif (node = fetcher.check(2, false, false, false)).select{|x|!x.is_a?(Lex::Node)}.empty? \
      && (node[0].type == :whitespace) && [:lbrk, :lsbrk, :lcbrk, :identifier, :string, :number].include?(node[1].type)
        wspc = fetcher.fetch(1, false, false, false)
      end
      
      if lbrk
        ebrk = {lbrk: :rbrk, lsbrk: :rsbrk, lcbrk: :rcbrk}[lbrk.type]
      end
      
      if lbrk || wspc
        while fetcher.check
          if !(val = fetch_single_expression(fetcher)).empty?
            args += val
          end
          
          if !(node = fetcher.check).nil? && node.is_a?(Lex::Node) && (node.type == :comma)
            fetcher.fetch
            fetcher.skip [:whitespace, :comment, :cr, :lf, :crlf]
          else
            break
          end
        end
        
        if node = fetcher.check
          if [:rbrk, :rsbrk, :rcbrk].include?(node.type)
            if !lbrk
              raize "Unexpected '#{node.text}'", node
            elsif node.type != ebrk
              raize "Expected #{ebrk}, found #{node.type}", node
            else
              rbrk = fetcher.fetch
            end
          end
        end
        
        if !lbrk.nil?
          if rbrk.nil?
            echr = {rbrk: ')', rsbrk: ']', rcbrk: '}'}[ebrk]
            raize "Expected '#{echr}'", fetcher.element
          elsif (node = fetcher.check) && (node.is_a?(Lex::Node)) && (node.type == :assign)
            if lbrk.type != :lsbrk
              raize "Unexpected '='", node
            else
              asgn = fetcher.fetch
              
              if !(val = fetch_single_expression(fetcher)).empty?
                args += val
              end
            end
          end
        end
      end
      
      Lex::Values.new(args, lbrk, rbrk, asgn)
    end
    def fetch_identifier(fetcher)
      identifier = nil
      
      if (node = fetcher.check) && node.is_a?(Lex::Node)
        if (nx = fetcher.check(2, false, false, false)).select{|x|!x.is_a?(Lex::Node)}.empty? \
        && (nx[0].type == :identifier) && "!?".include?(nx[1].text)
          # ex: empty!, empty?
          n1 = fetcher.fetch(2, false, false, false)
          nx = n1[0]
          nx.text += n1[1].text
          identifier = nx
        elsif node.type == :identifier
          identifier = fetcher.fetch
        elsif node.text == "@"
          node = fetcher.fetch
          
          if (nx = fetcher.check(2, false, false, false)) && (nx[0].text == "@") && (nx[1].type == :identifier)
            # @identifier
            nx = fetcher.fetch(2, false, false, false)
            node.type = :identifier
            node.text = node.text + nx.map{|x|x.text}.join
            identifier = node
          elsif (nx = fetcher.check(1, false, false, false)) && (nx.type == :identifier)
            # @@identifier
            node.type = :identifier
            node.text = node.text + fetcher.fetch.text
            identifier = node
          else
            raize "Invalid syntax", node
          end
        end
      end
      
      identifier
    end
    def fetch_operand(fetcher, receiver, is_dot_method)
      val = nil
      
      if val.nil? && is_dot_method
        if (n1 = fetcher.check(3, false, false, false)).select{|x|!x.is_a?(Lex::Node)}.empty? \
        && (n1.map{|x|x.type} == [:identifier, :whitespace, :assign])
          # ex: .b = v
          n1 = fetcher.fetch(3, false, false, false)
          nx = n1[0]
          nx.text += n1[2].text
          val = create_send_node(receiver, nx, fetch_values(fetcher))
        elsif (n1 = fetcher.check(2, false, false, false)).select{|x|!x.is_a?(Lex::Node)}.empty? \
        && (n1.map{|x|x.type} == [:identifier, :assign])
          # ex: .b = v
          n1 = fetcher.fetch(2, false, false, false)
          nx = n1[0]
          nx.text += n1[1].text
          val = create_send_node(receiver, nx, fetch_values(fetcher))
        end
      end
      
      if val.nil? && (n1 = fetcher.check) && n1.is_a?(Lex::Node)
        if (n1.type == :lbrk) && !(args = fetch_values(fetcher)).items.empty?
          # ex: (1 + 2)
          val = args.items.count == 1 ? args.items[0] : args.items
        elsif (n1.type == :lsbrk)
          # ex: [1, 2, 3]
          val = create_array(fetch_values(fetcher).items)
        elsif (n1.type == :lcbrk)
          # ex: {"one" => 1, "two" => 2, "three" => 3}
          val = create_hash(fetch_values(fetcher).items)
        end
      end
      
      if val.nil?
        if node = fetch_identifier(fetcher)
          if (nx = fetcher.check(1, false, false, false)) && [:lbrk, :lsbrk].include?(nx.type)
            # ex: identifier(...) or identifier[...]
            val = create_send_node(receiver, node, fetch_values(fetcher))
          elsif (nx = fetcher.check(1, false, false, false)) && (nx.type == :whitespace) && !(args = fetch_values(fetcher)).items.empty?
            # ex: identifier ...
            val = create_send_node(receiver, node, args)
          elsif is_dot_method
            # ex: .a
            val = create_send_node(receiver, node, Lex::Values.new(nil, nil, nil))
          else
            # ex: a
            val = node
          end
        elsif (node = fetcher.check) && node.is_a?(Lex::Node) && [:string, :number].include?(node.type)
          if !is_dot_method
            # ex: "123"
            val = fetcher.fetch
          else
            raize "Invalid method", node
          end
        end
      end
      
      if val
        if (node = fetcher.check(1, false, false, false)) && node.is_a?(Lex::Node) && (node.type == :dot)
          fetcher.fetch
          
          if cmd = fetch_operand(fetcher, val, true)
            val = cmd
          else
            raize "Expected method name", fetcher.element
          end
        end
      end
      
      val
    end
    def fetch_single_expression(fetcher)
      body = []
      
      while node = fetcher.check
        oldpos = fetcher.pos
        
        fetcher.skip [:whitespace]
        
        if node.is_a?(Lex::Node) && (node.type == :identifier) && ["do", "end"].include?(node.text)
          break
        elsif node.is_a?(Lex::Node) && (node.type == :identifier) && ["break"].include?(node.text)
          body << fetcher.fetch
        elsif [:comma, :rbrk, :rsbrk, :rcbrk, :cr, :lf, :crlf].include?(node.type)
          break
        elsif ShuntingYard::PRECEDENCE.key?(node.type)
          body << fetcher.fetch
        elsif operand = fetch_operand(fetcher, nil, false)
          body << operand
        elsif node.type == :backslash
          fetcher.fetch
          skip_linefeed fetcher
        else
          body << fetcher.fetch
        end
        
        if fetcher.pos == oldpos
          raize "Parse nothing in fetch_single_expression", fetcher.element
          break
        end
      end
      
      shunt_yard(body)
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
        raize "Expected class name, got #{name_node.inspect}", name_node
      else
        class_name = name_node.text
      end
      
      super_node = nil
      if (test_node = fetcher.check).text == "<"
        x = fetcher.fetch
        if (super_node = fetcher.fetch).nil?
          raize "Expected superclass name"
        elsif super_node.type != :identifier
          raize "Expected superclass name"
        end
      end
      
      body_node = fetch_sexp(fetcher)
      fetch_word fetcher, "end", true
      
      Lex::Class.new(name_node, super_node, body_node)
    end
    def fetch_function_params(fetcher)
      params = []
      
      if (node = fetcher.check) && (node.type == :lbrk)
        rbracket = false
        fetcher.fetch
        
        while node = fetcher.check
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
      if ((identifier = fetcher.fetch).type != :identifier) || (identifier.text != "def")
        raize "Function definition must start with 'def'", identifier
      end
      
      name_node = nil
      if (node = fetcher.check).nil?
        raize "Incomplete function definition", node
      elsif fetcher.check(3).map{|x|x ? x.text : "nil"}.join == "[]="
        node = fetcher.fetch(3)
        name_node = node[0]
        name_node.type = :identifier
        name_node.text = node.map{|x|x.text}.join
      elsif fetcher.check(2).map{|x|x ? x.text : "nil"}.join == "[]"
        node = fetcher.fetch(2)
        name_node = node[0]
        name_node.type = :identifier
        name_node.text = node.map{|x|x.text}.join
      elsif (nx = fetcher.check(2)) && (nx[0].type == :identifier) && !("!?=".index(nx[1] ? nx[1].text : "nil")).nil?
        node = fetcher.fetch(2)
        name_node = node[0]
        name_node.type = :identifier
        name_node.text = node.map{|x|x.text}.join
      elsif OPERATORS.include?(node.text)
        name_node = fetcher.fetch
      elsif node.type == :identifier
        name_node = fetcher.fetch
      else
        raize "Expected function name, got #{node.inspect}", node
      end
      
      
      rcvr_node = nil
      if (test_node = fetcher.check) && (test_node.text == ".")
        if name_node.text != "self"
          raize "Invalid function receiver '#{name_node.text}'", name_node
        else
          node1 = fetcher.fetch
          node2 = fetcher.fetch
          if node2.type != :identifier
            raize "Expected function name", node2
          else
            rcvr_node, name_node = name_node, node2
          end
        end
      end
      
      if (node = fetcher.check).nil?
        raize "Expected function body", node
      else
        args_node = fetch_function_params(fetcher)
      end
      
      body_node = fetch_sexp(fetcher)
      fetch_word fetcher, "end", true
      
      Lex::Function.new(rcvr_node, name_node, args_node, body_node)
    end
    def fetch_if(fetcher)
      wslist = [:cr, :lf, :crlf, :whitespace, :comment]
      
      if (if_node = fetcher.check) && ["if", "elsif"].include?(if_node.text)
        fetcher.fetch
      else
        raize "Expected 'if'", if_node
      end
      
      if (cond_node = fetch_single_expression(fetcher)).empty?
        raize "Expected boolean expression", cond_node
      end
      
      skip_linefeed fetcher
      expr1 = fetch_sexp(fetcher)
      
      if (node = fetcher.check).nil?
        raize "Expected 'elsif', 'else', or 'end'", fetcher.last
      elsif node.type != :identifier
        raize "Expected 'elsif', 'else', or 'end'; found #{node.inspect}", fetcher.last
      elsif (node = fetcher.check) && (node.text == "elsif")
        child_if = fetch_if(fetcher)
        Lex::IfBlock.new(if_node, cond_node, expr1, [child_if])
      elsif node.text == "else"
        fetcher.fetch
        expr2 = fetch_sexp(fetcher)
        fetch_word fetcher, "end", true
        
        Lex::IfBlock.new(if_node, cond_node, expr1, expr2)
      elsif node.text == "end"
        fetcher.fetch
        Lex::IfBlock.new(if_node, cond_node, expr1, nil)
      else
        raize "Expected 'end', found #{node.inspect}"
      end
    end
    def fetch_loop(fetcher)
      # loop [do]...end
      
      fetch_word fetcher, "loop", true
      fetch_word fetcher, "do", false
      skip_linefeed fetcher
      body_node = fetch_sexp(fetcher)
      fetch_word fetcher, "end", true
      
      Lex::LoopBlock.new(body_node)
    end
    def fetch_while(fetcher)
      # while condition [do]...end
      
      fetch_word fetcher, "while", true
      
      if (cond_node = fetch_single_expression(fetcher)).empty?
        raize "Expected boolean expression", cond_node
      end
      
      skip_whitespaces fetcher
      fetch_word fetcher, "do", false
      skip_linefeed fetcher
      body_node = fetch_sexp(fetcher)
      fetch_word fetcher, "end", true
      
      Lex::WhileBlock.new(cond_node, body_node)
    end
    def fetch_for(fetcher)
      # for variable in iterator [do]...end
      
      fetch_word fetcher, "for", true
      var_node = fetch_variable(fetcher)
      fetch_word fetcher, "in", true
      
      if (iter_node = fetch_single_expression(fetcher)).nil?
        raize "Expected iterator", fetcher.last
      elsif iter_node.empty?
        raize "Expected iterator", iter_node
      end
      
      fetch_word fetcher, "do", false
      skip_linefeed fetcher
      body_node = fetch_sexp(fetcher)
      fetch_word fetcher, "end", true
      
      Lex::ForBlock.new(var_node, iter_node, body_node)
    end
    def fetch_sexp(fetcher)
      sexp = []
      
      loop do
        oldpos = fetcher.pos
        
        skip_linefeed fetcher
        
        if node = fetcher.check
          if node.type == :identifier
            if node.text == "class"
              sexp << fetch_class_def(fetcher)
            elsif node.text == "def"
              sexp << fetch_function_def(fetcher)
            elsif ["elsif", "else", "end"].include?(node.text)
              break
            elsif ["break"].include?(node.text)
              sexp << fetcher.fetch
            elsif node.text == "if"
              sexp << fetch_if(fetcher)
            elsif node.text == "loop"
              sexp << fetch_loop(fetcher)
            elsif node.text == "while"
              sexp << fetch_while(fetcher)
            elsif node.text == "for"
              sexp << fetch_for(fetcher)
            else
              sexp += fetch_single_expression(fetcher)
            end
          elsif [:lf, :cr, :crlf].include?(node.type)
            fetcher.fetch
          elsif node.type == :rbrk
            break
          else
            sexp += fetch_single_expression(fetcher)
          end
        else
          break
        end
        
        if fetcher.pos == oldpos
          raize "Parse nothing in fetch_sexp", fetcher.element
          break
        end
      end
      
      sexp
    end
    
    public
    def self.sexp_to_s(sexp)
      Lex::Node.any_to_s sexp
    end
    def self.sexp_to_a(sexp)
      Lex::Node.any_to_a sexp
    end
    def self.convert_tokens_to_lex_nodes(tokens)
      tokens.map{|x|Lex::Node.new(x.row, x.col, x.source, x.type, x.text)}
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
    def to_sexp_array(tokens)
      begin
        nodes = self.class.convert_tokens_to_lex_nodes(tokens)
        nodes = fetch_sexp(NodeFetcher.new(nodes))
      rescue Exception => e
        ExceptionHelper.show e, @error_formatter
        nil
      end
    end
  end
end
