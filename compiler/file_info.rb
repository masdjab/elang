module Elang
  class FileInfo
    attr_reader :full, :path, :name_ext, :name, :ext
    
    def initialize(file_name)
      extsn = File.extname(file_name)
      @full = file_name
      @path = File.dirname(@full)
      @name_ext = File.basename(@full)
      @ext = !extsn.empty? ? extsn[1..-1] : ""
      @name = !extsn.empty? ? @name_ext[0...-extsn.length] : @name_ext
    end
    def replace_path(path)
      self.class.new(self.class.join(path, @name, @ext))
    end
    def replace_ext(ext)
      self.class.new(self.class.join(@path, @name, ext))
    end
    def self.join(path, name, ext)
      (!path.empty? ? "#{path}/" : "") + name + (!ext.empty? ? ".#{ext}" : "")
    end
  end
end
