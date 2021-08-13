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

# The type of virtual machine to use for any runtime operation.
export(NativeScript) var VMClass: NativeScript

# The current task being executed.
var Task: RuntimeTask = null

# The instanced virtual machine with scene templates and instancing.
onready var Code: VirtualMachine = $Code

func _ready() -> void:
	var _Error = Code.connect("OnBreak", self, "OnBreak")
	

func _exit_tree() -> void:
	if Task:
		Task.Wait()
		Task = null
	

func _process(delta: float) -> void:
	if Task:
		Task._process(delta)
		if Task.IsComplete():
			FinishSnippet(Task.Data, not IsUnitTest())
	

func IsRunning() -> bool:
	return Task != null and Task.Data != null

func IsPaused() -> bool:
	if not Task:
		return false
	
	return Task.IsPaused()

func IsActiveSnippet(InSnippet: SnippetData) -> bool:
	if not Task:
		return false
	
	return Task.Data == InSnippet

func IsUnitTest() -> bool:
	if not Task:
		return false
	
	return Task.IsUnitTest()

func Execute() -> void:
	# If a task already exists, then execution is in progress.
	if Task:
		return
	
	# TODO: Deprecate this to remove dependency.
	var SnippetGraphNode: SnippetGraph = get_node(Utility.GRAPH)
	
	Log.Clear()
	Log.Info("Running program.")
	
	emit_signal("OnStart")
	
	ExecuteSnippet(SnippetGraphNode.MainSnippet.Data)
	

func ExecuteSnippet(InSnippet: SnippetData, IsUnitTest := false, SkipBreakpoints := false, Parameters := []) -> void:
	if not InSnippet:
		return
	
	if Task:
		return
	
	var Args = {
		"skipbp": SkipBreakpoints,
		"params": Parameters
	}
	
	emit_signal("OnSnippetStart", InSnippet)
	
	if IsUnitTest:
		Task = RuntimeTask_RunUT.new()
	else:
		Task = RuntimeTask_Run.new()
	
	Task.Init(VMClass)
	var _Error = Task.connect("OnBreak", self, "OnBreak")
	if not Task.Execute(InSnippet, Args):
		# TODO: emit signal for runtime end
		pass
	

func FinishSnippet(InSnippet: SnippetData, GoToNext := true) -> void:
	if not InSnippet:
		return
	
	var Next = null
	var Result = null
	var SkipBP = false
	if Task:
		Next = Task.Data.Next
		Result = Task.Wait()
		SkipBP = Task.ShouldSkipBreakpoints()
		Task = null
	
	if not Result.Success:
		Log.Error("Failed to execute snippet '" + InSnippet.Name + "'.\n" + Result.GetError().Contents)
		GoToNext = false
	
	emit_signal("OnSnippetEnd", InSnippet)
	
	if Next and GoToNext:
		ExecuteSnippet(Next, false, SkipBP, Result.Results)
	else:
		# All snippets have been executed. The program has finished.
		emit_signal("OnEnd")
	

func Stop() -> void:
	if not Task:
		return
	
	# This notifies any sleeping threads that the VM is executing that it must be terminated.
	Task.Stop()
	
	FinishSnippet(Task.Data, false)
	

func Resume() -> void:
	if not Task:
		return
	
	Task.Resume()
	

func Step() -> void:
	if not Task:
		return
	
	Task.Step()
	

func Compile(InSnippet: SnippetData) -> Reference:
	if not InSnippet:
		return null
	
	return Code.Compile(InSnippet.Source)

func OnBreak(Line: int) -> void:
	emit_signal("OnBreak", Line)
	

func UpdateBreakpoints(Breakpoints: Array) -> void:
	if not Task:
		return
	
	Task.UpdateBreakpoints(Breakpoints)
	

func GetVariables() -> Dictionary:
	if not Task:
		return {}
	
	return Task.GetVariables()

func GetLineBreak() -> int:
	if not Task:
		return -1
	
	return Task.GetLineBreak()

# This is called on the client to simulate emitting signals for the UI to respond.
func ClientSnippetStart(InSnippet: SnippetData) -> void:
	if not InSnippet:
		return
	
	# Create a task object, but don't perform any operations on it.
	if not Task:
		Task = RuntimeTask.new()
	
	if Task.Data == InSnippet:
		return
	
	Task.Data = InSnippet
	emit_signal("OnSnippetStart", InSnippet)
	

func ClientSnippetEnd(InSnippet: SnippetData) -> void:
	if not InSnippet:
		return
	
	if not Task:
		return
	
	if Task.Data != InSnippet:
		return
	
	emit_signal("OnSnippetEnd", InSnippet)
	Task.Data = null
	
