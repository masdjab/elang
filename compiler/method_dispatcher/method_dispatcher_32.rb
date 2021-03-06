module Elang
  class MethodDispatcher32
    attr_accessor :classes
    attr_reader   :dispatcher_offset
    
    private
    def initialize
      @classes = nil
      @dispatcher_offset = 0
    end
    def get_scope
      Scope.new
    end
    def get_context
      "disp"
    end
    
    public
    def build_obj_method_dispatcher(symbols, symbol_refs, binary_code)
      codepad = Elang::CodePad.new(symbols, symbol_refs, binary_code)
      built_in_class_names = ["Integer", "NilClass", "FalseClass", "TrueClass"]
      label_method_selector = {}
      label_first_method = {}
      
      label_handle_invalid_class_id = codepad.register_label(get_scope, nil)
      codepad.append_hex "B800000000"             # mov ax, 0
      codepad.append_hex "C3"                     # ret
      
      label_handle_method_not_found = codepad.register_label(get_scope, nil)
      codepad.append_hex "B800000000"             # mov ax, 0
      codepad.append_hex "C3"                     # ret
      
      @classes.each do |key, cls|
        label_method_selector[key.downcase] = codepad.register_label(get_scope, nil)
        codepad.append_hex "8B450C"               # mov ax, [bp + 6]
        
        label_first_method[key.downcase] = codepad.register_label(get_scope, nil)
        cls[:i_funs].each do |f|
          function = codepad.symbols.items.find{|x|(x.is_a?(Function)) && (x.scope.cls == key) && (x.name == f[:name]) && x.receiver.nil?}
          codepad.add_function_id_ref f[:name], codepad.code_len + 1
          codepad.add_abs_code_ref function, codepad.code_len + 8
          codepad.append_hex "3D00000000"         # cmp ax, #{f[:id]}
          codepad.append_hex "7506"               # jnz + 2
          codepad.append_hex "B800000000"         # mov ax, #{key.downcase}_obj_#{f[:name]}
          codepad.append_hex "C3"                 # ret
        end
        
        if cls[:parent]
          codepad.add_near_code_ref label_first_method[cls[:parent].downcase], codepad.code_len + 1
          codepad.append_hex "E900000000"         # jmp label_first_method[superclass]
        else
          codepad.add_abs_code_ref label_handle_method_not_found, codepad.code_len + 1
          codepad.append_hex "B800000000C3"       # mov ax, label_handle_method_not_found; ret
        end
      end
      
      
      label_find_obj_method = codepad.register_label(get_scope, nil)
      codepad.append_hex "8B4508"                 # mov ax, [bp + 4]
      
      # add built-in class: Integer
      codepad.add_near_code_ref label_method_selector["integer"], codepad.code_len + 7
      codepad.append_hex "A901000000"             # test ax, 1
      codepad.append_hex "0F8500000000"           # jnz method_selector_integer
      
      # add built-in classes other than integer
      built_in_class_names.each do |cn|
        if (cn != "Integer") && @classes.key?(cn)
          class_id = Converter.int2hex(Class::ROOT_CLASS_IDS[cn], :dword, :be)
          codepad.add_near_code_ref label_method_selector[cn.downcase], codepad.code_len + 7
          codepad.append_hex "3D#{class_id}"      # test ax, 1
          codepad.append_hex "0F8400000000"       # jnz method_selector_integer
        end
      end
      
      
      codepad.append_hex "56"                     # push si
      codepad.append_hex "8B7508"                 # mov si, [bp + 4]
      codepad.append_hex "8B06"                   # mov ax, [si]
      codepad.append_hex "5E"                     # pop si
      
      # add non-built-in classes
      @classes.each do |key, cls|
        if !built_in_class_names.include?(key)
          if clsid = cls[:clsid]
            codepad.add_near_code_ref label_method_selector[key.downcase], codepad.code_len + 7
            class_id = Converter.int2hex(cls[:clsid], :dword, :be).upcase
            codepad.append_hex "3D#{class_id}"    # cmp ax, #{cls[:clsid]}
            codepad.append_hex "0F8400000000"     # jz label_method_selector[key.downcase]
          end
        end
      end
      
      codepad.add_abs_code_ref label_handle_invalid_class_id, codepad.code_len + 1
      codepad.append_hex "B800000000C3"           # mov ax, label_handle_invalid_class_id; ret
      
      label_return_to_caller = codepad.register_label(get_scope, nil)
      codepad.append_hex "50"                     # push ax
      codepad.append_hex "56"                     # push si
      codepad.append_hex "89EE"                   # mov si, bp
      codepad.append_hex "8B4510"                 # mov ax, [bp + 16]
      codepad.append_hex "83C004"                 # add ax, 4
      codepad.append_hex "C1E002"                 # shl ax, 2
      codepad.append_hex "01C6"                   # add si, ax
      codepad.append_hex "8B4504"                 # mov ax, [bp + 4]
      codepad.append_hex "87EE"                   # xchg bp, si
      codepad.append_hex "894500"                 # mov [bp], ax
      codepad.append_hex "87EE"                   # xchg bp, si
      codepad.append_hex "897504"                 # mov [bp + 4], si
      codepad.append_hex "5E"                     # pop si
      codepad.append_hex "58"                     # pop ax
      codepad.append_hex "5D"                     # pop bp
      codepad.append_hex "5C"                     # pop sp
      codepad.append_hex "C3"                     # ret
      
      offset_dispatch_obj_method = codepad.code_len
      codepad.append_hex "55"                     # push bp
      codepad.append_hex "89E5"                   # mov bp, sp
      codepad.add_abs_code_ref label_return_to_caller, codepad.code_len + 1
      codepad.append_hex "B800000000"             # mov ax, label_return_to_caller
      codepad.append_hex "50"                     # push ax
      
      codepad.add_near_code_ref label_find_obj_method, codepad.code_len + 1
      codepad.append_hex "E800000000"             # call label_find_obj_method
      codepad.append_hex "50"                     # push ax
      codepad.append_hex "C3"                     # ret
      
      @dispatcher_offset = offset_dispatch_obj_method
      
      codepad.code_page.data
    end
  end
end
