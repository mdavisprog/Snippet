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

class_name RuntimeTask
extends Reference

# A task represents a threaded action taken on a Snippet. The Runtime will manage
# these objects and emit the appropriate signal when complete.

# Emitted when a line break occurs.
#
# Line: int
signal OnBreak(Line)

enum STATUS {
	IDLE,
	RUNNING,
	BREAK,
	PAUSED,
	COMPLETE
}

# Snippet this task is associated with.
var Data: SnippetData = null

# Additional arguments used to execute this task.
var Arguments = {}

# The virtual machine used to perform the task.
var VM = null

# The virtual machine type to instance. This should be done on the thread.
var VMClass: NativeScript = null

# The current status of this task.
var Status = STATUS.IDLE

# The threading object. Unable to inherit from this class.
var Task = Thread.new()

# The result variable stored after execution is complete.
var Result = null

# This should be called by the Runtime object on the main thread.
func _process(_delta: float) -> void:
	if Status == STATUS.BREAK:
		emit_signal("OnBreak", VM.GetDebugger().GetLineBreak())
		Status = STATUS.PAUSED
	

func Init(InVMClass: NativeScript) -> void:
	VMClass = InVMClass
	

func Execute(InData: SnippetData, InArguments := {}) -> bool:
	Data = InData
	Arguments = InArguments
	
	if Task.start(self, "Execute_Thread", Arguments) != OK:
		return false
	
	return true

# The return value for this function will be returned to the calling object through
# the wait_to_finish() function.
func Execute_Thread(_InArguments: Dictionary):
	var Breakpoints = [] if ShouldSkipBreakpoints() else Data.Breakpoints
	var Params = [] if not Arguments.has("params") else Arguments["params"]
	
	VM = VMClass.new()
	VM.PushArguments(Params)
	
	VM.AttachDebugger()
	VM.GetDebugger().SetBreakpoints(Breakpoints)
	
	var _Error = VM.connect("OnPrint", self, "OnPrint")
	_Error = VM.GetDebugger().connect("OnBreak", self, "OnBreak")
	
	Status = STATUS.RUNNING
	Result = OnExecute();
	Status = STATUS.COMPLETE
	
	VM = null
	
	return Result

# This function should be overridden in sub-classes and return an object.
func OnExecute():
	pass
	

func Wait():
	if not Task.is_active():
		return null
	
	return Task.wait_to_finish()

func Stop() -> void:
	if not VM:
		return
	
	VM.Stop()

func Resume() -> void:
	if not VM:
		return
	
	if not IsPaused():
		return
	
	VM.Resume()
	

func Step() -> void:
	if not VM:
		return
	
	if not IsPaused():
		return
	
	VM.Step()
	Status = STATUS.RUNNING
	

func IsComplete() -> bool:
	return Status == STATUS.COMPLETE

func IsPaused() -> bool:
	return Status == STATUS.BREAK or Status == STATUS.PAUSED

func UpdateBreakpoints(Breakpoints: Array) -> void:
	if not VM:
		return
	
	# May not need to guard this operation as breakpoints are read-only on execution thread.
	VM.GetDebugger().SetBreakpoints(Breakpoints)
	

func ShouldSkipBreakpoints() -> bool:
	if Arguments.has("skipbp"):
		return Arguments["skipbp"]
	
	return false

func GetVariables() -> Dictionary:
	if not VM:
		return {}
	
	return VM.GetDebugger().GetVariables()

func GetLineBreak() -> int:
	if not VM:
		return -1
	
	if not VM.GetDebugger():
		return -1
	
	return VM.GetDebugger().GetLineBreak()

func OnPrint(Contents: String) -> void:
	Log.Info(Contents)
	

func OnBreak(_Line: int) -> void:
	Status = STATUS.BREAK
	

func IsUnitTest() -> bool:
	return false
