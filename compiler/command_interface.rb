module Elang
  class CommandInterface
    HELP_HINT = "Use -h or /? to view help."
    
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
      puts "-d                Enable dev mode"
      puts "-n=mode           Nodes output to show: none, libs, user, all"
      puts "-p=platform       Target platform: mswin, msdos, dados"
      puts "-a=arch           Target architecture: 16, 32"
      puts "-f=output format  com, mz, mzpe"
      #puts "-stdlib=file     Specify stdlib file"
      #puts "-no-elang-lib    Do not include lib.elang"
      puts "-h or /?          Show this help"
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
      
      valid_options = 
        [
          "d", 
          "n", 
          "p", 
          "a", 
          "f", 
          #"stdlib", 
          #"no-elang-lib", 
          "h", 
          "?"
        ]
      
      self.display_title
      
      if args.empty?
        self.display_usage
      elsif !(invalid_options = opts.keys - valid_options).empty?
        self.display_error "Invalid options: #{invalid_options.map{|x|"-#{x}"}.join(", ")}.\r\n#{HELP_HINT}"
      elsif opts.key?("h") || opts.key?("?")
        self.display_usage
      else
        source_file = args.shift
        platform = opts["p"]
        architecture = opts["a"]
        output_format = opts["f"]
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
          
          project = Elang::Project.new
          project.platform = platform
          project.architecture = architecture
          project.output_format = output_format
          project.source_file = source_file
          project.options = options
          
          pb_factory = Elang::ProjectBuilderFactory.new
          
          begin
            project_builder = pb_factory.create_project_builder(project)
            
            result = project_builder.build_project
            
            if result[:success]
              sfi = FileInfo.new(result[:source_file])
              ofi = FileInfo.new(result[:output_file])
              puts "Source path: #{sfi.path}"
              puts "Source file: #{sfi.name_ext}"
              puts "Output file: #{ofi.name_ext}"
              puts "Output size: #{File.size(ofi.full)} byte(s)"
            end
          rescue RuntimeError => e
            puts e.message
          end
        end
      end
    end
  end
end
