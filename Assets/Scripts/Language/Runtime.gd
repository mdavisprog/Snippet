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

# Emitted when the program has hit a breakpoint.
#
# Line: int - The line number of the active snippet.
signal OnBreak(Line)

# Emitted when the Runtime has ended.
signal OnEnd()

# Emitted when a snippet is about to be executed.
#
# InSnippet: SnippetData
signal OnSnippetStart(InSnippet)

# Emitted when a snippet has finished execution.
#
# InSnippet: SnippetData
signal OnSnippetEnd(InSnippet)

enum EXEC_TYPE {
	ALL,
	UNITTEST,
}

# Execute snippets on a separate thread to keep from blocking the main thread.
var Latent = null

# Dictionary used to pass information when executing in a separate thread.
var Arguments = {}

# The currently executing snippet.
var ActiveSnippet: SnippetData = null

# Store the result of the last snippet execution.
var ActiveResult = null

# Flag set to true when the threaded operation is complete.
var IsActiveComplete = false

# The type of execution the runtime is engaged in.
var ExecType = EXEC_TYPE.ALL

# The instanced virtual machine with scene templates and instancing.
onready var Code: VirtualMachine = $Code

func _ready() -> void:
	var _Error = Code.connect("OnBreak", self, "OnBreak")
	

func _exit_tree() -> void:
	if Latent:
		Latent.wait_to_finish()
		Latent = null
	

func _process(_delta: float) -> void:
	if ActiveSnippet:
		if IsActiveComplete:
			FinishSnippet(ActiveSnippet, ExecType == EXEC_TYPE.ALL)
	

func IsEnabled() -> bool:
	return Code != null

func IsRunning() -> bool:
	return ActiveSnippet != null

func IsPaused() -> bool:
	return Code.IsPaused()

func IsActiveSnippet(InSnippet: SnippetData) -> bool:
	return ActiveSnippet == InSnippet

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
	
	ExecuteSnippet(SnippetGraphNode.MainSnippet.Data)
	

func ExecuteSnippet(InSnippet: SnippetData, IsUnitTest := false, SkipBreakpoints := false) -> void:
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
		"Source": InSnippet.Source,
		"Name": InSnippet.Name,
		"Arguments": Args,
		"Breakpoints": InSnippet.Breakpoints if not SkipBreakpoints else []
	}
	
	Latent = Thread.new()
	Latent.start(self, "ExecuteSnippet_Thread", Arguments)
	

func ExecuteSnippet_Thread(InArguments: Dictionary) -> void:
	var Source: String = InArguments["Source"]
	var Name: String = InArguments["Name"]
	var Args: Array = InArguments["Arguments"]
	var Breakpoints: Array = InArguments["Breakpoints"]
	
	ActiveResult = Code.Execute(Source, Name, Args, Breakpoints)
	IsActiveComplete = true
	
	# TODO: Should error messaging dispatching happend here? Useful for reporting
	# any errors that were dispatched from native.
	

func FinishSnippet(InSnippet: SnippetData, GoToNext := true) -> void:
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
	
	# TODO: Update when 'Next' snippet is stored in SnippetData object.
	var Next: SnippetData = ActiveSnippet.Next
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
	

func Resume() -> void:
	Code.Resume()
	

func Step() -> void:
	Code.Step()
	

func Compile(InSnippet: SnippetData) -> Reference:
	if not InSnippet:
		return null
	
	return Code.Compile(InSnippet.Source)

func OnBreak(Line: int) -> void:
	emit_signal("OnBreak", Line)
	

func UpdateBreakpoints(Breakpoints: Array) -> void:
	Code.UpdateBreakpoints(Breakpoints)
	

func GetVariables() -> Dictionary:
	return Code.GetVariables()

func GetLineBreak() -> int:
	return Code.LineBreak

func ClientSnippetStart(InSnippet: SnippetData) -> void:
	if not InSnippet:
		return
	
	if ActiveSnippet == InSnippet:
		return
	
	ActiveSnippet = InSnippet
	emit_signal("OnSnippetStart", ActiveSnippet)
	

func ClientSnippetEnd(InSnippet: SnippetData) -> void:
	if not InSnippet:
		return
	
	if ActiveSnippet != InSnippet:
		return
	
	emit_signal("OnSnippetEnd", ActiveSnippet)
	ActiveSnippet = null
	
