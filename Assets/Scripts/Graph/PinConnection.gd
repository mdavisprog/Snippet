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

class_name PinConnection
extends Node2D

# Represents a curve connecting snippets together through pins. This manages the
# rendering of the curve which requires some conversions between node spaces.

# Iterations between curve points.
const STEP = 32.0

# The pin this connection is connected to. This should be the InputPin of a snippet.
# No type is specified here due to GDScript cyclic references.
var EndPin = null setget SetEndPin

# An optional end position can be set. This will be used if no end pin is set.
var End = Vector2.ZERO setget SetEnd

# The curve object used to calculate the positions used.
var Data = Curve2D.new()

# How long to play the animation for.
var AnimTime = 3.0

# Time remaining for animation.
var AnimTimeRem = 0.0

# The spacing between circles. This value is also used for animating the positions as well.
var Spacing = 0.2

# The time between spacing for animation.
var SpacingTime = 0.0 

func _draw() -> void:
	var Dest = End if not EndPin else to_local(EndPin.global_position)
	Data.clear_points()
	Data.add_point(Vector2.ZERO, Vector2.ZERO, Vector2(350.0, 0.0))
	Data.add_point(Dest, Vector2(-350.0, 0.0), Vector2.ZERO)
	
	# Taken from path_2d.cpp
	for I in range(Data.get_point_count()):
		var Previous: Vector2 = Data.get_point_position(I)
		
		for J in range(1, int(STEP)):
			var T: float = J / STEP
			var Next: Vector2 = Data.interpolate(I, T)
			draw_line(Previous, Next, Color.whitesmoke, 5, true)
			Previous = Next
	
	if AnimTimeRem > 0.0:
		var Radius = min(15.0 * AnimTimeRem, 25.0)
		var I = 0.0
		while I <= (1.0 - Spacing):
			var SubTime = I + SpacingTime
			var Position = Data.interpolate_baked(SubTime * Data.get_baked_length(), true)
			draw_circle(Position, Radius, Color.whitesmoke)
			I += Spacing
	

func _process(delta: float) -> void:
	if AnimTimeRem > 0.0:
		AnimTimeRem -= delta
		SpacingTime += delta * 0.5
		if SpacingTime >= Spacing: SpacingTime = 0.0
		update()
	

func SetEndPin(Value) -> void:
	if EndPin != Value:
		EndPin = Value
		update()
	

func SetEnd(Value: Vector2) -> void:
	End = to_local(Value)
	update()
	

func BeginExecute() -> void:
	AnimTimeRem = AnimTime
	
