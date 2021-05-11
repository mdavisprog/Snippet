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

# The VM instance that is created from VMClass if valid.
var VM = null

# The result of the last compile. Should be a LuaVM reference.
var CompileResult: Reference = null

# The result of the last execution. Should be a LuaVM reference.
var ExecResult: Reference = null

func _ready() -> void:
	var _Error = null
	if VMClass:
		if not VM:
			VM = VMClass.new()
			_Error = VM.connect("OnPrint", self, "OnPrint")
	

func Reset() -> void:
	if VM:
		VM.Reset()
	

func ToLua(Code: String) -> ParserResult:
	var Parse = Parser.new()
	var Result: ParserResult = Parse.Begin(Code)
	return Result
	

func Compile(Code: String) -> Reference:
	if VM:
		CompileResult = VM.Compile(Code)
	else:
		CompileResult.Success = false
	
	return CompileResult

func Execute(Code: String) -> Reference:
	if VM:
		ExecResult = VM.Execute(Code)
	else:
		ExecResult.Success = false
	
	return ExecResult

func OnPrint(Contents: String) -> void:
	Log.Info(Contents)
	
