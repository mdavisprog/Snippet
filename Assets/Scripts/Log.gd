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
# handle logging requests.

# OnLog
#
# Type: TYPE
# Contents: String
signal OnLog(Type, Contents)

# Emitted when there is a clear request made to the Log system.
signal OnClear()

# Types of logs that can be dispatched.
enum TYPE {INFO, WARN, ERROR}

func Info(Contents: String) -> void:
	emit_signal("OnLog", TYPE.INFO, Contents)
	

func Warn(Contents: String) -> void:
	emit_signal("OnLog", TYPE.WARN, Contents)
	

func Error(Contents: String) -> void:
	emit_signal("OnLog", TYPE.ERROR, Contents)
	

func Clear() -> void:
	emit_signal("OnClear")
	
