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

class_name VirtualMachine
extends Node

# Object to compile and execute code.

# The type of virtual machine to instance.
export(NativeScript) var VMClass: NativeScript

# Buffer holding any output received from the language vm.
var Buffer = ""

# For now, only a single VM instance can be used.
var ActiveVM = null

# Mutex lock used to access various properties.
var Guard = Mutex.new()

func DispatchBuffer() -> void:
	if Buffer.empty():
		return
	
	Guard.lock()
	Log.Info(Buffer)
	Buffer = ""
	Guard.unlock()
	

func ToLua(Code: String) -> ParserResult:
	var Parse = Parser.new()
	var Result: ParserResult = Parse.Begin(Code)
	return Result
	

func Compile(Code: String) -> Reference:
	if not VMClass:
		return null
	
	# TODO: Should thread compilation as well. No Lua states should be created on
	# the main thread.
	var VM = VMClass.new()
	var _Error = VM.connect("OnPrint", self, "OnPrint")
	var Result = VM.Compile(Code)
	VM.disconnect("OnPrint", self, "OnPrint")
	return Result

func Execute(Code: String, Name: String, Args: Array, Breakpoints: Array) -> Reference:
	if not VMClass:
		return null
	
	var VM = VMClass.new()
	VM.AttachDebugger()
	VM.GetDebugger().SetBreakpoints(Breakpoints)
	var _Error = VM.connect("OnPrint", self, "OnPrint")
	
	Guard.lock()
	ActiveVM = VM
	VM.PushArguments(Args)
	Guard.unlock()
	
	var Result = VM.Execute(Code, Name)
	VM.disconnect("OnPrint", self, "OnPrint")
	
	Guard.lock()
	ActiveVM = null
	Guard.unlock()
	
	return Result

func OnPrint(Contents: String) -> void:
	Guard.lock()
	Buffer += Contents + "\n"
	Guard.unlock()
	

func Stop() -> void:
	if not ActiveVM:
		return
	
	ActiveVM.Stop()
	

func Resume() -> void:
	if not ActiveVM:
		return
	
	if State != STATE.PAUSED:
		return
	
	Guard.lock()
	ActiveVM.Resume()
	State = STATE.RUNNING
	Guard.unlock()
	

func UpdateBreakpoints(Breakpoints: Array) -> void:
	if not ActiveVM:
		return
	
	# May not need to guard this operation as breakpoints are read-only on execution thread.
	ActiveVM.GetDebugger().SetBreakpoints(Breakpoints)
	
