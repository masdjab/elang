module Elang
  class CommandInterface
    HELP_HINT = "Use -h or /? to view help."
    
    def compile(source_file, options = {})
      compiler = Compiler.new(source_file, options)
      
      if compiler.compile
        puts "Source path: #{compiler.source_file.path}"
        puts "Source file: #{compiler.source_file.name_ext}"
        puts "Output file: #{compiler.output_file.name_ext}"
        puts "Output size: #{File.size(compiler.output_file.full)} byte(s)"
      end
    end
    def self.get_file_path_name_ext(filename)
      path = File.dirname(filename)
      path = !path.empty? ? "#{path}/" : ""
      extn = File.extname(filename)
      name = File.basename(filename)
      name = name[0...extn.length]
      [path, name, extn]
    end
    def self.display_title
      puts "ELANG v#{Elang::VERSION} by Heryudi Praja"
    end
    def self.display_usage
      puts
      puts "Usage: ruby elang.rb source_file [options]"
      puts
      puts "Available options:"
      puts "-d              Enable dev mode"
      puts "-n=mode         Nodes output to show: none, libs, user, all"
      puts "-stdlib=file    Specify stdlib file"
      puts "-no-elang-lib   Do not include lib.elang"
      puts "-h or /?        Show this help"
    end
    def self.display_error(msg)
      puts msg
    end
    def self.get_show_nodes_params(args)
      nn = args.delete("-nn")
      nl = args.delete("-nl")
      nu = args.delete("-nu")
      na = args.delete("-na")
      tl = args.delete("-tl")
      
      mm = {"-nn" => :none, "-nl" => :libs, "-nu" => :user, "-na" => :all}
      
      [nn, nl, nu, na].select{|x|!x.nil?}.inject({}){|a,b|a[b] = mm[b]; a}
    end
    def self.parse_arguments(arguments)
      args = []
      opts = {}
      
      arguments.each do |a|
        if "/-".index(a[0])
          a = a.index("--") == 0 ? a[2..-1] : a[1..-1]
          m = a.index(":")
          n = a.index("=")
          
          if (s = m ? m : n)
            k = a[0...s].strip
            v = a[(s + 1)..-1].strip
            v = v[1..-2] if (v[0] == v[1]) && ["\"", "'"].index(v[0])
            opts[k] = v
          else
            opts[a] = nil
          end
        else
          a = a[1..-2] if (a[0] == a[-1]) && ["\"", "'"].index(a[0])
          args << a
        end
      end
      
      [args, opts]
    end
    def self.compile
      args, opts = self.parse_arguments(ARGV)
      valid_options = ["d", "n", "stdlib", "no-elang-lib", "h", "?"]
      
      self.display_title
      
      if args.empty?
        self.display_usage
      elsif !(invalid_options = opts.keys - valid_options).empty?
        self.display_error "Invalid options: #{invalid_options.map{|x|"-#{x}"}.join(", ")}.\r\n#{HELP_HINT}"
      elsif opts.key?("h") || opts.key?("?")
        self.display_usage
      else
        source_file = args.shift
        show_nodes = opts["n"]
        stdlib = opts["stdlib"]
        dev_mode = opts.key?("d")
        no_elang_lib = opts.key?("no-elang-lib")
        
        if !show_nodes.nil? && !["none", "libs", "user", "all"].include?(show_nodes)
          self.display_error "Invalid show_nodes options: #{show_nodes}.\r\n#{HELP_HINT}"
        else
          options = {}
          
          options[:dev] = true if dev_mode
          options[:show_nodes] = show_nodes if show_nodes
          options[:stdlib] = stdlib if stdlib
          options[:no_elang_lib] = no_elang_lib if no_elang_lib
          
          self.new.compile(source_file, options)
        end
      end
    end
  end
end
