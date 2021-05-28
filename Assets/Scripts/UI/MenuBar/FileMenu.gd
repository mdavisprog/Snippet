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

class_name FileMenu
extends TextureButtonMenu

# This class handles all options available to the user via the 'File' option.

enum {
	NEW,
	OPEN,
	CLOSE,
	QUIT
}

# File dialog displayed to the develoer.
var Explorer: FileDialog = null

# The option that was selected.
var Selected = NEW

# The pending directory to perform an operation on after some additional user input.
var PendingDir = ""

func _ready() -> void:
	var _Error = null
	if Instance:
		Instance.add_item("New", NEW)
		Instance.add_item("Open", OPEN)
		Instance.add_item("Close", CLOSE)
		Instance.add_separator()
		Instance.add_item("Quit", QUIT)
		
		Instance.set_item_disabled(CLOSE, true)
	
	if not Explorer:
		Explorer = FileDialog.new()
		Explorer.access = FileDialog.ACCESS_FILESYSTEM
		Explorer.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		_Error = Explorer.connect("dir_selected", self, "OnDirSelected")
		
		var Top: Control = Utility.GetTop(self)
		Top.call_deferred("add_child", Explorer)
	
	_Error = Workspace.connect("OnStateChange", self, "OnWorkspaceState")
	

func OnSelected(Id: int) -> void:
	Selected = Id
	match (Id):
		NEW, OPEN:
			Explorer.mode = FileDialog.MODE_OPEN_DIR
			Explorer.popup_centered_ratio()
		CLOSE:
			Workspace.Close()
		QUIT:
			get_tree().quit(0)
	

func OnDirSelected(Dir: String) -> void:
	match (Selected):
		NEW:
			if Workspace.Exists(Dir):
				PendingDir = Dir
				var Instance = ConfirmationDialog.new()
				Instance.name = "ConfirmDlg"
				Instance.dialog_text = "A workspace already exists at '%s'. Would you like to delete its contents?" % Dir
				var _Error = Instance.connect("confirmed", self, "OnConfirmDelete")
				_Error = Instance.get_cancel().connect("pressed", self, "OnCancelDelete")
				var Top = Utility.GetTop(self)
				Top.add_child(Instance)
				Instance.popup_centered()
			else:
				if not Workspace.Create(Dir):
					Log.Error("Failed to create a new workspace at '%s'." % Dir)
		OPEN:
			if not Workspace.Open(Dir):
				Log.Error("Failed to open workspace at '%s'." % Dir)
	

func OnWorkspaceState(State: int) -> void:
	match (State):
		Workspace.STATE.NONE:
			Instance.set_item_disabled(CLOSE, true)
		Workspace.STATE.LOADED:
			Instance.set_item_disabled(CLOSE, false)
	

func OnConfirmDelete() -> void:
	if PendingDir.empty():
		return
	
	var _Result = Workspace.Delete(PendingDir)
	
	if not Workspace.Create(PendingDir):
		Log.Error("Failed to create a new workspace at '%s'." % PendingDir)
	
	QueueFreeConfirmDlg()
	

func OnCancelDelete() -> void:
	QueueFreeConfirmDlg()
	

func QueueFreeConfirmDlg() -> void:
	var Top: Control = Utility.GetTop(self)
	var ConfirmDlg: ConfirmationDialog = Top.get_node("ConfirmDlg")
	if ConfirmDlg:
		ConfirmDlg.queue_free()
	
