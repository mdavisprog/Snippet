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

# Emitted when this instance is closed.
#
# Instance: FloatingWindow
signal OnClosed(Instance)

# Access to hide the close button.
export(bool) var HideCloseButton = false setget SetHideCloseButton

enum OP {
	NONE,
	MOVE,
	RESIZE,
}

# The current operation being performed on the window.
var Op = OP.NONE

# Reference to the Title label.
onready var Title: Label = $Panel/VBoxContainer/TitleContainer/Title

# Adjust the size of the close button to match the height of the title.
onready var CloseButton: TextureButton = $Panel/CloseButton

# Background panel for all contents. Is also used to block mouse input.
onready var Contents: Panel = $Panel

# Separate node that can handle resizing the window.
onready var Sizer: DynamicSizer = $Sizer

func _ready() -> void:
	var _Error = null
	
	if Engine.editor_hint:
		# Editor only code just go here.
		return
	
	_Error = connect("resized", self, "OnResized")
	_Error = Sizer.connect("OnDrag", self, "OnSizer")
	_Error = Title.connect("resized", self, "OnTitleResized")
	
	if CloseButton:
		_Error = CloseButton.connect("pressed", self, "OnClosePressed")
		UpdateCloseButton()
	

func _enter_tree() -> void:
	UpdateCloseButton()
	
	if Engine.editor_hint:
		return
	

func _gui_input(event: InputEvent) -> void:
	if Engine.editor_hint:
		return
	
	var MouseButton = event as InputEventMouseButton
	if MouseButton:
		if MouseButton.pressed:
			if MouseButton.button_index == BUTTON_LEFT:
				if Contents.get_rect().has_point(MouseButton.position):
					Op = OP.MOVE
		else:
			Op = OP.NONE
	
	var MouseMotion = event as InputEventMouseMotion
	if MouseMotion:
		match (Op):
			OP.MOVE:
				rect_position += MouseMotion.relative
	

func OnTitleResized() -> void:
	rect_min_size = Title.rect_size + Vector2(25, 0)
	

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
	CloseButton.rect_position = Vector2(rect_size.x - CloseButton.rect_size.x - 5, 5)
	
	update()
	

func OnResized() -> void:
	UpdateCloseButton()
	

func OnClosePressed() -> void:
	emit_signal("OnClosed", self)
	queue_free()
	

func SetHideCloseButton(Value: bool) -> void:
	HideCloseButton = Value
	if CloseButton:
		CloseButton.visible = not HideCloseButton
		update()
	

func OnSizer() -> void:
	Op = OP.RESIZE
	

func CancelOp() -> void:
	Op = OP.NONE
	
