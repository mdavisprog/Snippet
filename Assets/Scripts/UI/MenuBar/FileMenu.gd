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
	CLOSE,
	QUIT
}

var Explorer: FileDialog = null

func _ready() -> void:
	var _Error = null
	if Instance:
		Instance.add_item("New", NEW)
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
	match (Id):
		NEW:
			Explorer.mode = FileDialog.MODE_OPEN_DIR
			Explorer.popup_centered_ratio()
		CLOSE:
			Workspace.Close()
		QUIT:
			get_tree().quit(0)
	

func OnDirSelected(Dir: String) -> void:
	if Workspace.Exists(Dir):
		Log.Error("Workspace already exists at '%s'." % Dir)
		return
	
	if not Workspace.Create(Dir):
		Log.Error("Failed to create a new workspace at '%s'." % Dir)
		return
	

func OnWorkspaceState(State: int) -> void:
	match (State):
		Workspace.STATE.NONE:
			Instance.set_item_disabled(CLOSE, true)
		Workspace.STATE.LOADED:
			Instance.set_item_disabled(CLOSE, false)
	
