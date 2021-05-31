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

# Hold a reference to the SnippetGraph node.
var SnippetGraphNode: SnippetGraph = null

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
	
	if not SnippetGraphNode:
		SnippetGraphNode = get_node_or_null(Utility.GetSnippetGraphPath())
		if SnippetGraphNode:
			_Error = SnippetGraphNode.connect("OnOperation", self, "OnSnippetGraphOperation")
			_Error = SnippetGraphNode.connect("OnAddSnippet", self, "OnSnippetGraphAddSnippet")
		else:
			push_error("No valid SnippetGraph node found at: " + Utility.GetSnippetGraphPath())
	
	if TooltipFont:
		theme.set_font("font", "TooltipLabel", TooltipFont)
	
	# Handle the system quit request ourselves.
	get_tree().set_auto_accept_quit(false)
	

func _gui_input(event: InputEvent) -> void:
	if not Workspace.IsLoaded():
		return
	
	var MouseButton = event as InputEventMouseButton
	if MouseButton:
		if MouseButton.button_index == BUTTON_RIGHT:
			if not MouseButton.pressed and not PerformedOp:
				if SnippetGraphNode:
					if SnippetGraphNode.HoveredSnippet:
						PopupsNode.SnippetMenu.SetSnippet(SnippetGraphNode.HoveredSnippet)
						PopupsNode.SnippetMenu.popup_at_mouse()
					else:
						PopupsNode.GraphMenu.popup_at_mouse()
	

func _notification(what: int) -> void:
	match (what):
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			if Workspace.IsTempModified():
				Utility.MessageBox(
					"Save Changes?",
					"Changes have been made to the new workspace. Would you like to save this workspace?",
					funcref(self, "OnConfirm"))
			else:
				Quit()
	

func OnConfirm(Confirm: bool) -> void:
	if not Confirm:
		Quit()
		return
	
	Utility.ShowFileExplorer(funcref(self, "OnQuitSavePrompt"))
	

func OnSnippetGraphOperation(Phase: int, Operation: int) -> void:
	match (Phase):
		SnippetGraph.PHASES.BEGIN:
			PerformedOp = false
		SnippetGraph.PHASES.END:
			PerformedOp = true
	
	match (Operation):
		SnippetGraph.OPS.EDIT:
			EditSnippet(SnippetGraphNode.SelectedSnippet)
	

func OnSnippetGraphAddSnippet(Item: Snippet) -> void:
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
		SnippetWindowInstance.call_deferred("EditTitle")
	

# TODO: Look into placing this into a separate system.
func OnRun() -> void:
	if not Code:
		return
	
	if not SnippetGraphNode:
		return
	
	Log.Clear()
	Log.Info("Running program.")
	
	var ExecResult = null
	var Next: Snippet = SnippetGraphNode.MainSnippet
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
	

func OnQuitSavePrompt(Dir: String) -> void:
	if Dir.empty():
		Quit()
		return
	
	var Source: String = Workspace.Location
	Workspace.Close()
	var _Result = Workspace.Copy(Source, Dir)
	Quit()
	

func Quit(ExitCode := 0) -> void:
	Workspace.Close()
	get_tree().quit(ExitCode)
	
