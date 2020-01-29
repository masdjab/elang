module Elang
  class CodesetTool
    ROOT_CLASSES = ["Integer", "NilClass", "TrueClass", "FalseClass", "Object"]
    BASE_FUNCTION_ID = 1
    
    def initialize(codeset)
      @codeset = codeset
    end
    def create_class_id(original_id)
      original_id + 5
    end
    def get_function_names
      if @functions.nil?
        @functions = @codeset.symbols.items.select{|x|x.is_a?(Function)}.map{|x|x.name}.uniq
      end
      
      @functions
    end
    def get_instance_vars(cls)
      if cls.parent
        parent = @codeset.symbols.items.find{|x|x.is_a?(Class) && (x.name == cls.parent)}
        parent_iv = get_instance_vars(parent)
      else
        parent_iv = []
      end
      
      self_iv = @codeset.symbols.items.select{|x|x.is_a?(InstanceVariable) && (x.scope.cls == cls.name)}.map{|x|x.name}
      
      parent_iv + self_iv
    end
    def get_instance_methods(cls)
      functions = get_function_names
      
      @codeset.symbols.items
        .select{|x|x.is_a?(Function) && (x.scope.cls == cls.name) && x.receiver.nil?}
        .map{|x|{id: BASE_FUNCTION_ID + functions.index(x.name), name: x.name, offset: x.offset}}
    end
    def get_classes_hierarchy
      classes = {}
      
      @codeset.symbols.items.each do |s|
        if s.is_a?(Class)
          if !classes.key?(s.name)
            classes[s.name] = 
              {
                :clsid  => create_class_id(s.index), 
                :parent => s.parent, 
                :i_vars => get_instance_vars(s), 
                :i_funs => get_instance_methods(s)
              }
          end
        end
      end
      
      puts classes.inspect
    end
  end
end
