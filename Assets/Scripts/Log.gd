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

# Singleton utility class to manage logging and allow multiple listeners to
# handle logging requests. This interface is thread-safe except for the Clear function.

class LogItem:
	var Type: int
	var Contents: String
	
	func _init(InType: int, InContents: String) -> void:
		Type = InType
		Contents = InContents
		
	

# OnLog
#
# Type: TYPE
# Contents: String
signal OnLog(Type, Contents)

# Emitted when there is a clear request made to the Log system.
signal OnClear()

# Types of logs that can be dispatched.
enum TYPE {INFO, WARN, ERROR}

# LogItem array to hold entries if they came on a separate thread.
var Items = []

# A mutex to lock write access to the Items array.
var Guard = Mutex.new()

# The main thread ID. Stored at application startup.
var MainThreadID = 0

func _ready() -> void:
	MainThreadID = OS.get_thread_caller_id()
	

func _process(_delta: float) -> void:
	if not Items.empty():
		Guard.lock()
		for Item in Items:
			Internal(Item.Type, Item.Contents)
		Items.clear()
		Guard.unlock()
	

func Info(Contents: String) -> void:
	Internal(TYPE.INFO, Contents)
	

func Warn(Contents: String) -> void:
	Internal(TYPE.WARN, Contents)
	

func Error(Contents: String) -> void:
	Internal(TYPE.ERROR, Contents)
	

func Internal(Type: int, Contents: String) -> void:
	if MainThreadID == OS.get_thread_caller_id():
		emit_signal("OnLog", Type, Contents)
	else:
		Guard.lock()
		Items.append(LogItem.new(Type, Contents))
		Guard.unlock()
	

func Clear() -> void:
	emit_signal("OnClear")
	
