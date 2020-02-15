module Elang
  class CodesetTool
    def initialize(codeset)
      @codeset = codeset
    end
    def self.create_class_id(cls)
      if cls.name == "Integer"
        nil
      elsif Class::ROOT_CLASS_IDS.key?(cls.name)
        Class::ROOT_CLASS_IDS[cls.name]
      else
        Class::USER_CLASS_ID_BASE + (cls.index * 2)
      end
    end
    def get_function_names
      if @functions.nil?
        predefined = Function::PREDEFINED_FUNCTION_NAMES
        func_names = @codeset.symbols.items.select{|x|x.is_a?(Function)}.map{|x|x.name}.uniq
        @functions = predefined + (func_names - predefined)
      end
      
      @functions
    end
    def get_global_variables
      @codeset.symbols.items.select{|s|s.is_a?(Variable) && s.scope.root?}
    end
    def get_instance_variables(cls)
      if cls.parent
        parent = @codeset.symbols.items.find{|x|x.is_a?(Class) && (x.name == cls.parent)}
        parent_iv = get_instance_variables(parent)
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
        .map{|x|{id: functions.index(x.name), name: x.name, offset: x.offset}}
    end
    def get_classes_hierarchy
      classes = {}
      
      @codeset.symbols.items.each do |s|
        if s.is_a?(Class)
          if !classes.key?(s.name)
            classes[s.name] = 
              {
                :clsid  => self.class.create_class_id(s), 
                :parent => s.parent, 
                :i_vars => get_instance_variables(s), 
                :i_funs => get_instance_methods(s)
              }
          end
        end
      end
      
      classes
    end
  end
end
