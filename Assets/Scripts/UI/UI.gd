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

class_name UI
extends Control

# The tooltip font to use.
export(Font) var TooltipFont

# Hold a reference to the Workspace node.
var WorkspaceNode: Workspace = null

# HACK: Keep track developer workspace operations. Prevent opening context menu.
var PerformedOp = false

# Should contain access to all popup windows.
onready var PopupsNode: Popups = $Popups

# Place for scene instancing.
onready var UIFactoryNode: UIFactory = $UIFactory

# Virtual machine used to execute all connected snippets.
onready var Code: VirtualMachine = $Code

func _ready() -> void:
	var _Error = null
	
	if not WorkspaceNode:
		WorkspaceNode = get_node_or_null(Utility.GetWorkspacePath())
		if WorkspaceNode:
			_Error = WorkspaceNode.connect("OnOperation", self, "OnWorkspaceOperation")
			_Error = WorkspaceNode.connect("OnAddSnippet", self, "OnWorkspaceAddSnippet")
		else:
			push_error("No valid Workspace node found at: " + Utility.GetWorkspacePath())
	
	if TooltipFont:
		theme.set_font("font", "TooltipLabel", TooltipFont)
	

func _gui_input(event: InputEvent) -> void:
	var MouseButton = event as InputEventMouseButton
	if MouseButton:
		if MouseButton.button_index == BUTTON_RIGHT:
			if not MouseButton.pressed and not PerformedOp:
				if WorkspaceNode:
					if WorkspaceNode.HoveredSnippet:
						PopupsNode.SnippetMenu.SetSnippet(WorkspaceNode.HoveredSnippet)
						PopupsNode.SnippetMenu.popup_at_mouse()
					else:
						PopupsNode.GraphMenu.popup_at_mouse()
	

func OnWorkspaceOperation(Phase: int, Operation: int) -> void:
	match (Phase):
		Workspace.Phases.Begin:
			PerformedOp = false
		Workspace.Phases.End:
			PerformedOp = true
	
	match (Operation):
		Workspace.Ops.Edit:
			EditSnippet(WorkspaceNode.SelectedSnippet)
	

func OnWorkspaceAddSnippet(Item: Snippet) -> void:
	EditSnippet(Item, true)
	

func EditSnippet(Item: Snippet, IsNew := false) -> void:
	if not Item:
		return
	
	if not UIFactoryNode or not UIFactoryNode.SnippetWindowTemplate:
		return
	
	var Items: Array = get_tree().get_nodes_in_group("SnippetWindows")
	for I in Items:
		if I.This == Item:
			return
	
	var SnippetWindowInstance: SnippetWindow = UIFactoryNode.SnippetWindowTemplate.instance()
	add_child(SnippetWindowInstance)
	SnippetWindowInstance.Show(Item)
	SnippetWindowInstance.Editor.Select("New_Snippet")
	var _Error = SnippetWindowInstance.connect("OnRunAll", self, "OnRun")
	
	if IsNew:
		SnippetWindowInstance.EditTitle()
	

# TODO: Look into placing this into a separate system.
func OnRun() -> void:
	if not Code:
		return
	
	if not WorkspaceNode:
		return
	
	Log.Clear()
	Log.Info("Running program.")
	
	var ExecResult = null
	var Next: Snippet = WorkspaceNode.MainSnippet
	while Next:
		var Name: String = Next.GetTitle()
		var Source: String = Next.Text
		
		# Reset to a clean slate for each snippet for now.
		# TODO: Need to pass on data returned from this snippet to the next connected snippet.
		Code.Reset()
		
		if ExecResult:
			Code.VM.PushArguments(ExecResult.Results)
		
		ExecResult = Code.Execute(Source)
		if not ExecResult.Success:
			Log.Error("Failed to execute snippet '" + Name + "'.\n" + ExecResult.GetError().Contents);
			break
		
		Next = Next.GetNextSnippet()
	
