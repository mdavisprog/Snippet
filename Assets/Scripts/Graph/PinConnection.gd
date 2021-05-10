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

# The pin this connection is connected to. This should be the InputPin of a snippet.
# No type is specified here due to GDScript cyclic references.
var EndPin = null setget SetEndPin

# An optional end position can be set. This will be used if no end pin is set.
var End = Vector2.ZERO setget SetEnd

func _draw() -> void:
	var Dest = End if not EndPin else to_local(EndPin.global_position)
	draw_line(Vector2.ZERO, Dest, Color.whitesmoke, 5.0, true)
	

func SetEndPin(Value) -> void:
	if EndPin != Value:
		EndPin = Value
		update()
	

func SetEnd(Value: Vector2) -> void:
	End = to_local(Value)
	update()
	
