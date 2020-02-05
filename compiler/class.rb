module Elang
  class Class
    CLS_ID_NULL         = 0
    CLS_ID_FALSE        = 2
    CLS_ID_TRUE         = 4
    CLS_ID_OBJECT       = 6
    CLS_ID_ENUMERATOR   = 8
    CLS_ID_STRING       = 10
    CLS_ID_ARRAY        = 12
    
    CLS_NAME_INTEGER    = "Integer"
    CLS_NAME_NULL       = "NilClass"
    CLS_NAME_FALSE      = "FalseClass"
    CLS_NAME_TRUE       = "TrueClass"
    CLS_NAME_OBJECT     = "Object"
    CLS_NAME_ENUMERATOR = "Enumerator"
    CLS_NAME_STRING     = "String"
    CLS_NAME_ARRAY      = "Array"
    
    ROOT_CLASS_IDS      = 
      {
        CLS_NAME_INTEGER    => nil, 
        CLS_NAME_NULL       => CLS_ID_NULL, 
        CLS_NAME_FALSE      => CLS_ID_FALSE, 
        CLS_NAME_TRUE       => CLS_ID_TRUE, 
        CLS_NAME_OBJECT     => CLS_ID_OBJECT, 
        CLS_NAME_ENUMERATOR => CLS_ID_ENUMERATOR, 
        CLS_NAME_STRING     => CLS_ID_STRING, 
        CLS_NAME_ARRAY      => CLS_ID_ARRAY
      }
    
    USER_CLASS_ID_BASE  = 11
    
    attr_reader :scope, :name, :parent, :index
    
    def initialize(scope, name, parent, index)
      @index = index
      @scope = scope
      @name = name
      @parent = parent
    end
  end
end
