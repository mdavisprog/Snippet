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

# The directory containing temporary data files for empty workspaces.
const TEMP_DIR = "Temp"

# Emitted when the state of the workspace has changed.
#
# NewState: STATE
signal OnStateChange(NewState)

# List of states a workspace can be in.
enum STATE {
	NONE,
	CLOSING,
	LOADED,
	TEMP,
}

# The current state.
var State = STATE.NONE

# The absolute path to the loaded workspace.
var Location = ""

func _notification(what: int) -> void:
	match (what):
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			Close()
	

func IsLoaded() -> bool:
	return State == STATE.LOADED or State == STATE.TEMP

func GetPath(InLocation: String) -> String:
	return InLocation + "/.snippet/"

func Create(InLocation: String) -> bool:
	# The path already exists. Unable to create a new workspace at the given location.
	if Exists(InLocation):
		return false
	
	var Dir = Directory.new()
	var Absolute = GetPath(InLocation)
	
	var Error = Dir.make_dir_recursive(Absolute)
	if Error != OK:
		Log.Error("Failed to create workspace at '%s' with error code %d." % [Absolute, Error])
		return false
	
	Location = InLocation
	State = STATE.LOADED
	emit_signal("OnStateChange", State)
	return true

func CreateTemp() -> bool:
	var TempLocation = "user://".plus_file(TEMP_DIR)
	var _Result = false
	
	if Exists(TempLocation):
		_Result = Delete(TempLocation)
	
	if not Create(TempLocation):
		return false
	
	State = STATE.TEMP
	return true

func Close() -> void:
	if not IsLoaded():
		return
	
	emit_signal("OnStateChange", STATE.CLOSING)
	Location = ""
	State = STATE.NONE
	emit_signal("OnStateChange", State)
	

func Open(InLocation: String) -> bool:
	Close()
	
	if not Exists(InLocation):
		return false
	
	Location = InLocation
	AppSettings.Data["LastOpened"] = Location
	State = STATE.LOADED
	emit_signal("OnStateChange", State)
	return true

func Exists(InLocation: String) -> bool:
	var Absolute = GetPath(InLocation)
	var Dir = Directory.new()
	return Dir.dir_exists(Absolute)

func DeleteDirectory(Root: String, DeleteRoot: bool) -> bool:
	var Dir = Directory.new()
	if Dir.open(Root) != OK:
		return false
	
	var Error = Dir.list_dir_begin(true)
	if Error != OK:
		return false
	
	var FileName: String = Dir.get_next()
	while not FileName.empty():
		var Absolute: String = Root.plus_file(FileName)
		
		if Dir.dir_exists(Absolute):
			var _Result = DeleteDirectory(Absolute, true)
		
		Error = Dir.remove(Absolute)
		FileName = Dir.get_next()
	
	if DeleteRoot:
		Error = Dir.remove(Root)
	
	return true

func Delete(InLocation: String) -> bool:
	if not Exists(InLocation):
		return false
	
	if not DeleteDirectory(InLocation, false):
		return false
	
	return true

func SaveSnippet(Name: String, Source: String, UTSource: String) -> bool:
	if not IsLoaded():
		return false
	
	var Absolute: String = Location + "/" + Name + ".lua"
	
	var Handle = File.new()
	if Handle.open(Absolute, File.WRITE_READ) != OK:
		return false
	
	Handle.store_string(Source)
	Handle.close()
	
	Absolute = Absolute.trim_suffix(".lua") + ".ut.lua"
	if Handle.open(Absolute, File.WRITE_READ) != OK:
		return false
	
	Handle.store_string(UTSource)
	Handle.close()
	return true

func DoesSnippetExist(Name: String) -> bool:
	if not IsLoaded():
		return false
	
	var Absolute: String = Location.plus_file(Name + ".lua")
	var Handle = File.new()
	return Handle.file_exists(Absolute)

func RenameSnippet(Old: String, New: String) -> bool:
	if not IsLoaded():
		return false
	
	var OldAbsolute: String = Location.plus_file(Old + ".lua")
	var NewAbsolute: String = Location.plus_file(New + ".lua")
	var Dir = Directory.new()
	
	var Error = Dir.rename(OldAbsolute, NewAbsolute)
	if Error != OK:
		Log.Error("Failed to rename snippet from '%s' to '%s' with error code '%d'." % [Old, New, Error])
		return false
	
	OldAbsolute = Location.plus_file(Old + ".ut.lua")
	NewAbsolute = Location.plus_file(New + ".ut.lua")
	
	Error = Dir.rename(OldAbsolute, NewAbsolute)
	if Error != OK:
		Log.Error("Failed to rename snippet unit tests from '%s' to '%s' with error code '%d'." % [Old, New, Error])
		return false
	
	return true

func GetSnippetData() -> Array:
	var Result = Array()
	
	if not IsLoaded():
		return Result
	
	var Dir = Directory.new()
	var Error = Dir.open(Location)
	if Error != OK:
		Log.Error("Failed to open directory '%s' with error code '%d'." % [Location, Error])
		return Result
	
	Error = Dir.list_dir_begin(true, true)
	if Error != OK:
		Log.Error("Failed to iterate contents of directory '%s' with error code '%d'." % [Location, Error])
		return Result
	
	var FileName: String = Dir.get_next()
	while not FileName.empty():
		var Absolute: String = Location.plus_file(FileName)
		if Dir.file_exists(Absolute) and not Absolute.ends_with("ut.lua"):
			var Item = SnippetData.new()
			Item.Name = FileName.get_basename()
			
			var Handle = File.new()
			Error = Handle.open(Absolute, File.READ)
			if Error == OK:
				Item.Source = Handle.get_as_text()
				Handle.close()
				
				var UTAbsolute = Absolute.replace(".lua", ".ut.lua")
				Error = Handle.open(UTAbsolute, File.READ)
				if Error == OK:
					Item.UTSource = Handle.get_as_text()
					Handle.close()
				else:
					Log.Info("Failed to open file '%s' with error code '%d'." % [UTAbsolute, Error])
				
				Result.append(Item)
			else:
				Log.Warn("Failed to open file '%s' with error code '%d'." % [Absolute, Error])
			
		FileName = Dir.get_next()
	
	return Result

func SaveVariant(FileName: String, Variant) -> bool:
	if not IsLoaded():
		return false
	
	var Absolute: String = GetPath(Location).plus_file(FileName)
	var Handle = File.new()
	var Error = Handle.open(Absolute, File.WRITE)
	if Error != OK:
		Log.Error("Failed to create file '%s' with error code '%d'." % [Absolute, Error])
		return false
	
	Handle.store_string(to_json(Variant))
	Handle.close()
	return true

func LoadVariant(FileName: String):
	var Result = null
	
	if not IsLoaded():
		return Result
	
	var Absolute: String = GetPath(Location).plus_file(FileName)
	var Handle = File.new()
	var Error = Handle.open(Absolute, File.READ)
	if Error != OK:
		if Error != ERR_FILE_NOT_FOUND:
			Log.Error("Failed to open file '%s' with error code '%d'." % [Absolute, Error])
		return Result
	
	Result = parse_json(Handle.get_as_text())
	Handle.close()
	
	return Result
