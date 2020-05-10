module Elang
  class Codeset
    attr_reader :branch, :sections
    
    private
    def initialize
      @sections = {}
      @current_section = nil
      clear_all
    end
    def with_section(section_name = nil)
      ss = section_name ? @sections[section_name] : @current_section
      ss ? yield(ss) : nil
    end
    
    public
    def create_section(name, type)
      if !@sections.key?(name)
        @sections[name] = CodeSection.new(name, type, "")
      end
      
      @sections[name]
    end
    def select_section(name)
      if @sections.key?(name)
        @current_section = @sections[name]
      end
    end
    def [](index, length)
      @current_section ? @current_section[index, length] : nil
    end
    def []=(index, length, data)
      @current_section[index, length] = data if @current_section
    end
    def append(section_name, code = nil)
      section_name, code = code, section_name if code.nil?
      with_section(section_name){|s|s.data << code} if !code.empty?
    end
    def length
      @current_section ? @current_section.size : nil
    end
    def clear
      @current_section.data = "" if @current_section
    end
    def clear_all
      @sections.each{|x|x.data = ""}
    end
    def empty?
      @sections.values.map{|x|x.size}.sum == 0
    end
    def render(section_name = nil)
      with_section(section_name){|s|s.data}
    end
  end
end
