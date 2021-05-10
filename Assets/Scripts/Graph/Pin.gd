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
class_name Pin
extends Node2D

# Represents the beginning or an end to a connection between snippets.

enum TYPE {INPUT, OUTPUT}

# OnPressed
#
# InPin: Pin
signal OnPressed(InPin)

enum STATES {
	NORMAL,
	HOVERED,
	FILLED_NORMAL,
	FILLED_HOVERED
}

# The texture used to render the different pin states.
export(Texture) var States: Texture
export(Rect2) var Normal: Rect2
export(Rect2) var Hovered: Rect2
export(Rect2) var Filled_Normal: Rect2
export(Rect2) var Filled_Hovered: Rect2

# The current state of the pin, determined by connection status and mouse hover.
var State = STATES.NORMAL

# The PinConnection associated with this Pin.
var Connection: PinConnection = null setget SetConnection

# The type of pin this pin is. Default is output.
var Type = TYPE.OUTPUT

func _draw() -> void:
	if not States:
		return
	
	var Filled = is_instance_valid(Connection)
	var Region = Rect2()
	match (State):
		STATES.HOVERED:
			Region = Filled_Hovered if Filled else Hovered
		_:
			Region = Filled_Normal if Filled else Normal
	
	var Size: Vector2 = States.get_size()
	draw_texture_rect_region(States, Rect2(Vector2.ZERO + Size * -0.5, States.get_size()), Region)
	

func _input(event: InputEvent) -> void:
	var Motion = event as InputEventMouseMotion
	if Motion:
		var Size: Vector2 = States.get_size() * scale
		var Bounds = Rect2(global_position + Size * -0.5, Size)
		var New = State
		if Bounds.has_point(Motion.global_position):
			New = STATES.HOVERED
		else:
			New = STATES.NORMAL
		
		if State != New:
			State = New
			update()
	
	var MouseButton = event as InputEventMouseButton
	if MouseButton:
		if MouseButton.pressed and MouseButton.button_index == BUTTON_LEFT and State == STATES.HOVERED:
			emit_signal("OnPressed", self)
			get_tree().set_input_as_handled()
	

func GetSize() -> Vector2:
	return Normal.size

func SetConnection(Value: PinConnection) -> void:
	if Connection != Value:
		Connection = Value
		update()
	

func Update() -> void:
	for Child in get_children():
		if Child is PinConnection:
			Child.update()
			break
	
	if Connection:
		Connection.update()
	
