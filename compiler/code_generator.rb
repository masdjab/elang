require './compiler/symbols'
require './compiler/variable'
require './compiler/ast_node'
require './utils/converter'

module Elang
  class CodeGenerator
    attr_reader :symbols
    
    def initialize
      @symbols = Symbols.new
      @scope_stack = []
    end
    def current_scope
      !@scope_stack.empty? ? @scope_stack.last : nil
    end
    def enter_scope(scope)
      cs = current_scope
      @scope_stack << "#{cs ? cs : ""}#{scope}"
    end
    def leave_scope
      @scope_stack.pop if !@scope_stack.empty?
    end
    def prepare_single_operand(node, value_index, operand_index)
      if (val_node = node[value_index]).is_a?(Array)
        handle_any([val_node])
      elsif val_node.type == :number
        # mov reg, imm
        (!operand_index.nil? && operand_index > 1 ? "B9" : "B8") + Elang::Utils::Converter.int_to_whex_be(val_node.text.to_i).upcase
      elsif val_node.type == :string
        # mov reg, str
        (!operand_index.nil? && operand_index > 1 ? "8B0E" : "A1") + "0000"
      elsif val_node.type == :identifier
        # mov reg, var
        (!operand_index.nil? && operand_index > 1 ?  "8B0E" : "A1") + "0000"
      else
        op_info = operand_index ? " #{operand_index}" : ""
        raise "Invalid operand#{op_info}: #{val_node.inspect}"
      end
    end
    def prepare_operands(node)
      init_ax = prepare_single_operand(node, 1, 1)
      init_cx = prepare_single_operand(node, 2, 2)
      init_ax + init_cx
    end
    def handle_assignment(node)
      left_var = node[1]
      var_name = left_var.text
      
      if !left_var.is_a?(Elang::AstNode) || (left_var.type != :identifier)
        raise "Left operand for assignment must be a symbol, #{left_var.inspect} given"
      end
      
      if @symbols.find_exact(current_scope, var_name).nil?
        @symbols.add(Elang::Variable.new(current_scope, var_name))
      end
      
      init_ax = prepare_single_operand(node, 2, nil)
      
      # mov var, ax
      init_ax + "A20000"
    end
    def handle_addition(node)
      # add ax, cx
      prepare_operands(node) + "01C8"
    end
    def handle_subtraction(node)
      # sub ax, cx
      prepare_operands(node) + "29C8"
    end
    def handle_multiplication(node)
      # mul ax, cx
      prepare_operands(node) + "F7E9"
    end
    def handle_division(node)
      # div ax, cx
      prepare_operands(node) + "F7F9"
    end
    def handle_numeric_and(node)
      # and ax, cx
      prepare_operands(node) + "21C8"
    end
    def handle_numeric_or(node)
      # or ax, cx
      prepare_operands(node) + "09C8"
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
      body_code = handle_any(func_body)
      leave_scope
      
      # "ret" + (params_count > 0 ? " #{params_count * 2}" : "")
      body_code + (params_count > 0 ? "C2#{Elang::Utils::Converter.int_to_whex_be(params_count * 2).upcase}" : "C3")
    end
    def handle_function_call(node)
      # push ax; call target
      init_args = (0...node[2].count).map{|x|prepare_single_operand(node[2], x, 1) + "50"}.join
      init_args + "E80000"
    end
    def handle_any(nodes)
      binary_code = ""
      
      nodes.each do |node|
        if node.is_a?(Array)
          if !node[0].is_a?(Elang::AstNode)
            raise "Expected identifier, #{node[0].inspect} given"
          elsif node[0].type == :punc
            case node[0].text
            when "="
              binary_code << handle_assignment(node)
            when "+"
              binary_code << handle_addition(node)
            when "-"
              binary_code << handle_subtraction(node)
            when "*"
              binary_code << handle_multiplication(node)
            when "/"
              binary_code << handle_division(node)
            when "&"
              binary_code << handle_numeric_and(node)
            when "|"
              binary_code << handle_numeric_or(node)
            else
              raise "Unknown node type: #{node.inspect}"
            end
          elsif node[0].type == :identifier
            case node[0].text
            when "def"
              binary_code << handle_function_def(node)
            when "call"
              binary_code << handle_function_call(node)
            else
              raise "Cannot handle node: #{node.inspect}"
            end
          else
            raise "Cannot handle node: #{node.inspect}"
          end
        else
          raise "Expected array, #{node.class} given: #{node.inspect}"
        end
      end
      
      binary_code
    end
    def generate_code(nodes)
      Elang::Utils::Converter.hex_to_bin(handle_any(nodes))
    end
  end
end
