require './application'
require './image_builder'
require './utils/converter'

app = Elang::EApplication.new("test")

app.variables << Elang::EVariable.new("version", nil)
app.constants << Elang::EConstant.new("Hello world...")
app.constants << Elang::EConstant.new("This is a string constant.")

app.functions << Elang::EFunction.new("fn001", app.subs.code.length, ["arg1", "arg2"])
app.subs.code << "#fn001"

app.functions << Elang::EFunction.new("fn002", app.subs.code.length, ["text"])
app.relocations << Elang::RelocationItem.new("fn001", app.subs, app.subs.code.length + 13)
app.subs.code << "#fn002{fn001(xx)}"

app.functions << Elang::EFunction.new("fn003", app.subs.code.length, ["v1", "v2"])
app.relocations << Elang::RelocationItem.new("fn001", app.subs, app.subs.code.length + 13)
app.relocations << Elang::RelocationItem.new("fn002", app.subs, app.subs.code.length + 24)
app.subs.code << "#fn003{fn001(xx), fn002(xx)}"

app.functions << Elang::EFunction.new("length", app.subs.code.length, ["value"])
app.relocations << Elang::RelocationItem.new("fn003", app.subs, app.subs.code.length + 13)
app.relocations << Elang::RelocationItem.new("fn002", app.subs, app.subs.code.length + 24)
app.subs.code << "#fn004(fn003(xx), fn002(xx))"

app.main.code << "main:"
app.main.code << "print(v1)"
app.relocations << Elang::RelocationItem.new("fn001", app.main, app.main.code.length + 11)
app.relocations << Elang::RelocationItem.new("fn002", app.main, app.main.code.length + 27)
app.main.code << "call:fn001(xx), call:fn002(xx)"
app.main.code << "end"

relocator = Elang::RelocationInitializer.new.init(app)

bx_format = Elang::ImageBuilder.new.build(app)
file = File.new("test.com", "wb")
file.write bx_format.raw_image
file.close
