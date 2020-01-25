require './compiler/main'

#Elang::Main.new.handle_request
Elang::Main.new.compile("tests/elang/numeric_operations.rb", "output.com")
