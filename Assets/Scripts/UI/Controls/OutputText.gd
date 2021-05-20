# MIT License
# 
# Copyright (c) 2021 Mitchell Davis <mdavisprog@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class_name OutputText
extends RichTextLabel

# Manages displaying output from the application or developer.

func _ready() -> void:
	var _Error = Log.connect("OnLog", self, "OnLog")
	_Error = Log.connect("OnClear", self, "OnClear")
	

func OnLog(Type: int, Contents: String) -> void:
	var PopColor = false
	match (Type):
		Log.TYPE.ERROR:
			push_color(Color.red)
			PopColor = true
	
	print(Contents)
	AddLine(Contents)
	
	if PopColor:
		pop()
	

func OnClear() -> void:
	clear()
	

func AddLine(Line: String) -> void:
	add_text(Line + "\n")
	
