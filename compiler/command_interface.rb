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
      puts "-d    Enable dev mode"
      puts "-nn   Nodes output to show: none"
      puts "-nl   Nodes output to show: libs"
      puts "-nu   Nodes output to show: user"
      puts "-na   Nodes output to show: all"
      puts "-h    Show this help"
      puts "/?    Alias for -h"
    end
    def self.display_error(msg)
      puts msg
    end
    def self.get_show_nodes_params(args)
      nn = args.delete("-nn")
      nl = args.delete("-nl")
      nu = args.delete("-nu")
      na = args.delete("-na")
      mm = {"-nn" => :none, "-nl" => :libs, "-nu" => :user, "-na" => :all}
      [nn, nl, nu, na].select{|x|!x.nil?}.inject({}){|a,b|a[b] = mm[b]; a}
    end
    def self.compile
      args = ARGV
      
      self.display_title
      
      if (args = ARGV).count == 0
        self.display_usage
      else
        source_file = args.shift
        show_help = args.delete("-h"){args.delete("/?"){false}}
        dev_mode = args.delete("-d"){false}
        show_nodes = get_show_nodes_params(args)
        
        if !args.empty?
          self.display_error "Invalid options: #{args.join(", ")}.\r\n#{HELP_HINT}"
        elsif show_help
          self.display_usage
        elsif show_nodes.count > 1
          self.display_error "Invalid show_nodes options: #{show_nodes.keys.join(" ")}.\r\n#{HELP_HINT}"
        else
          options = {dev: dev_mode}
          options[:show_nodes] = show_nodes.values.first if !show_nodes.empty?
          self.new.compile(source_file, options)
        end
      end
    end
  end
end
