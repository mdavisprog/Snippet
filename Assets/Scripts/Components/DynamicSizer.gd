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

class_name DynamicSizer
extends Node

# Node that allows resizing the parent's bounds through the mouse. This currently
# only handles cases where the parent is a Control, but could be expanded further
# to include Node2D based nodes.

# Emitted when a drag operation has occurred.
signal OnDrag()

# The sides of the parent that can be adjusted.
enum SIZER {N = 1, S = 2, E = 4, W = 8}

# The width of the handle on the edges.
export var Width = 10

# Bitwise flag set to filter which sides can be resized.
export(int, FLAGS, "N", "S", "E", "W") var Filter = SIZER.N | SIZER.S | SIZER.E | SIZER.W

# Additional margin to apply to each direction.
export var MarginN = 0.0
export var MarginS = 0.0
export var MarginE = 0.0
export var MarginW = 0.0

# Flags for this sizer usually updated 
var Flags = 0

# Set if Flags is not empty when a valid area is clicked.
var Drag = false

func _input(event: InputEvent) -> void:
	var MouseMotion = event as InputEventMouseMotion
	if MouseMotion:
		if Drag:
			var Position: Vector2 = GetPosition()
			var Size: Vector2 = GetSize()
			var MinSize: Vector2 = GetMinSize()
			if Flags & SIZER.N:
				if Size.y - MouseMotion.relative.y > MinSize.y:
					Position.y += MouseMotion.relative.y
					Size.y -= MouseMotion.relative.y
			if Flags & SIZER.S:
				Size.y += MouseMotion.relative.y
			if Flags & SIZER.W:
				if Size.x - MouseMotion.relative.x > MinSize.x:
					Position.x += MouseMotion.relative.x
					Size.x -= MouseMotion.relative.x
			if Flags & SIZER.E:
				Size.x += MouseMotion.relative.x
			
			SetPosition(Position)
			SetSize(Size)
			
			emit_signal("OnDrag")
		else:
			Flags = 0
			if GetSizerBounds(SIZER.N).has_point(MouseMotion.global_position):
				Flags |= SIZER.N if Filter & SIZER.N else 0
			if GetSizerBounds(SIZER.S).has_point(MouseMotion.global_position):
				Flags |= SIZER.S if Filter & SIZER.S else 0
			if GetSizerBounds(SIZER.E).has_point(MouseMotion.global_position):
				Flags |= SIZER.E if Filter & SIZER.E else 0
			if GetSizerBounds(SIZER.W).has_point(MouseMotion.global_position):
				Flags |= SIZER.W if Filter & SIZER.W else 0
			
			var CursorShape = Control.CURSOR_ARROW
			if Flags & SIZER.N:
				if Flags & SIZER.E: CursorShape = Control.CURSOR_BDIAGSIZE
				elif Flags & SIZER.W: CursorShape = Control.CURSOR_FDIAGSIZE
				else: CursorShape = Control.CURSOR_VSIZE
			elif Flags & SIZER.S:
				if Flags & SIZER.W: CursorShape = Control.CURSOR_BDIAGSIZE
				elif Flags & SIZER.E: CursorShape = Control.CURSOR_FDIAGSIZE
				else: CursorShape = Control.CURSOR_VSIZE
			elif Flags & SIZER.E or Flags & SIZER.W:
				CursorShape = Control.CURSOR_HSIZE
			
			SetMouseCursor(CursorShape)
	
	var MouseButton = event as InputEventMouseButton
	if MouseButton:
		if MouseButton.button_index == BUTTON_LEFT:
			Drag = MouseButton.pressed and Flags != 0
	

func GetPosition() -> Vector2:
	var Result = Vector2.ZERO
	
	var ParentControl = get_parent() as Control
	if ParentControl:
		Result = ParentControl.rect_global_position
	
	return Result

func GetSize() -> Vector2:
	var Result = Vector2.ZERO
	
	var ParentControl = get_parent() as Control
	if ParentControl:
		Result = ParentControl.rect_size
	
	return Result

func GetMinSize() -> Vector2:
	var Result = Vector2.ZERO
	
	var ParentControl = get_parent() as Control
	if ParentControl:
		Result = ParentControl.rect_min_size
	
	return Result

func GetSizerBounds(Sizer: int) -> Rect2:
	var Result = Rect2()
	var Size: Vector2 = GetSize()
	var Min: Vector2 = GetPosition()
	var Max: Vector2 = Min + Size
	var HalfW = Width / 2
	
	match (Sizer):
		SIZER.N:
			Result.position = Vector2(Min.x, Min.y - HalfW + MarginN)
			Result.size = Vector2(Size.x, Width)
		SIZER.S:
			Result.position = Vector2(Min.x, Max.y - HalfW + MarginS)
			Result.size = Vector2(Size.x, Width)
		SIZER.W:
			Result.position = Vector2(Min.x - HalfW + MarginW, Min.y)
			Result.size = Vector2(Width, Size.y)
		SIZER.E:
			Result.position = Vector2(Max.x - HalfW + MarginE, Min.y)
			Result.size = Vector2(Width, Size.y)
	
	return Result

func SetMouseCursor(Cursor: int) -> void:
	var ParentControl = get_parent() as Control
	if ParentControl:
		if ParentControl.get_cursor_shape() != Cursor:
			ParentControl.mouse_default_cursor_shape = Cursor
	

func SetPosition(Position: Vector2) -> void:
	var ParentControl = get_parent() as Control
	if ParentControl:
		ParentControl.rect_global_position = Position
	

func SetSize(Size: Vector2) -> void:
	var ParentControl = get_parent() as Control
	if ParentControl:
		ParentControl.rect_size = Size
	
