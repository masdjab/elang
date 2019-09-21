require_relative 'parser'
require_relative 'lang'

# heredoc test:
a = <<EOS
mulakno kuwi...
ojo kesusu...
EOS

=begin
class ReservedWords
  def initialize
    @known_words = 
      [
        "puts", "if", "elsif", "else", "end", "def", "while", "break"
      ]
  end
  def reserved?(word)
    @known_words.include?(word.downcase)
  end
end
=end

srcfile = "test2.txt"
parser = Lang::SourceParser.new(File.read(srcfile))
parser.parse
