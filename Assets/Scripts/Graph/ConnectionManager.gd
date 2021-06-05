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

class_name ConnectionManager
extends Node

# Node to manage any active connections in the workspace.

# The connection scene to instance.
export(PackedScene) var ConnectionScene: PackedScene

# The current active pin.
var Active: PinConnection = null

func _input(event: InputEvent) -> void:
	if not Active:
		return
	
	var MouseMotion = event as InputEventMouseMotion
	if MouseMotion:
		Active.End = MouseMotion.global_position
	
	var MouseButton = event as InputEventMouseButton
	if MouseButton:
		if MouseButton.pressed and Active:
			# Notify the connection of the Pin that is associated with this
			# connection.
			var Parent = Active.get_parent() as Pin
			if Parent:
				Parent.Connection = null
				Parent.update()
			
			Active.queue_free()
			Active = null
	

func CreateConnection(Parent: Pin) -> PinConnection:
	if not ConnectionScene:
		push_error("ConnectionScene is null.")
		return null
	
	var Result: PinConnection = ConnectionScene.instance()
	if not Result:
		push_error("ConnectionScene is not of type PinConnection.")
		return null
	
	if Parent:
		Parent.add_child(Result)
		Parent.Connection = Result
	
	return Result

func CreateActive(Parent: Pin) -> void:
	if Active:
		return
	
	Active = CreateConnection(Parent)
	

func DestroyActive() -> void:
	if not Active:
		return
	
	Active.queue_free()
	Active = null
	

func CanConnect(A: Pin, B: Pin) -> bool:
	if not A or not B:
		return false
	
	# Prevent connecting to the same snippet.
	if A.get_parent() == B.get_parent():
		return false
	
	if A.Type == B.Type:
		return false
	
	return true

func ConnectTo(InPin: Pin) -> bool:
	if not InPin:
		return false
	
	if not Active:
		return false
	
	var Parent = Active.get_parent() as Pin
	if not Parent:
		return false
	
	if not CanConnect(Parent, InPin):
		return false
	
	if InPin.Type == Pin.TYPE.OUTPUT:
		Parent.remove_child(Active)
		InPin.add_child(Active)
		InPin.Connection = Active
		InPin = Parent
	
	InPin.Connection = Active
	Active.EndPin = InPin
	Active = null
	
	return true

func Modify(InPin: Pin) -> void:
	if not InPin:
		return
	
	if not InPin.Connection:
		return
	
	if not InPin.Connection.EndPin:
		return
	
	if Active:
		return
	
	Active = InPin.Connection
	
	# Reparent before setting End position to prevent flickering.
	if InPin.Type == Pin.TYPE.OUTPUT:
		InPin.remove_child(Active)
		Active.EndPin.add_child(Active)
	
	Active.EndPin = null
	Active.End = Active.get_global_mouse_position()
	InPin.Connection = null
	

func Disconnect(InPin: Pin) -> void:
	if not InPin:
		return
	
	if not InPin.Connection:
		return
	
	if InPin.Type == Pin.TYPE.OUTPUT:
		if InPin.Connection.EndPin:
			InPin.Connection.EndPin.Connection = null
	else:
		var Other = InPin.Connection.get_parent() as Pin
		if Other:
			Other.Connection = null
	
	InPin.Connection.queue_free()
	InPin.Connection = null
	

func ConnectSnippets(A, B) -> bool:
	if not A or not B:
		return false
	
	CreateActive(A.OutputPin)
	if not ConnectTo(B.InputPin):
		return false
	
	return true
