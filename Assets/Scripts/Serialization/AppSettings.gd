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

# Singleton object that allows any object to set/get settings needed between
# application runs.

# The location of the file.
const LOCATION = "user://appsettings.cfg"

# The dictionary used to store all settings. This is serialized to disk at application exit.
var Data = {}

func _init() -> void:
	var _Result = Load()
	

func _exit_tree() -> void:
	var _Result = Save()
	

func Save() -> bool:
	var Handle = File.new()
	var Error = Handle.open(LOCATION, File.WRITE)
	if Error != OK:
		Log.Error("Failed to save app settings file at location '%s' with error code %d." % [LOCATION, Error])
		return false
	
	Handle.store_string(to_json(Data))
	Handle.close()
	return true

func Load() -> bool:
	var Handle = File.new()
	var Error = Handle.open(LOCATION, File.READ)
	if Error != OK:
		if Error != ERR_DOES_NOT_EXIST:
			Log.Error("Failed to load app settings file at location '%s' with error code %d." % [LOCATION, Error])
		return false
	
	Data = parse_json(Handle.get_as_text())
	Handle.close()
	return true
