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
class_name FloatingWindow
extends Control

# Control that mimics the WindowDialog control but outside of the popup ecosystem.

# The area size for the sizer handles.
const SIZER_HANDLE_SIZE = 5

# Access to hide the close button.
export(bool) var HideCloseButton = false setget SetHideCloseButton

enum OP {
	NONE,
	MOVE,
	RESIZE,
}

enum SIZER {N = 1, S = 2, E = 4, W = 8}

# The current operation being performed on the window.
var Op = OP.NONE

# The flags currently applied to the sizer.
var SizerFlags = 0

# Reference to the Title label.
onready var Title: Label = $Panel/VBoxContainer/TitleContainer/Title

# Adjust the size of the close button to match the height of the title.
onready var CloseButton: TextureButton = $Panel/CloseButton

func _ready() -> void:
	var _Error = null
	
	if Title:
		_Error = Title.connect("resized", self, "OnTitleResized")
	
	if Engine.editor_hint:
		# Editor only code just go here.
		return
	
	_Error = connect("resized", self, "OnResized")
	
	if CloseButton:
		_Error = CloseButton.connect("pressed", self, "OnClosePressed")
		UpdateCloseButton()
	

func _enter_tree() -> void:
	UpdateCloseButton()
	
	if Engine.editor_hint:
		return
	

func has_point(point: Vector2) -> bool:
	var Bounds = Rect2(Vector2.ZERO, rect_size)
	Bounds.position += Vector2(-SIZER_HANDLE_SIZE, -SIZER_HANDLE_SIZE)
	Bounds.size += Vector2(SIZER_HANDLE_SIZE * 2, SIZER_HANDLE_SIZE * 2)
	return Bounds.has_point(point)

func _gui_input(event: InputEvent) -> void:
	if Engine.editor_hint:
		return
	
	var MouseButton = event as InputEventMouseButton
	if MouseButton:
		if MouseButton.pressed:
			if MouseButton.button_index == BUTTON_LEFT:
				if SizerFlags != 0:
					Op = OP.RESIZE
				else:
					var PanelNode: Control = $Panel
					if PanelNode and PanelNode.get_rect().has_point(MouseButton.position):
						Op = OP.MOVE
		else:
			Op = OP.NONE
	
	var MouseMotion = event as InputEventMouseMotion
	if MouseMotion:
		match (Op):
			OP.NONE:
				SizerFlags = GetSizerFlags(MouseMotion.global_position)
				
				var CursorShape = CURSOR_ARROW
				if SizerFlags & SIZER.N:
					if SizerFlags & SIZER.E: CursorShape = CURSOR_BDIAGSIZE
					elif SizerFlags & SIZER.W: CursorShape = CURSOR_FDIAGSIZE
					else: CursorShape = CURSOR_VSIZE
				elif SizerFlags & SIZER.S:
					if SizerFlags & SIZER.W: CursorShape = CURSOR_BDIAGSIZE
					elif SizerFlags & SIZER.E: CursorShape = CURSOR_FDIAGSIZE
					else: CursorShape = CURSOR_VSIZE
				elif SizerFlags & SIZER.E or SizerFlags & SIZER.W:
					CursorShape = CURSOR_HSIZE
				
				if get_cursor_shape() != CursorShape:
					mouse_default_cursor_shape = CursorShape
			OP.MOVE:
				rect_position += MouseMotion.relative
			OP.RESIZE:
				if SizerFlags & SIZER.N:
					rect_position.y += MouseMotion.relative.y
					rect_size.y += -MouseMotion.relative.y
				if SizerFlags & SIZER.S:
					rect_size.y += MouseMotion.relative.y
				if SizerFlags & SIZER.W:
					rect_position.x += MouseMotion.relative.x
					rect_size.x += -MouseMotion.relative.x
				if SizerFlags & SIZER.E:
					rect_size.x += MouseMotion.relative.x
	

func OnTitleResized() -> void:
	if not Title:
		return
	
	if Title.text.empty():
		margin_top = 0
	else:
		margin_top = -Title.rect_size.y
	
	UpdateCloseButton()
	

func UpdateCloseButton() -> void:
	if not CloseButton:
		return
	
	# The close button will need to be resized. Start with a default size and attempt
	# to retrieve an associated size.
	var TitleH = 14
	
	var TheTheme: Theme = get_theme()
	if TheTheme and TheTheme.default_font:
		TitleH = TheTheme.default_font.get_height()
	
	if Title:
		TitleH = Title.rect_size.y
	
	CloseButton.expand = true
	CloseButton.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	CloseButton.rect_min_size = Vector2(TitleH, TitleH) * 0.5
	CloseButton.rect_size = CloseButton.rect_min_size
	
	# Position the button in the top left corner.
	CloseButton.rect_position = Vector2(rect_size.x - CloseButton.rect_size.x - SIZER_HANDLE_SIZE, SIZER_HANDLE_SIZE)
	
	update()
	

func OnResized() -> void:
	UpdateCloseButton()
	

func OnClosePressed() -> void:
	queue_free()
	

func SetHideCloseButton(Value: bool) -> void:
	HideCloseButton = Value
	if CloseButton:
		CloseButton.visible = not HideCloseButton
		update()
	

func GetSizerFlags(Point: Vector2) -> int:
	var Result = 0
	
	var Bounds: Rect2 = get_rect()
	if Bounds.position.y <= Point.y and Point.y <= Bounds.position.y + SIZER_HANDLE_SIZE:
		Result = SIZER.N
	elif Bounds.end.y - SIZER_HANDLE_SIZE <= Point.y and Point.y <= Bounds.end.y:
		Result = SIZER.S
	
	if Bounds.position.x <= Point.x and Point.x <= Bounds.position.x + SIZER_HANDLE_SIZE:
		Result |= SIZER.W
	elif Bounds.end.x - SIZER_HANDLE_SIZE <= Point.x and Point.x <= Bounds.end.x:
		Result |= SIZER.E
	
	return Result
