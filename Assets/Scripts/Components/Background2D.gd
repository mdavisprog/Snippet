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
class_name Background2D
extends Node2D

# Simple node that renders a style box.

# Style box to render.
export(StyleBox) var Box: StyleBox setget SetBox

# The size of the background.
export(Vector2) var Size: Vector2 setget SetSize

# Should the background be centered.
export(bool) var Center = true

func _ready() -> void:
	if not Engine.editor_hint:
		if Box:
			# Duplicate the box to create a unique instance for this node.
			Box = Box.duplicate(true)
	

func _draw() -> void:
	if not Box:
		return
	
	draw_style_box(Box, GetBounds())
	

func SetBox(Value) -> void:
	if not Value:
		if Box:
			Box.disconnect("changed", self, "OnChanged")
	
	Box = Value
	if Box:
		if not Box.is_connected("changed", self, "OnChanged"):
			var _Error = Box.connect("changed", self, "OnChanged")
	
	update()
	

func OnChanged() -> void:
	update()
	

func SetSize(Value) -> void:
	Size = Value
	update()
	

func SetColor(InColor: Color) -> void:
	var FlatBox = Box as StyleBoxFlat
	if FlatBox:
		FlatBox.bg_color = InColor
	

func SetHighlight(Highlight: bool) -> void:
	var FlatBox = Box as StyleBoxFlat
	if FlatBox:
		var BorderColor = Color.yellow if Highlight else Color.transparent
		FlatBox.border_color = BorderColor
		update()
	

func GetBounds(Offset := Vector2.ZERO) -> Rect2:
	var Position: Vector2 = Size * -0.5 if Center else Vector2.ZERO
	return Rect2(Position + Offset, Size)
