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

# Layer to add all SnippetWindow instances to.
onready var SnippetsLayer = $SnippetsLayer

# Should contain access to all popup windows.
onready var PopupsNode: Popups = $Popups

# Place for scene instancing.
onready var UIFactoryNode: UIFactory = $UIFactory

func _ready() -> void:
	var _Error = null
	
	if not SnippetGraphNode:
		SnippetGraphNode = get_node_or_null(Utility.GRAPH)
		if SnippetGraphNode:
			_Error = SnippetGraphNode.connect("OnOperation", self, "OnSnippetGraphOperation")
			_Error = SnippetGraphNode.connect("OnAddSnippet", self, "OnSnippetGraphAddSnippet")
		else:
			push_error("No valid SnippetGraph node found at: " + Utility.GRAPH)
	
	if TooltipFont:
		theme.set_font("font", "TooltipLabel", TooltipFont)
	
	# Handle the system quit request ourselves.
	get_tree().set_auto_accept_quit(false)
	

func _gui_input(event: InputEvent) -> void:
	if not Workspace.IsLoaded() or Runtime.IsRunning():
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
			TryQuit()
	

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
	
	if IsNew:
		# Do not call 'SetData' to keep the text hash from being updated.
		Item.Data = Workspace.CreateSnippet("")
		Item.SetTitle("")
	
	if not UIFactoryNode or not UIFactoryNode.SnippetWindowTemplate:
		return
	
	var Items: Array = get_tree().get_nodes_in_group("SnippetWindows")
	for I in Items:
		if I.This == Item:
			return
	
	var SnippetWindowInstance: SnippetWindow = UIFactoryNode.SnippetWindowTemplate.instance()
	SnippetsLayer.add_child(SnippetWindowInstance)
	SnippetWindowInstance.Show(Item)
	SnippetWindowInstance.Editor.Select("New_Snippet")
	
	if IsNew:
		SnippetWindowInstance.SetTitle("new_snippet")
		SnippetWindowInstance.call_deferred("EditTitle")
	

func OnQuitSavePrompt(Dir: String) -> void:
	if Dir.empty():
		Quit()
		return
	
	var Source: String = Workspace.Location
	Workspace.Close()
	# For now, just delete the destination and copy the contents from the temp directory.
	var _Result = Workspace.Delete(Dir)
	_Result = Workspace.Copy(Source, Dir)
	AppSettings.Data["LastOpened"] = Dir
	Quit()
	

func TryQuit() -> void:
	if Workspace.IsTempModified():
		Utility.MessageBox(
			"Save Changes?",
			"Changes have been made to the new workspace. Would you like to save this workspace?",
			funcref(self, "OnConfirm"),
			MessageBox.TYPE.YESNO)
	else:
		Quit()
	

func Quit(ExitCode := 0) -> void:
	Workspace.Close()
	Runtime.Stop()
	get_tree().quit(ExitCode)
	
