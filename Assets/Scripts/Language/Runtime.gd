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

# Emitted when the Runtime is about to start.
signal OnStart()

# Emitted when the Runtime has ended.
signal OnEnd()

# Emitted when a snippet is about to be executed.
#
# InSnippet: Snippet
signal OnSnippetStart(InSnippet)

# Emitted when a snippet has finished execution.
#
# InSnippet: Snippet
signal OnSnippetEnd(InSnippet)

enum ACTION {
	BEGIN,
	END,
}

enum EXEC_TYPE {
	ALL,
	UNITTEST,
}

# Execute snippets on a separate thread to keep from blocking the main thread.
var Latent = null

# Dictionary used to pass information when executing in a separate thread.
var Arguments = {}

# The currently executing snippet.
var ActiveSnippet: Snippet = null

# Store the result of the last snippet execution.
var ActiveResult = null

# Flag set to true when the threaded operation is complete.
var IsActiveComplete = false

# The type of execution the runtime is engaged in.
var ExecType = EXEC_TYPE.ALL

# The instanced virtual machine with scene templates and instancing.
onready var Code: VirtualMachine = $Code

func _exit_tree() -> void:
	if Latent:
		Latent.wait_to_finish()
		Latent = null
	

func _process(_delta: float) -> void:
	if ActiveSnippet:
		if IsActiveComplete:
			FinishSnippet(ActiveSnippet, ExecType == EXEC_TYPE.ALL)
	
	Code.DispatchBuffer()
	

func IsEnabled() -> bool:
	return Code != null

func IsRunning() -> bool:
	return ActiveSnippet != null

func IsUnitTest() -> bool:
	return ExecType == EXEC_TYPE.UNITTEST

func Execute() -> void:
	if not IsEnabled():
		return
	
	# If a latent object already exists, then execution is in progress.
	if Latent:
		return
	
	var SnippetGraphNode: SnippetGraph = get_node(Utility.GRAPH)
	
	Log.Clear()
	Log.Info("Running program.")
	
	emit_signal("OnStart")
	
	ExecuteSnippet(SnippetGraphNode.MainSnippet)
	

func ExecuteSnippet(InSnippet: Snippet, IsUnitTest := false) -> void:
	if not IsEnabled():
		return
	
	if not InSnippet:
		return
	
	if Latent:
		return
	
	ActiveSnippet = InSnippet
	IsActiveComplete = false
	ExecType = EXEC_TYPE.UNITTEST if IsUnitTest else EXEC_TYPE.ALL
	
	var Args = []
	if ActiveResult:
		Args = ActiveResult.Results
	
	emit_signal("OnSnippetStart", InSnippet)
	
	Arguments = {
		"Source": InSnippet.Text,
		"Name": InSnippet.GetTitle(),
		"Arguments": Args
	}
	
	Latent = Thread.new()
	Latent.start(self, "ExecuteSnippet_Thread", Arguments)
	

func ExecuteSnippet_Thread(InArguments: Dictionary) -> void:
	var Source: String = InArguments["Source"]
	var Name: String = InArguments["Name"]
	var Args: Array = InArguments["Arguments"]
	
	ActiveResult = Code.Execute(Source, Name, Args)
	IsActiveComplete = true
	
	# TODO: Should error messaging dispatching happend here? Useful for reporting
	# any errors that were dispatched from native.
	

func FinishSnippet(InSnippet: Snippet, GoToNext := true) -> void:
	if not InSnippet:
		return
	
	# There may not be a valid ActiveResult object if the execution is terminated early.
	if ActiveResult and not ActiveResult.Success:
		Log.Error("Failed to execute snippet '" + InSnippet.GetTitle() + "'.\n" + ActiveResult.GetError().Contents)
		GoToNext = false
	
	emit_signal("OnSnippetEnd", InSnippet)
	
	if Latent:
		Latent.wait_to_finish()
		Latent = null
	
	var Next: Snippet = InSnippet.GetNextSnippet()
	if Next and GoToNext:
		ExecuteSnippet(Next)
	else:
		ActiveSnippet = null
		ActiveResult = null
		# All snippets have been executed. The program has finished.
		emit_signal("OnEnd")
	

func Stop() -> void:
	if not ActiveSnippet:
		return
	
	# This notifies any sleeping threads that the VM is executing that it must be terminated.
	Code.Stop()
	
	FinishSnippet(ActiveSnippet, false)
	

func Compile(InSnippet: Snippet) -> Reference:
	if not InSnippet:
		return null
	
	return Code.Compile(InSnippet.Text)
