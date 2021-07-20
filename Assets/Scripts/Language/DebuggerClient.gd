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

class_name DebuggerClient
extends StreamPeerTCP

# TCP client socket used to communicate to a DebuggerServer socket. Put into its
# class track state and emit signals.

enum STATE {
	DISCONNECTED,
	CONNECTING,
	CONNECTED
}

# Emitted when the client has successfully connected to the server.
signal OnConnected()

# Emitted when the client has been disconnected from the server by the server.
signal OnDisconnected()

# Emitted when a connection attempt to a server has failed.
signal OnConnectionError()

# Emitted when data is received from the server.
#
# Data: String
signal OnDataReceived(Data)

# The current state of the connection. This is used to emit some signals.
var State = STATE.DISCONNECTED

func Connect(Port: int) -> bool:
	if get_status() == STATUS_CONNECTED:
		return true
	
	if connect_to_host("localhost", Port) != OK:
		Log.Error("Failed to initiate connection to remote debugging host.")
		return false
	
	State = STATE.CONNECTING
	return true

func Disconnect() -> void:
	if is_connected_to_host():
		disconnect_from_host()
	

func Update() -> void:
	if get_status() == STATUS_ERROR:
		Log.Error("Failed to connect to remote debugging host.")
		emit_signal("OnConnectionError")
		disconnect_from_host()
	
	if get_status() == STATUS_CONNECTED:
		if State == STATE.CONNECTING:
			set_no_delay(true)
			State = STATE.CONNECTED
			emit_signal("OnConnected")
		
		if get_available_bytes() > 0:
			emit_signal("OnDataReceived", get_string())
	
	if State == STATE.CONNECTED and get_status() == STATUS_NONE:
		State = STATE.DISCONNECTED
		emit_signal("OnDisconnected")
	
