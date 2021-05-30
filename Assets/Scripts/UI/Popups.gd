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

class_name Popups
extends Control

# Control to hold behavior related to popups.

# Options for when the developer clicks on an empty area of the workspace.
onready var GraphMenu: GraphPopupMenu = $GraphPopupMenu

# Options for when the developer clicks on a snippet.
onready var SnippetMenu: SnippetPopupMenu = $SnippetPopupMenu

# Modal dialog displayed when conveying information to the user that requires input.
onready var MessageBox = $MessageBox

# File explorer that can be accessed globally.
onready var FileExplorer: FileDialog = $FileExplorer

func _ready() -> void:
	FileExplorer.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
