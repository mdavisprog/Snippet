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
class_name Snippet
extends Node2D

# Represents a single node in a graph.

enum STATE {
	NORMAL,
	LOCKED,
}

# Emitted when the state of this snippet is updated.
#
# InSnippet: Snippet
# InState: STATE
signal OnStateChanged(InSnippet, InState)

# Border to apply to all sides of the background around the title.
export(Vector2) var Border: Vector2 setget SetBorder

# Pin scene to instance for setting up connections.
export(PackedScene) var PinScene: PackedScene

# Reference to the background.
onready var BackgroundNode: Background2D = $Background

# Reference to the title label.
onready var TitleNode: Label2D = $Background/Title

# Plays animations for additional feedback.
onready var Animations: AnimationPlayer = $Background/Animations

# The snippet data associated with this visual node.
var Data: SnippetData = null

# A SHA-1 has of the unmodified text.
var TextHash = ""

# The state of the snippet. The state dictates what actions can be taken
# with this snippet.
var State = STATE.NORMAL

# The pins used to connect this snippet to others.
var InputPin: Pin = null
var OutputPin: Pin = null

func _ready() -> void:
	var _Error
	if TitleNode:
		_Error = TitleNode.connect("TextChanged", self, "OnTextChanged")
	
	add_to_group("Snippet")
	
	if Engine.editor_hint:
		return
	
	InputPin = NewPin(Pin.TYPE.INPUT)
	OutputPin = NewPin()
	
	_Error = Animations.connect("animation_finished", self, "OnAnimationFinished")
	_Error = Runtime.connect("OnSnippetStart", self, "OnSnippetStart")
	_Error = Runtime.connect("OnSnippetEnd", self, "OnSnippetEnd")
	

func _process(_delta: float) -> void:
	if Engine.editor_hint:
		return
	
	if Animations.is_playing():
		BackgroundNode.update()
	

func SetTitle(Title: String) -> void:
	if State == STATE.LOCKED:
		return
	
	if TitleNode:
		TitleNode.Text = Title
	

func GetTitle() -> String:
	return TitleNode.Text

func SetColor(InColor: Color) -> void:
	if State == STATE.LOCKED:
		return
	
	if BackgroundNode:
		BackgroundNode.SetColor(InColor)
	

func OnTextChanged(_Value: String) -> void:
	Update()
	

func SetBorder(Value: Vector2) -> void:
	Border = Value
	Update()
	

func Update() -> void:
	if TitleNode:
		var PinSize: Vector2 = GetPinSize()
		var Size: Vector2 = TitleNode.GetSize()
		BackgroundNode.SetSize(Size + Border + Vector2(0, PinSize.y))
		
		var Bounds: Rect2 = BackgroundNode.GetBounds()
		TitleNode.position = Vector2(0, Bounds.position.y + Size.y)
		
		var Y = TitleNode.position.y + PinSize.y * 0.75
		
		if InputPin:
			InputPin.position = Vector2(Bounds.position.x + Border.x, Y)
		
		if OutputPin:
			OutputPin.position = Vector2(Bounds.end.x - Border.x, Y)
	

func OnMouseEntered() -> void:
	if State == STATE.LOCKED:
		return
	
	if BackgroundNode:
		BackgroundNode.SetHighlight(true)
	

func OnMouseExited() -> void:
	if State == STATE.LOCKED:
		return
	
	if BackgroundNode:
		BackgroundNode.SetHighlight(false)
	

func Contains(Point: Vector2) -> bool:
	return BackgroundNode.GetBounds(global_position).has_point(Point)

func SetState(InState: int) -> void:
	if State == InState:
		return
	
	State = InState
	emit_signal("OnStateChanged", self, State)
	

func OnPinPressed(InPin: Pin) -> void:
	if Runtime.IsRunning():
		return
	
	var Connections: ConnectionManager = get_node_or_null(Utility.CONNECTIONS)
	if not Connections:
		push_error("Workspace does not contain a ConnectionManager node.")
		return
	
	var _Result = null
	if OutputPin == InPin:
		if Connections.Active:
			_Result = Connections.ConnectTo(OutputPin)
		elif OutputPin.Connection:
			Connections.Modify(OutputPin)
		else:
			Connections.CreateActive(OutputPin)
	elif InputPin == InPin:
		# Attempting to make a connection.
		if Connections.Active:
			_Result = Connections.ConnectTo(InputPin)
		elif InputPin.Connection:
			Connections.Modify(InputPin)
		else:
			Connections.CreateActive(InputPin)
	

func NewPin(Type := Pin.TYPE.OUTPUT) -> Pin:
	if not PinScene:
		return null
	
	var Result: Pin = PinScene.instance()
	Result.Type = Type
	var _Error = Result.connect("OnPressed", self, "OnPinPressed")
	BackgroundNode.add_child(Result)
	return Result

func Move(Delta: Vector2) -> void:
	position += Delta
	
	if InputPin:
		InputPin.Update()
	
	if OutputPin:
		OutputPin.Update()
	

func RemovePin(Type: int) -> void:
	if Type == Pin.TYPE.INPUT:
		BackgroundNode.remove_child(InputPin)
		InputPin.queue_free()
		InputPin = null
	elif Type == Pin.TYPE.OUTPUT:
		BackgroundNode.remove_child(OutputPin)
		OutputPin.queue_free()
		OutputPin = null
	

func GetPinSize() -> Vector2:
	if InputPin:
		return InputPin.GetSize()
	
	if OutputPin:
		return OutputPin.GetSize()
	
	return Vector2.ZERO

func GetNextSnippet() -> Snippet:
	if not OutputPin:
		return null
	
	var Connection: PinConnection = OutputPin.Connection
	
	if not Connection:
		return null
	
	if not Connection.EndPin:
		return null
	
	# The pin's parent is the background node. The parent of that node is the snippet.
	return Connection.EndPin.get_parent().get_parent()

func Destroy() -> void:
	var Connections: ConnectionManager = get_node_or_null(Utility.CONNECTIONS)
	if not Connections:
		return
	
	Connections.Disconnect(InputPin)
	Connections.Disconnect(OutputPin)
	
	if not Data:
		return
	
	var _Result = Workspace.DeleteSnippet(Data.Name)
	queue_free()
	

func Save() -> bool:
	if not Data:
		return false
	
	var Hash: String = Data.Source.sha1_text()
	if TextHash == Hash:
		return false
	
	TextHash = Hash
	return Workspace.SaveSnippet(Data)

func OnAnimationFinished(_Name: String) -> void:
	State = STATE.NORMAL
	

func OnSnippetStart(InSnippet: SnippetData) -> void:
	if InSnippet != Data:
		return
	
	if Animations.is_playing():
		Animations.stop()
	
	# Play the first frame so that the color appears.
	Animations.play("Temperature", -1.0, 0.0)
	State = STATE.LOCKED
	
	if InputPin and InputPin.Connection and not Runtime.IsUnitTest():
		InputPin.Connection.PlayAnimation()
	

func OnSnippetEnd(InSnippet: SnippetData) -> void:
	if InSnippet != Data:
		return
	
	# Finish playing out the animation.
	Animations.play("Temperature")
	State = STATE.NORMAL
	
	if InputPin and InputPin.Connection:
		InputPin.Connection.StopAnimation()
	

func SetData(InData: SnippetData) -> void:
	Data = InData
	if Data:
		TextHash = Data.Source.sha1_text()
		SetTitle(Data.Name)
	else:
		TextHash = ""
		SetTitle("Empty")
	
