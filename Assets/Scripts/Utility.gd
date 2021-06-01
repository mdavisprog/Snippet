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

extends Node

# A Utility class that can be used globally. This is achieved by adding this
# object to the project's Auto Load list.

# List of node paths that can be accessed globally.
const UI = @"/root/Main/UILayer/UI"
const UIFACTORY = @"/root/Main/UILayer/UI/UIFactory"
const GRAPH = @"/root/Main/SnippetGraph"
const CONNECTIONS = @"/root/Main/SnippetGraph/Connections"

func GetTop(InControl: Control) -> Control:
	if not InControl:
		return null
	
	var Result: Control = InControl.get_parent_control()
	
	if not Result:
		return InControl
	
	var Last = null
	while Result:
		Last = Result
		Result = Result.get_parent_control()
	
	Result = Last
	return Result
	

func MessageBox(Title: String, Message: String, Callback: FuncRef, Type := MessageBox.TYPE.OKCANCEL) -> void:
	var UINode = get_node(UI)
	if not UINode:
		return
	
	UINode.PopupsNode.MessageBox.Show(Title, Message, Callback, Type)
	

func ShowFileExplorer(Callback: FuncRef) -> void:
	var UINode = get_node(UI)
	if not UINode:
		return
	
	UINode.PopupsNode.FileExplorer.Show(Callback)
	
