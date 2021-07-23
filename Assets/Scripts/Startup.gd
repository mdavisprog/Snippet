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

# This is a bare bones startup scene. This is used to determine if all of the
# UI components should be loaded or if we are running a headless process.

# The processing time to pass to the Runtime.
const FrameTime = 1.0 / 60.0

var LogFile = File.new()

# The main scene to instance to run the application.
export(PackedScene) var MainScene

func _ready() -> void:
	if not MainScene:
		Log.Error("No MainScene specified! Exiting application.")
		get_tree().quit()
	
	var Location = ""
	var SnippetName = ""
	var UseDebugger = false
	var SkipBreakpoints = false
	var Args: PoolStringArray = OS.get_cmdline_args()
	for Arg in Args:
		if Arg.begins_with("--snippet-run="):
			Location = GetValue(Arg)
		elif Arg.begins_with("--snippet-name="):
			SnippetName = GetValue(Arg)
		elif Arg == "--snippet-debug":
			UseDebugger = true
		elif Arg == "--snippet-log":
			CreateLogFile()
		elif Arg == "--snippet-skipbp":
			SkipBreakpoints = true
	
	if not Location.empty():
		if not Run(Location, SnippetName, UseDebugger, SkipBreakpoints):
			Shutdown()
	else:
		# The main UI application starts here.
		var Instance = MainScene.instance()
		add_child(Instance)
	

func Run(Location: String, SnippetName: String, UseDebugger := false, SkipBreakpoints := false) -> bool:
	var _Error = Log.connect("OnLog", self, "OnLog")
	_Error = Runtime.connect("OnEnd", self, "OnRuntimeEnd")
	
	if not Workspace.Open(Location):
		Log.Info("Unable to run snippet at '%s'." % Location)
		return false
	
	if UseDebugger:
		Debugger.RegisterServer()
		
		if not Debugger.Listen():
			Workspace.Close()
			return false
		
		if not Debugger.WaitForClient():
			Log.Info("No clients connected for debugging session.")
			Workspace.Close()
			return false
	
	Log.Info("Running snippets at '%s'." % Location)
	
	var IsUnitTest = not SnippetName.empty()
	if SnippetName.empty():
		SnippetName = "main"
	
	var Data: SnippetData = Workspace.GetSnippet(SnippetName)
	if Data:
		Runtime.ExecuteSnippet(Data, IsUnitTest, SkipBreakpoints)
	else:
		Log.Error("Failed to find snippet '%s'." % SnippetName)
		return false
	
	return true

func GetValue(Arg: String) -> String:
	var Pair: PoolStringArray = Arg.split("=", true, 2)
	return Pair[1]

func OnLog(_Type: int, Contents: String) -> void:
	print(Contents)
	
	if LogFile.is_open():
		LogFile.store_line(Contents)
	
	Debugger.DispatchToClients(Debugger.MESSAGE.LOG, Contents)
	

func CreateLogFile() -> void:
	var LogPath: String = ProjectSettings.get_setting("logging/file_logging/log_path")
	var FileName: String = LogPath.get_base_dir().plus_file("debug_session.txt")
	LogFile.open(FileName, File.WRITE)
	

func OnRuntimeEnd() -> void:
	Shutdown()
	

func Shutdown() -> void:
	Workspace.Close()
	
	if LogFile.is_open():
		LogFile.close()
	
	get_tree().quit(0)
	
