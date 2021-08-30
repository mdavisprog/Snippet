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

# The maximum width allowed for this label. If non-zero, will ensure the
# text fits within the specified width. If not, the text will be rendered with
# a shortened version of the text.
export(float) var MaxWidth = 0.0 setget SetMaxWidth

# The visual rendering of the text. Stored for quick access when querying for
# the size of this label.
var Visual = ""

func _draw() -> void:
	if FontRef:
		var Size: Vector2 = FontRef.get_string_size(Visual)
		draw_string(FontRef, Vector2(Size.x * -0.5, 0.0), Visual)
	

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
	UpdateVisualText()
	emit_signal("TextChanged", Text)
	update()
	

func GetSize() -> Vector2:
	if not FontRef:
		return Vector2.ZERO
	
	if Text.empty():
		return Vector2.ZERO
	
	return FontRef.get_string_size(Text)

func GetVisualSize() -> Vector2:
	if not FontRef:
		return Vector2.ZERO
	
	if Visual.empty():
		return Vector2.ZERO
	
	return FontRef.get_string_size(Visual)

func UpdateVisualText() -> void:
	Visual = Text
	
	if not FontRef:
		return
	
	var Size: Vector2 = FontRef.get_string_size(Text)
	if MaxWidth > 0.0 and Size.x > MaxWidth:
		Visual = ""
		var DotSize: Vector2 = FontRef.get_string_size("...")
		for I in range(Text.length()):
			Visual += Text[I]
			Size = FontRef.get_string_size(Visual)
			if Size.x + DotSize.x >= MaxWidth:
				Visual += "..."
				break
	

func SetMaxWidth(Value: float) -> void:
	MaxWidth = Value
	SetText(Text)
	
