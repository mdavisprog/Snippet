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
	TEMP_MODIFIED
}

# The current state.
var State = STATE.NONE

# The absolute path to the loaded workspace.
var Location = ""

# The active list of snippets in the workspace.
var Snippets = []

func IsLoaded() -> bool:
	return State == STATE.LOADED or State == STATE.TEMP or State == STATE.TEMP_MODIFIED

func IsTempModified() -> bool:
	return State == STATE.TEMP_MODIFIED

func MarkTempDirty() -> void:
	if State == STATE.TEMP:
		State = STATE.TEMP_MODIFIED
	

func GetPath(InLocation: String) -> String:
	return InLocation + "/.snippet/"

func Create(InLocation: String) -> bool:
	Close()
	
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
	AppSettings.Data["LastOpened"] = Location
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
	AppSettings.Data["LastOpened"] = ""
	return true

func Close() -> void:
	if not IsLoaded():
		return
	
	SaveSnippets()
	emit_signal("OnStateChange", STATE.CLOSING)
	Location = ""
	Snippets.clear()
	State = STATE.NONE
	emit_signal("OnStateChange", State)
	

func Open(InLocation: String) -> bool:
	Close()
	
	if not Exists(InLocation):
		return false
	
	Location = InLocation
	AppSettings.Data["LastOpened"] = Location
	State = STATE.LOADED
	LoadSnippets()
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

func CreateSnippet(Name: String) -> SnippetData:
	for Item in Snippets:
		if Item.Name == Name:
			return Item
	
	var Result = SnippetData.new()
	Result.Name = Name
	Snippets.append(Result)
	return Result

func SaveSnippet(Data: SnippetData) -> bool:
	if not IsLoaded():
		return false
	
	if Data.Name.empty():
		return false
	
	var Absolute: String = Location + "/" + Data.Name + ".lua"
	
	var Handle = File.new()
	if Handle.open(Absolute, File.WRITE_READ) != OK:
		return false
	
	Handle.store_string(Data.Source)
	Handle.close()
	
	Absolute = Absolute.trim_suffix(".lua") + ".ut.lua"
	if Handle.open(Absolute, File.WRITE_READ) != OK:
		return false
	
	Handle.store_string(Data.UTSource)
	Handle.close()
	
	if State == STATE.TEMP:
		State = STATE.TEMP_MODIFIED
	
	return true

func DoesSnippetExist(Name: String) -> bool:
	if not IsLoaded():
		return false
	
	for Item in Snippets:
		if Item.Name == Name:
			return true
	
	return false

func GetSnippet(Name: String) -> SnippetData:
	for Item in Snippets:
		if Item.Name == Name:
			return Item
	
	return null

func RenameSnippet(Old: String, New: String) -> bool:
	if not IsLoaded():
		return false
	
	var OldAbsolute: String = Location.plus_file(Old + ".lua")
	var NewAbsolute: String = Location.plus_file(New + ".lua")
	var Dir = Directory.new()
	
	# If the file doesn't exist, no need to attempt a rename.
	if not Dir.file_exists(OldAbsolute):
		return false
	
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

func DeleteSnippet(Name: String) -> bool:
	if not IsLoaded():
		return false
	
	for I in range(0, Snippets.size()):
		var Item: SnippetData = Snippets[I]
		if Item.Name == Name:
			Snippets.remove(I)
			break
	
	var Dir = Directory.new()
	var Result = true
	var FileName: String = Location.plus_file(Name + ".lua")
	if not Dir.file_exists(FileName) or Dir.remove(FileName) != OK: Result = false
	
	FileName = Location.plus_file(Name + ".ut.lua")
	if not Dir.file_exists(FileName) or Dir.remove(FileName) != OK: Result = false
	
	return Result

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

func CopyDirectory(Source: String, Destination: String) -> bool:
	var Dir = Directory.new()
	var Error = Dir.open(Source)
	if Error != OK:
		Log.Error("CopyDirectory: Failed to open source directory '%s' with error code %d." % [Source, Error])
		return false
	
	if not Dir.dir_exists(Destination):
		Error = Dir.make_dir_recursive(Destination)
		if Error != OK:
			Log.Error("CopyDirectory: Failed to create destination '%s' with error code %d." % [Destination, Error])
			return false
	
	Error = Dir.list_dir_begin(true)
	if Error != OK:
		Log.Error("CopyDirectory: Failed to begin iteration process with error code %d." % Error)
		return false
	
	var FileName = Dir.get_next()
	while not FileName.empty():
		var SourceAbs: String = Source.plus_file(FileName)
		var DestAbs: String = Destination.plus_file(FileName)
		if Dir.dir_exists(SourceAbs):
			var _Result = CopyDirectory(SourceAbs, DestAbs)
		else:
			Error = Dir.copy(SourceAbs, DestAbs)
			if Error != OK:
				Log.Error("CopyDirectory: Copy operation to '%s' failed with error code %d." % [DestAbs, Error])
				break
		
		FileName = Dir.get_next()
	
	Dir.list_dir_end()
	return true

func Copy(Source: String, Destination: String) -> bool:
	if not Exists(Source):
		Log.Error("No valid workspace to copy from in source '%s'." % Source)
		return false
	
	if Exists(Destination):
		Log.Error("Failed to copy. Workspace already exists at destination '%s'." % Destination)
		return false
	
	if not CopyDirectory(Source, Destination):
		# Should already have a valid error message printed out. No need to add additional one here.
		return false
	
	return true

func SaveSnippets() -> void:
	var _Result = false
	var PDB = {}
	for Item in Snippets:
		_Result = SaveSnippet(Item)
		
		var Entry = {
			"Next": Item.Next.Name if Item.Next else "",
			"Breakpoints": Item.Breakpoints
		}
		
		PDB[Item.Name] = Entry
	
	_Result = SaveVariant("PDB", PDB)
	

func LoadSnippets() -> void:
	Snippets = GetSnippetData()
	
	var PDB = LoadVariant("PDB")
	if not PDB:
		return
	
	for Item in Snippets:
		if PDB.has(Item.Name):
			Item.Breakpoints = PDB[Item.Name].Breakpoints as PoolIntArray
			
			for Next in Snippets:
				if Next.Name == PDB[Item.Name].Next:
					Item.Next = Next
					break
	

func Startup() -> void:
	var LastOpened = AppSettings.Data.get("LastOpened")
	if LastOpened:
		var _Result = Open(LastOpened)
	
	if not IsLoaded():
		call_deferred("CreateTemp")
	
