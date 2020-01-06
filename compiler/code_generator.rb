require './compiler/constant'
require './compiler/variable'
require './compiler/function'
require './compiler/symbol_ref'
require './compiler/ast_node'
require './compiler/codeset'
require './utils/converter'

#(todo)#
# - assign local variable
# - get parameter value passed by ref

module Elang
  class CodeGenerator
    attr_reader :symbols, :symbol_refs
    
    private
    def initialize
      @codeset = CodeSet.new
      @scope_stack = []
    end
    def code_len
      @codeset.code_branch.length
    end
    def hex2bin(h)
      Elang::Utils::Converter.hex_to_bin(h)
    end
    def current_scope
      !@scope_stack.empty? ? @scope_stack.last : nil
    end
    def enter_scope(scope)
      cs = current_scope
      @scope_stack << "#{cs ? cs : ""}#{scope}"
      @codeset.enter_subs
    end
    def leave_scope
      @codeset.leave_subs
      @scope_stack.pop if !@scope_stack.empty?
    end
    def code_type
      (current_scope ? current_scope : "").index("#") ? :subs : :main
    end
    def add_constant_ref(symbol, location)
      @codeset.symbol_refs << ConstantRef.new(symbol, current_scope, location, code_type)
    end
    def add_variable_ref(symbol, location)
      @codeset.symbol_refs << VariableRef.new(symbol, current_scope, location, code_type)
    end
    def add_function_ref(symbol, location)
      @codeset.symbol_refs << FunctionRef.new(symbol, current_scope, location, code_type)
    end
    def get_string_constant(str)
      if (symbol = @codeset.symbols.find_str(str)).nil?
        symbol = Elang::Constant.new(current_scope, Elang::Constant.generate_name, str)
      end
      
      symbol
    end
    def append_code(code)
      @codeset.append_code code
    end
    def prepare_single_operand(node, operand_index)
      hex_code = ""
      right_val = !operand_index.nil? && operand_index > 1
      
      if node.is_a?(Array)
        handle_any([node])
      elsif node.type == :number
        # mov reg, imm
        value_hex = Elang::Utils::Converter.int_to_whex_be(node.text.to_i).upcase
        hex_code = (right_val ? "B9" : "B8") + value_hex
      elsif node.type == :string
        # mov reg, str
        str = get_string_constant(node.text)
        hex = right_val ? "8B0E" : "A1"
        add_constant_ref str, code_len + (hex.length / 2)
        hex_code = hex + "0000"
      elsif node.type == :identifier
        if (symbol = @codeset.symbols.find_nearest(current_scope, node.text)).nil?
          raise "Symbol '#{node.text}' not defined"
        else
          # mov reg, var
          hex = right_val ?  "8B0E" : "A1"
          add_variable_ref symbol, code_len + (hex.length / 2)
          hex_code = hex + "0000"
        end
      else
        op_info = operand_index ? " #{operand_index}" : ""
        raise "Invalid operand#{op_info}: #{node.inspect}"
      end
      
      append_code hex2bin(hex_code)
    end
    def prepare_operands(node)
      prepare_single_operand(node[1], 1)
      prepare_single_operand(node[2], 2)
    end
    def handle_assignment(node)
      left_var = node[1]
      var_name = left_var.text
      
      if !left_var.is_a?(Elang::AstNode) || (left_var.type != :identifier)
        raise "Left operand for assignment must be a symbol, #{left_var.inspect} given"
      end
      
      if receiver = @codeset.symbols.find_exact(current_scope, var_name).nil?
        @codeset.symbols.add(receiver = Elang::Variable.new(current_scope, var_name))
      end
      
      prepare_single_operand(node[2], nil)
      add_variable_ref receiver, code_len + 1
      # mov var, ax
      append_code hex2bin("A20000")
    end
    def handle_addition(node)
      # add ax, cx
      prepare_operands(node)
      append_code hex2bin("01C8")
    end
    def handle_subtraction(node)
      # sub ax, cx
      prepare_operands(node)
      append_code hex2bin("29C8")
    end
    def handle_multiplication(node)
      # mul ax, cx
      prepare_operands(node)
      append_code hex2bin("F7E9")
    end
    def handle_division(node)
      # div ax, cx
      prepare_operands(node)
      append_code hex2bin("F7F9")
    end
    def handle_numeric_and(node)
      # and ax, cx
      prepare_operands(node)
      append_code hex2bin("21C8")
    end
    def handle_numeric_or(node)
      # or ax, cx
      prepare_operands(node)
      append_code hex2bin("09C8")
    end
    def handle_function_def(node)
      func_name = node[1].text
      func_args = node[2]
      func_body = node[3]
      params_count = func_args.count
      active_scope = current_scope
      
      if (active_scope ? active_scope : "").index("#")
        raise "Function cannot be nested"
      end
      
      enter_scope "##{func_name}"
      function = @codeset.symbols.find_exact(active_scope, func_name)
      function.offset = code_len
      func_args.each{|x|@codeset.symbols.add Variable.new(current_scope, x.text)}
      handle_any func_body
      # "ret" + (params_count > 0 ? " #{params_count * 2}" : "")
      hex_code = (params_count > 0 ? "C2#{Elang::Utils::Converter.int_to_whex_be(params_count * 2).upcase}" : "C3")
      append_code hex2bin(hex_code)
      leave_scope
    end
    def handle_function_call(node)
      # push ax; call target
      func_name = node[0].text
      
      if (function = @codeset.symbols.find_function(func_name)).nil?
        raise "Call to undefined function '#{func_name}'"
      else
        arguments = node[1]
        
        (0...arguments.count).each do |i|
          prepare_single_operand(arguments[i], 1)
          append_code hex2bin("50")
        end
        
        add_function_ref function, code_len + 1
        append_code hex2bin("E80000")
      end
    end
    def handle_any(nodes)
      nodes.each do |node|
        if node.is_a?(Array)
          first_node = node[0]
          
          if !first_node.is_a?(Elang::AstNode)
            raise "Expected identifier, #{node[0].inspect} given"
          else
            case first_node.type
            when :assign
              handle_assignment(node)
            when :plus
              handle_addition(node)
            when :minus
              handle_subtraction(node)
            when :star
              handle_multiplication(node)
            when :slash
              handle_division(node)
            when :and
              handle_numeric_and(node)
            when :or
              handle_numeric_or(node)
            when :identifier
              if first_node.text == "def"
                handle_function_def(node)
              else
                if (function = @codeset.symbols.find_exact(current_scope, first_node.text)).nil?
                  raise "Call to undefined function '#{first_node.text}'"
                elsif !function.is_a?(Function)
                  raise "Call to non-function '#{first_node.text}'"
                else
                  handle_function_call node
                end
              end
            else
              raise "Cannot handle node: #{node.inspect}"
            end
          end
        else
          raise "Expected array, #{node.class} given: #{node.inspect}"
        end
      end
    end
    def detect_functions(nodes)
      nodes.each do |node|
        if node.is_a?(Array)
          if node[0].is_a?(Array)
            detect_functions node
          elsif (node[0].type == :identifier) && (node[0].text == "def")
            func_name = node[1].text
            func_args = node[2]
            function = Function.new(nil, func_name, func_args, 0)
            @codeset.symbols.add function
          end
        end
      end
    end
    
    public
    def generate_code(nodes)
      @codeset = CodeSet.new
      detect_functions nodes
      handle_any nodes
      @codeset
    end
  end
end
