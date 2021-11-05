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
extends Node2D

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
	

func _unhandled_input(event: InputEvent) -> void:
	var MouseButton = event as InputEventMouseButton
	if MouseButton:
		if MouseButton.pressed and Active:
			DestroyActive()
	

func CreateConnection(Parent: Pin) -> PinConnection:
	if not ConnectionScene:
		push_error("ConnectionScene is null.")
		return null
	
	var Result: PinConnection = ConnectionScene.instance()
	if not Result:
		push_error("ConnectionScene is not of type PinConnection.")
		return null
	
	if Parent:
		Parent.Connection = Result
		
		if Parent.Type == Pin.TYPE.INPUT:
			Result.EndPin = Parent
		else:
			Result.StartPin = Parent
	
	add_child(Result)
	Result.End = get_global_mouse_position()
	return Result

func CreateActive(Parent: Pin) -> void:
	if Active:
		return
	
	Active = CreateConnection(Parent)
	

func DestroyActive() -> void:
	if not Active:
		return
	
	DestroyConnection(Active)
	Active = null
	

func DestroyConnection(Connection: PinConnection) -> void:
	if not Connection:
		return
	
	remove_child(Connection)
	
	if Connection.StartPin:
		Connection.StartPin.Connection = null
	
	if Connection.EndPin:
		Connection.EndPin.Connection = null
	
	Connection.queue_free()
	

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
	
	var From: Pin = Active.StartPin if Active.StartPin else Active.EndPin
	if not From:
		return false
	
	var To: Pin = InPin
	if not CanConnect(From, To):
		return false
	
	Disconnect(InPin)
	
	if InPin.Type == Pin.TYPE.OUTPUT:
		To = From
		From = InPin
	
	From.Connection = Active
	To.Connection = Active
	
	Active.StartPin = From
	Active.EndPin = To
	Active = null
	
	From.GetSnippet().Data.Next = To.GetSnippet().Data
	
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
	Active.HaltAnimation()
	
	var Out: Pin = Active.StartPin
	var End: Pin = Active.EndPin
	
	Out.GetSnippet().Data.Next = null
	
	if InPin.Type != Pin.TYPE.INPUT:
		Out.Connection = null
		Active.StartPin = null
	else:
		End.Connection = null
		Active.EndPin = null
	
	Active.End = Active.get_global_mouse_position()
	

func Disconnect(InPin: Pin) -> void:
	if not InPin:
		return
	
	if not InPin.Connection:
		return
	
	var Conn: PinConnection = InPin.Connection
	var From: Pin = Conn.StartPin
	
	From.GetSnippet().Data.Next = null
	
	DestroyConnection(Conn)
	

func ConnectSnippets(A, B) -> bool:
	if not A or not B:
		return false
	
	CreateActive(A.OutputPin)
	if not ConnectTo(B.InputPin):
		return false
	
	return true
