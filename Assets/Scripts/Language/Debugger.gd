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

# class_name Debugger
extends Node

# Singleton object to manage any remote debugging.

enum STATE {
	NONE,
	CONNECTED,
	FINISHED,
	FAILED_TO_CONNECT,
}

enum MESSAGE {
	LOG,
	SNIPPET_START,
	SNIPPET_END,
	BREAK,
	RESUME,
	STEP,
	STOP
}

# Emitted when the state of the debugger changes.
#
# State: STATE
signal OnStateChange(State)

# Port to use for debug communication.
const PORT = 14550

# Timeout the 
const WAIT_FOR_CLIENT_TIMEOUT = 5000

# The listen server for the debugger.
var Server = TCP_Server.new()

# List of connected clients.
var Clients = []

# The client connection to the server.
var Connection = DebuggerClient.new()

# Store the last process ID and kill it if application is exiting.
var ProcessID = 0

# The frame data when the debugger breaks.
var FrameData = {}

# The amount of times to retry the connection to the server. Non-Windows systems
# does not have an initial connection delay and will error out immediately. We will
# just retry up to a number of times before failing completely.
var Retries = 0

func _ready() -> void:
	var _Error = Connection.connect("OnConnected", self, "OnClientConnected")
	_Error = Connection.connect("OnDisconnected", self, "OnClientDisconnected")
	_Error = Connection.connect("OnConnectionError", self, "OnClientConnectionError")
	_Error = Connection.connect("OnDataReceived", self, "OnClientDataReceived")
	

func _process(_delta: float) -> void:
	if Server.is_listening():
		if Server.is_connection_available():
			var Peer: StreamPeerTCP = Server.take_connection()
			Peer.set_no_delay(true)
			Clients.append(Peer)
		
		for Client in Clients:
			if Client.get_available_bytes() > 0:
				OnServerDataReceived(Client.get_string())
	
	Connection.Update()
	

func _exit_tree() -> void:
	if Server.is_listening():
		Server.stop()
	
	Connection.Disconnect()
	
	if ProcessID != 0:
		var _Error = OS.kill(ProcessID)
	

func Launch(Name := "") -> bool:
	Workspace.SaveSnippets()
	
	var EXEPath: String = OS.get_executable_path()
	var Args = []
	if OS.has_feature("editor"):
		var Dir = Directory.new()
		Args = [
			"--path",
			ProjectSettings.globalize_path(Dir.get_current_dir())
		]
	Args.append_array([
		"--no-window",
		"--snippet-run=" + Workspace.Location,
		"--snippet-debug"
	])
	
	if not Name.empty():
		Args.append("--snippet-name=" + Name)
	
	if OS.is_debug_build():
		Args.append("--snippet-log")
	
	if ProcessID != 0:
		var _Error = OS.kill(ProcessID)
	
	ProcessID = OS.execute(EXEPath, Args, false)
	
	if ProcessID == -1:
		Log.Error("Failed to launch debugging process.")
		return false
	
	Log.Clear()
	Log.Info("Launching debug session...")
	
	Retries = 0
	if not Connection.Connect(PORT):
		return false
	
	return true

func RegisterServer() -> void:
	var _Error = Runtime.connect("OnSnippetStart", self, "OnSnippetStart_Server")
	_Error = Runtime.connect("OnSnippetEnd", self, "OnSnippetEnd_Server")
	_Error = Runtime.connect("OnBreak", self, "OnBreak_Server")
	

func Listen() -> bool:
	if Server.is_listening():
		return true
	
	var Error = Server.listen(PORT)
	if Error != OK:
		Log.Error("Failed to listen on port %d. Error code: %d" % [PORT, Error])
		return false
	
	Log.Info("Create debug listen server on port %d." % PORT)
	return true

func WaitForClient() -> bool:
	if not Server.is_listening():
		return false
	
	var Start: int = OS.get_ticks_msec()
	while Clients.size() == 0:
		_process(0.0)
		OS.delay_msec(100)
		
		# Timeout if no connection was received.
		if OS.get_ticks_msec() - Start > WAIT_FOR_CLIENT_TIMEOUT:
			break
	
	if Clients.size() == 0:
		return false
	
	return true

func GeneratePayload(Type: int, Contents: String) -> String:
	return to_json({
		"Type": Type,
		"Contents": Contents
	})

func DispatchToClients(Type: int, Contents: String) -> void:
	if not Server.is_listening():
		return
	
	var Payload: String = GeneratePayload(Type, Contents)
	
	for Client in Clients:
		Client.put_string(Payload)
	

func DispatchToServer(Type: int, Contents: String) -> void:
	if not Connection.is_connected_to_host():
		return
	
	var Payload: String = GeneratePayload(Type, Contents)
	
	Connection.put_string(Payload)
	

func OnClientConnected() -> void:
	emit_signal("OnStateChange", STATE.CONNECTED)
	

func OnClientDisconnected() -> void:
	emit_signal("OnStateChange", STATE.FINISHED)
	

func OnClientConnectionError() -> void:
	# Early failure may have occurred here. Attempt a retry. If max number is
	# reached, emit the signal.
	var Emit = false
	if Connection.IsConnecting() and Retries < 5:
		var Scene: SceneTree = Engine.get_main_loop()
		yield(Scene.create_timer(0.5), "timeout")
		
		Retries += 1
		if not Connection.Connect(PORT):
			Emit = true
	else:
		Emit = true
		
	if Emit:
		Log.Error("Failed to connect to remote debugging host.")
		emit_signal("OnStateChange", STATE.FAILED_TO_CONNECT)
	

func OnServerDataReceived(Data: String) -> void:
	var Payload = parse_json(Data)
	
	if typeof(Payload) != TYPE_DICTIONARY:
		return
	
	var Type: int = Payload["Type"]
	var _Contents: String = Payload["Contents"]
	
	match (Type):
		MESSAGE.RESUME:
			Runtime.Resume()
		MESSAGE.STEP:
			Runtime.Step()
		MESSAGE.STOP:
			Runtime.Stop()
	

func OnClientDataReceived(Data: String) -> void:
	var Payload = parse_json(Data)
	
	if typeof(Payload) != TYPE_DICTIONARY:
		return
	
	var Type: int = Payload["Type"]
	var Contents: String = Payload["Contents"]
	
	match (Type):
		MESSAGE.LOG:
			Log.Info(Contents)
		MESSAGE.SNIPPET_START, MESSAGE.SNIPPET_END:
			var InSnippet: SnippetData = Workspace.GetSnippet(Contents)
			if InSnippet:
				if Type == MESSAGE.SNIPPET_START:
					Runtime.ClientSnippetStart(InSnippet)
				else:
					Runtime.ClientSnippetEnd(InSnippet)
			else:
				Log.Warn("Failed to find snippet '%s'." % Contents)
		MESSAGE.BREAK:
			var Table: Dictionary = parse_json(Contents)
			var Line: int = Table["Line"]
			FrameData = Table["Variables"]
			Runtime.emit_signal("OnBreak", Line)
	

func OnSnippetStart_Server(InSnippet: SnippetData) -> void:
	DispatchToClients(MESSAGE.SNIPPET_START, InSnippet.Name)
	

func OnSnippetEnd_Server(InSnippet: SnippetData) -> void:
	DispatchToClients(MESSAGE.SNIPPET_END, InSnippet.Name)
	

func OnBreak_Server(Line: int) -> void:
	var Variables: Dictionary = Runtime.GetVariables()
	var Payload = {
		"Line": Line,
		"Variables": Variables
	}
	DispatchToClients(MESSAGE.BREAK, to_json(Payload))
	

func Resume() -> void:
	DispatchToServer(MESSAGE.RESUME, "")
	

func Step() -> void:
	DispatchToServer(MESSAGE.STEP, "")
	

func Stop() -> void:
	DispatchToServer(MESSAGE.STOP, "")
	
