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

class_name MessageBox
extends ConfirmationDialog

# Simple dialog to manage the behavior of message boxes.

# The types of message boxes supported.
enum TYPE {
	OKCANCEL,
	YESNO,
}

# Store a reference to a function that will be invoked upon a response from the
# developer.
var Callback: FuncRef = null

func _ready() -> void:
	var _Error = null
	_Error = connect("confirmed", self, "OnConfirm")
	_Error = get_cancel().connect("pressed", self, "OnCancel")
	

func Show(Title: String, Message: String, InCallback: FuncRef, Type := TYPE.OKCANCEL) -> void:
	window_title = Title
	dialog_text = Message
	Callback = InCallback
	
	# Set to default state
	get_ok().text = "OK"
	get_ok().visible = true
	get_cancel().text = "Cancel"
	get_cancel().visible = true
	
	match (Type):
		TYPE.YESNO:
			get_ok().text = "Yes"
			get_cancel().text = "No"
	
	popup_centered()
	

func OnConfirm() -> void:
	if Callback: Callback.call_func(true)
	

func OnCancel() -> void:
	if Callback: Callback.call_func(false)
	
