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

class_name SnippetWindow
extends FloatingWindow

# Collection of controls that allow for editing the contents of a snippet.

# The snippet associated with this window.
var This: Snippet = null

# The toolbar used for registering signals.
onready var Toolbar: SnippetToolbar = $Panel/VBoxContainer/Margins/Contents/Toolbar

# The text edit control containing the source.
onready var Editor: SnippetTextEdit = $Panel/VBoxContainer/Margins/Contents/Tabs/Snippet

# Base control holding unit test controls.
onready var UTControl: Control = $"Panel/VBoxContainer/Margins/Contents/Tabs/Unit Tests"

# The text that is displayed for running a basic unit test for the given snippet. This is
# read-only.
onready var UTBase: LineEdit = $"Panel/VBoxContainer/Margins/Contents/Tabs/Unit Tests/BaseTest"

# The text edit control for unit tests.
onready var UTEdit: UnitTestTextEdit = $"Panel/VBoxContainer/Margins/Contents/Tabs/Unit Tests/UnitTests"

# Debug window to display the generated Lua code.
onready var Lua: TextEdit = $Panel/VBoxContainer/Margins/Contents/Tabs/Lua

# Container holding the text edit controls.
onready var Editors: TabContainer = $Panel/VBoxContainer/Margins/Contents/Tabs

# Reference to the status bar.
onready var Status: StatusBar = $Panel/VBoxContainer/Margins/Contents/StatusBar

# The virtual machine used to compile and execute the snippet.
onready var Code: VirtualMachine = $Code

# Delay before compiling source to give the user time to finish typing their thoughts.
onready var CompileTimer: Timer = $CompileTimer

# Delay before displaying the auto complete window for the focused edit.
onready var AutoCompleteTimer: Timer = $AutoCompleteTimer

# The auto complete window used to display suggestions to the developer.
onready var AutoCompleteWindow: AutoComplete = $AutoComplete

func _ready() -> void:
	var _Error = Toolbar.connect("OnAction", self, "OnAction")
	_Error = Editor.connect("text_changed", self, "OnSnippetTextChanged")
	_Error = Editors.connect("tab_changed", self, "OnTabChanged")
	_Error = CompileTimer.connect("timeout", self, "OnCompileTimer")
	_Error = AutoCompleteTimer.connect("timeout", self, "OnAutoComplete")
	_Error = AutoCompleteWindow.connect("OnConfirm", self, "OnAutoCompleteConfirm")
	
	Status.text = ""
	

func Show(InSnippet: Snippet) -> void:
	This = InSnippet
	Editor.text = This.Text
	OnSnippetTextChanged()
	
	var Bounds: Rect2 = InSnippet.BackgroundNode.GetBounds(InSnippet.global_position)
	rect_global_position = Vector2(Bounds.end.x, Bounds.position.y)
	rect_size = Vector2(300, 350)
	

func OnAction(Action: int) -> void:
	match (Action):
		SnippetToolbar.ACTION.RUN:
			RunUnitTest()
	

func OnTabChanged(Tab: int) -> void:
	if not Code:
		return
	
	if Editors.get_tab_control(Tab) == UTControl:
		UpdateStatusBar(Code.ExecResult)
	else:
		UpdateStatusBar(Code.CompileResult)
	

func UpdateStatusBar(VMResult) -> void:
	if not VMResult:
		return
	
	var Success: bool = VMResult.Success
	
	var Active: Control = Editors.get_current_tab_control()
	match (Active):
		Editor:
			Status.text = "Success" if Success else "Failed to compile."
		_:
			# Update the text with a proper error message from VMResult if one exists.
			Status.text = "Success" if Success else VMResult.GetMessage()
	
	Status.SetError(not Success)
	

func OnSnippetTextChanged() -> void:
	CompileTimer.start()
	AutoCompleteTimer.start()
	

func OnCompileTimer() -> void:
	if not Code or not Code.VM:
		return
	
	Editor.ClearLineStates()
	Code.Reset()
	var Result: ParserResult = Code.ToLua(Editor.text)
	if not Result.Success:
		return
	
	This.Text = Editor.text
	This.SetTitle(Result.FunctionName)
	
	var CompileResult = Code.Compile(Result.Code)
	Lua.readonly = false
	Lua.text = Result.Code
	Lua.readonly = true
	
	UpdateStatusBar(CompileResult)
	
	Toolbar.Run.disabled = not CompileResult.Success
	
	var Args = PoolStringArray()
	for _I in range(Result.Arguments.size()): Args.append("nil")
	
	UTBase.text = Result.FunctionName + "(" + Args.join(",") + ")"
	
	if not CompileResult.Success:
		Editor.SetLineState(CompileResult.GetLine(), BaseTextEdit.LINE_STATE.ERROR)
	

func RunUnitTest() -> void:
	# Make sure the VM has a clean slate.
	Code.Reset()
	Log.Clear()
	
	# The first thing we need to do is define the function. This is done by executing
	# the main function so it is defined. This should succeed if it passed the
	# compilation phase.
	var Result = Code.Execute(Lua.text)
	if not Result.Success:
		Editors.current_tab = 0
		UpdateStatusBar(Result)
	
	# Focus the unit test edit control.
	Editors.current_tab = 1
	
	# Combine the base unit test with any custom unit test code.
	var Source = UTBase.text + "\n"
	Source += UTEdit.text
	
	Log.Info("Running unit tests for snippet '%s'." % This.GetTitle())
	
	# Now run the unit tests.
	Result = Code.Execute(Source)
	UpdateStatusBar(Result)
	

func OnAutoComplete() -> void:
	var Word: String = Editor.GetWordAtCursor().to_lower()
	if Word.empty():
		AutoCompleteWindow.visible = false
		return
	
	# Grab the keywords for the editor.
	var Keywords: Array = Editor.GetKeywords()
	if Keywords.empty():
		return
	
	var Filtered = Array()
	for I in Keywords:
		if I == Word:
			# The given word already matches a keyword. No need to display auto complete.
			return
		elif I.to_lower().begins_with(Word):
			Filtered.append(I)
	
	# Clear the list and add all possible choices.
	AutoCompleteWindow.List.clear()
	for I in Filtered:
		AutoCompleteWindow.List.add_item(I)
	
	if AutoCompleteWindow.List.get_item_count() == 0:
		return
	
	AutoCompleteWindow.List.select(0)
	
	var Pos: Vector2 = Editor.GetCursorPos()
	AutoCompleteWindow.popup(Rect2(Pos + Editor.rect_global_position, Vector2(175, 75)))
	

func OnAutoCompleteConfirm(Item: String) -> void:
	Editor.SetWordAtCursor(Item)
	
