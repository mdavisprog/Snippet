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

tool
class_name Label2D
extends Node2D

# Class that renders a text label in the 2D world space. A font must
# be supplied.

# Emitted when the text has changed.
#
# Value: String
signal TextChanged(Value)

# The font object to use.
export(Font) var FontRef: Font

# The text to render.
export(String) var Text: String setget SetText

func _draw() -> void:
	if FontRef:
		var Size: Vector2 = FontRef.get_string_size(Text)
		draw_string(FontRef, Vector2(Size.x * -0.5, 0.0), Text)
	

func SetFont(Value: Font) -> void:
	if FontRef == Value:
		return
	
	if not Value and FontRef:
		FontRef.disconnect("changed", self, "OnFontChanged")
	
	FontRef = Value
	update()
	
	if FontRef:
		if not FontRef.is_connected("changed", self, "OnFontChanged"):
			var _Error = FontRef.connect("changed", self, "OnFontChanged")
	

func OnFontChanged() -> void:
	update()
	

func SetText(Value: String) -> void:
	Text = Value
	emit_signal("TextChanged", Text)
	update()
	

func GetSize() -> Vector2:
	if not FontRef:
		return Vector2.ZERO
	
	if Text.empty():
		return Vector2.ZERO
	
	return FontRef.get_string_size(Text)
	
