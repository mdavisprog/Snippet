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

class_name StatusBar
extends LineEdit

# Can display some status text and provides functions to easily alter the visuals.

# The default read-only style.
var DefaultStyle: StyleBox = null

# The style to apply for an error. Duplicated at startup so that any changes are unique to the
# instanced style.
var ErrorStyle: StyleBox = null

func _ready() -> void:
	var Style: StyleBox = get_stylebox("read_only")
	if Style:
		DefaultStyle = Style
		ErrorStyle = Style.duplicate()
		
		if ErrorStyle is StyleBoxFlat:
			ErrorStyle.bg_color = Color("#762929")
	

func SetError(Enable: bool) -> void:
	if not DefaultStyle:
		return
	
	if Enable:
		add_stylebox_override("read_only", ErrorStyle)
	else:
		add_stylebox_override("read_only", DefaultStyle)
	
