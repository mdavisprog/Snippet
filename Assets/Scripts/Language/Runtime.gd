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

# Singleton object that manages the execution of snippets. This script should
# be attached to a scene so that exports can be set.

# Emitted when the Runtime is performing an action.
#
# Action: ACTION
signal OnAction(Action)

# Emitted when a snippet is about to be executed.
#
# InSnippet: Snippet
signal OnExecuteSnippet(InSnippet)

enum ACTION {
	BEGIN,
	END,
}

# The instanced virtual machine with scene templates and instancing.
onready var Code: VirtualMachine = $Code

func IsEnabled() -> bool:
	return Code and Code.VM
	

func Execute() -> void:
	if not IsEnabled():
		return
	
	var SnippetGraphNode: SnippetGraph = get_node(Utility.GRAPH)
	
	Log.Clear()
	Log.Info("Running program.")
	
	emit_signal("OnAction", ACTION.BEGIN)
	
	var ExecResult = null
	var Next: Snippet = SnippetGraphNode.MainSnippet
	while Next:
		var Name: String = Next.GetTitle()
		var Source: String = Next.Text
		
		# Reset to a clean slate for each snippet for now.
		# TODO: Need to pass on data returned from this snippet to the next connected snippet.
		Runtime.Code.Reset()
		
		if ExecResult:
			Code.VM.PushArguments(ExecResult.Results)
		
		emit_signal("OnExecuteSnippet", Next)
		
		ExecResult = Code.Execute(Source)
		if not ExecResult.Success:
			Log.Error("Failed to execute snippet '" + Name + "'.\n" + ExecResult.GetError().Contents);
			break
		
		Next = Next.GetNextSnippet()
	
	emit_signal("OnAction", ACTION.END)
	

