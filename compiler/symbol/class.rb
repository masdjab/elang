module Elang
  class Class
    ROOT_CLASS_IDS = 
      {
        "Integer"     => nil, 
        "NilClass"    => 0, 
        "FalseClass"  => 2, 
        "TrueClass"   => 4, 
        "Object"      => 6, 
        "Enumerator"  => 8, 
        "Array"       => 10, 
        "String"      => 12
      }
    
    USER_CLASS_ID_BASE  = 0x100
    
    attr_reader :scope, :name, :parent, :clsid
    
    def initialize(scope, name, parent, clsid)
      @clsid = clsid
      @scope = scope
      @name = name
      @parent = parent
    end
  end
end
