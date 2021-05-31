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

class_name SnippetGraph
extends Node2D

# Represents the developer's space where a collection of snippets are inter-connected
# to form a program.

# Emitted when an operation has been performed.
#
# Phase: Phases
# Operation: Ops
signal OnOperation(Phase, Operation)

# Emitted when a new snippet has been added .
#
# Item: Snippet
signal OnAddSnippet(Item)

# The list of operations that can be performed in the graph.
enum OPS {
	NONE,
	TRANSLATE_GRAPH,
	MOVING_SNIPPET,
	EDIT,
}

# The list of possible phases of an operation.
enum PHASES {
	BEGIN,
	END
}

# The type of snippet to create.
export(PackedScene) var SnippetScene: PackedScene

# The current operation being performed.
var Op = OPS.NONE

# Was an actual operation performed. Some operations such as TRANSLATE_GRAPH
# may be primed but not actually used. For cases like this, we want the UI layer
# to handle the input.
var PerformedOp: bool = false

# The selected snippet.
var SelectedSnippet: Snippet = null

# The hovered snippet.
var HoveredSnippet: Snippet = null

# The main snippet. This is where a full program execution begins.
var MainSnippet: Snippet = null

func _ready() -> void:
	var _Error = Workspace.connect("OnStateChange", self, "OnWorkspaceState")
	

func _input(event: InputEvent) -> void:
	if not MainSnippet:
		return
	
	var MouseButton = event as InputEventMouseButton
	if MouseButton:
		if MouseButton.pressed:
			PerformedOp = false
			if MouseButton.button_index == BUTTON_RIGHT:
				Op = OPS.TRANSLATE_GRAPH
			elif MouseButton.button_index == BUTTON_MIDDLE:
				position = Vector2.ZERO
			elif MouseButton.button_index == BUTTON_LEFT:
				if HoveredSnippet:
					SelectedSnippet = HoveredSnippet
					if MouseButton.doubleclick:
						Op = OPS.EDIT
					else:
						Op = OPS.MOVING_SNIPPET
			
			if Op != OPS.NONE:
				emit_signal("OnOperation", PHASES.BEGIN, Op)
		else:
			var LastOp = Op
			Op = OPS.NONE
			SelectedSnippet = null
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			if PerformedOp:
				emit_signal("OnOperation", PHASES.END, LastOp)
				PerformedOp = false
	
	var MouseMotion = event as InputEventMouseMotion
	if MouseMotion:
		if Op == OPS.NONE:
			var Nodes: Array = get_tree().get_nodes_in_group("Snippet")
			for I in Nodes:
				var Item = I as Snippet
				if Item.Contains(MouseMotion.global_position):
					if HoveredSnippet != Item:
						HoveredSnippet = Item
						HoveredSnippet.OnMouseEntered()
				elif HoveredSnippet == Item:
					HoveredSnippet.OnMouseExited()
					HoveredSnippet = null
		
		match (Op):
			OPS.TRANSLATE_GRAPH:
				position += MouseMotion.relative
				
				if not PerformedOp:
					PerformedOp = true
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		if SelectedSnippet:
			SelectedSnippet.Move(MouseMotion.relative)
	

func AddSnippet(ScreenPosition: Vector2, Emit := true) -> Snippet:
	if not SnippetScene:
		push_warning("No Snippet scene specified for instancing.")
		return null
	
	var Result: Snippet = SnippetScene.instance()
	add_child(Result)
	Result.position = to_local(ScreenPosition)
	
	if Emit:
		emit_signal("OnAddSnippet", Result)
	
	return Result
	

func CreateMainSnippet() -> void:
	if MainSnippet:
		return
	
	# For now, offset a little so it is displayed when the app starts.
	# In the future, the camera should focus on the world origin.
	MainSnippet = AddSnippet(Vector2.ZERO, false)
	MainSnippet.Text = "print(\"hello world!\")"
	MainSnippet.SetTitle("main")
	MainSnippet.RemovePin(Pin.TYPE.INPUT)
	FocusPoint(Vector2(-200, -50))
	

func FocusPoint(Point: Vector2) -> void:
	var Size: Vector2 = get_viewport_rect().size
	position = Point + Size * 0.5
	

func OnWorkspaceState(State: int) -> void:
	match (State):
		Workspace.STATE.NONE:
			Clear()
		Workspace.STATE.CLOSING:
			Save()
		Workspace.STATE.LOADED:
			Load()
	

func Save() -> void:
	var Snippets: Array = get_tree().get_nodes_in_group("Snippet")
	
	var Buffer = []
	for Item in Snippets:
		var Entry = {
			"Name": Item.GetTitle(),
			"Position": {
				"X": Item.position.x,
				"Y": Item.position.y
			}
		}
		Buffer.append(Entry)
	
	var _Result = Workspace.SaveVariant("GRAPH", Buffer)
	

func Load() -> void:
	var List = []
	# First, add snippets based on available files.
	var Data: Array = Workspace.GetSnippetData()
	for Item in Data:
		var NewSnippet = AddSnippet(Vector2.ZERO, false)
		NewSnippet.Text = Item.Source
		NewSnippet.Text_Tests = Item.UTSource
		NewSnippet.SetTitle(Item.Name)
		
		if Item.Name == "main":
			MainSnippet = NewSnippet
			MainSnippet.RemovePin(Pin.TYPE.INPUT)
		
		List.append(NewSnippet)
	
	if not MainSnippet:
		CreateMainSnippet()
		var _Result = MainSnippet.Save()
	
	# Now, load in the graph data to position the snippets.
	var Buffer = Workspace.LoadVariant("GRAPH")
	if not Buffer:
		return
	
	for Item in Buffer:
		for Element in List:
			if Element.GetTitle() == Item.Name:
				Element.position = Vector2(Item.Position.X, Item.Position.Y)
	

func Clear() -> void:
	if MainSnippet:
		MainSnippet.queue_free()
		MainSnippet = null
	
	var Snippets: Array = get_tree().get_nodes_in_group("Snippet")
	for Item in Snippets:
		Item.queue_free()
	
