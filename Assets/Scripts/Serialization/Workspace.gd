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

# Manages the loading and saving of a workspace.

# Emitted when the state of the workspace has changed.
#
# NewState: STATE
signal OnStateChange(NewState)

# List of states a workspace can be in.
enum STATE {
	NONE,
	LOADED,
}

# The current state.
var State = STATE.NONE

# The absolute path to the loaded workspace.
var Location = ""

func IsLoaded() -> bool:
	return State == STATE.LOADED

func GetPath(InLocation: String) -> String:
	return InLocation + "/.snippet/"

func Create(InLocation: String) -> bool:
	# The path already exists. Return that it is has already been created.
	if Exists(InLocation):
		Location = InLocation
		return true
	
	var Dir = Directory.new()
	var Absolute = GetPath(InLocation)
	
	if Dir.make_dir(Absolute) != OK:
		return false
	
	Location = Absolute
	State = STATE.LOADED
	emit_signal("OnStateChange", State)
	return true

func Exists(InLocation: String) -> bool:
	var Absolute = GetPath(InLocation)
	var Dir = Directory.new()
	return Dir.dir_exists(Absolute)
