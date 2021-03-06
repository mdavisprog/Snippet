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
var This: Snippet = null setget SetSnippet

# The result of a parse that occurs after text has been entered.
var ParseResult: ParserResult = null

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

# Delay before compiling source to give the user time to finish typing their thoughts.
onready var CompileTimer: Timer = $CompileTimer

# Delay before displaying the auto complete window for the focused edit.
onready var AutoCompleteTimer: Timer = $AutoCompleteTimer

# The auto complete window used to display suggestions to the developer.
onready var AutoCompleteWindow: AutoComplete = $AutoComplete

# Control that is visible when the title needs to be edited.
onready var TitleEdit: LineEdit = $Panel/VBoxContainer/TitleContainer/TitleEdit

func _ready() -> void:
	var _Error = Toolbar.connect("OnAction", self, "OnAction")
	_Error = Editor.connect("text_changed", self, "OnSnippetTextChanged")
	_Error = Editor.connect("breakpoint_toggled", self, "OnBreakpointToggled")
	_Error = Editor.connect("OnHoverWord", self, "OnHoverWord")
	_Error = CompileTimer.connect("timeout", self, "OnCompileTimer")
	_Error = AutoCompleteTimer.connect("timeout", self, "OnAutoComplete")
	_Error = AutoCompleteWindow.connect("OnConfirm", self, "OnAutoCompleteConfirm")
	_Error = Title.connect("gui_input", self, "OnTitleGuiInput")
	_Error = TitleEdit.connect("text_entered", self, "OnTitleEditChanged")
	_Error = TitleEdit.connect("focus_exited", self, "OnTitleEditUnfocus")
	_Error = Runtime.connect("OnStart", self, "OnRuntimeStart")
	_Error = Runtime.connect("OnBreak", self, "OnRuntimeBreak")
	_Error = Runtime.connect("OnEnd", self, "OnRuntimeEnd")
	_Error = Debugger.connect("OnStateChange", self, "OnDebuggerStateChange")
	
	Status.text = ""
	Editor.HoverWordTimer.paused = true
	
	ToggleRunButtons(false)
	
	add_to_group("SnippetWindows")
	

func Show(InSnippet: Snippet) -> void:
	SetSnippet(InSnippet)
	Editor.text = This.Data.Source
	UTEdit.text = This.Data.UTSource
	Title.text = This.Data.Name
	
	if not Runtime.IsRunning():
		PrimeTimers()
	else:
		OnRuntimeStart()
		if Runtime.IsPaused():
			OnRuntimeBreak(Runtime.GetLineBreak())
	
	var Bounds: Rect2 = InSnippet.BackgroundNode.GetBounds(InSnippet.global_position)
	rect_global_position = Vector2(Bounds.end.x, Bounds.position.y)
	rect_size = Vector2(300, 350)
	
	Editor.remove_breakpoints()
	for Line in This.Data.Breakpoints:
		Editor.set_line_as_breakpoint(Line, true)
	

func OnAction(Action: int) -> void:
	var Launched = false
	match (Action):
		SnippetToolbar.ACTION.RUN:
			Launched = Debugger.Launch()
		SnippetToolbar.ACTION.RUNUT, SnippetToolbar.ACTION.RESUME:
			if Runtime.IsRunning():
				if Action == SnippetToolbar.ACTION.RUNUT:
					Debugger.Step()
				else:
					Debugger.Resume()
				Toolbar.SetResume(false)
				Editor.ClearLineStates()
				Editor.HoverWordTimer.paused = true
			else:
				Launched = Debugger.Launch(This.Data.Name)
		SnippetToolbar.ACTION.STOP:
			Debugger.Stop()
			Editor.ClearLineStates()
	
	if Launched:
		OnRuntimeStart()
	

func UpdateStatusBar(Success: bool, Error: String) -> void:
	Status.text = "Success" if Success else Error
	Status.SetError(not Success)
	

func OnSnippetTextChanged() -> void:
	PrimeTimers()
	Workspace.MarkTempDirty()
	

func PrimeTimers() -> void:
	ToggleRunButtons(false)
	CompileTimer.start()
	AutoCompleteTimer.start()
	

func OnCompileTimer() -> void:
	Editor.ClearLineStates()
	
	var Source: String = Editor.text
	This.Data.Source = Source
	
	var CompileResult = Runtime.Compile(This.Data)
	Lua.readonly = false
	Lua.text = Source
	Lua.readonly = true
	
	SetError(CompileResult)
	ToggleRunButtons(CompileResult.Success and not Runtime.IsRunning())
	UTBase.text = This.GetTitle() + "()"
	

func RunUnitTest() -> void:
	Log.Clear()
	
	var FnName: String = This.GetTitle()
	Log.Info("Running unit tests for snippet '%s'." % FnName)
	
	# First, run the base unit test and ensure no invalid operations occur.
	# TODO: Pass in parsed arguments results. This will require a cached ParserResult
	# object that was generated after text has been entered.
	Runtime.ExecuteSnippet(This.Data, true)
	OnRuntimeStart()
	
	# TODO: Custom unit test code should just do a raw execute. It is up to
	# the developer on how this unit test behaves and should assert if there is
	# an error.
	# var Source += UTEdit.text
	

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
		AutoCompleteWindow.visible = false
		return
	
	AutoCompleteWindow.List.select(0)
	
	var Pos: Vector2 = Editor.GetCursorPos()
	AutoCompleteWindow.popup(Rect2(Pos + Editor.rect_global_position, Vector2(175, 75)))
	

func OnAutoCompleteConfirm(Item: String) -> void:
	Editor.SetWordAtCursor(Item)
	

func ToggleRunButtons(Enabled: bool) -> void:
	Toolbar.Run.disabled = not Enabled
	Toolbar.RunUT.disabled = not Enabled
	

func OnTitleGuiInput(event: InputEvent) -> void:
	if Runtime.IsRunning():
		return
	
	var MouseButton = event as InputEventMouseButton
	if MouseButton:
		if MouseButton.doubleclick and MouseButton.button_index == BUTTON_LEFT:
			EditTitle()
			# Calling set_input_as_handled did not seem to work and will need more
			# investigation. For now, just defer the call to ensure the window is not moved.
			call_deferred("CancelOp")
	

func SetTitle(InTitle: String) -> void:
	Title.text = InTitle
	

func EditTitle() -> void:
	var SnippetGraphNode: SnippetGraph = get_node_or_null(Utility.GRAPH)
	if SnippetGraphNode.MainSnippet == This:
		return
	
	Title.visible = false
	TitleEdit.visible = true
	TitleEdit.text = Title.text
	TitleEdit.select_all()
	TitleEdit.grab_focus()
	

func OnTitleEditChanged(Text: String) -> void:
	var Old = This.Data.Name
	if Workspace.DoesSnippetExist(Text):
		if Old != Text:
			UpdateStatusBar(false, "Snippet '%s' already exists." % Text)
		else:
			# The name didn't change. No need to continue.
			OnTitleEditUnfocus()
		return
	
	OnTitleEditUnfocus()
	
	# If no name has been set yet, then clear the status bar in case there was an error.
	if This.Data.Name.empty():
		UpdateStatusBar(true, "")
	
	This.Data.Name = Text
	This.SetTitle(Text)
	Title.text = Text
	
	if not Workspace.RenameSnippet(Old, Text):
		var _Result = This.Save()
	

func OnTitleEditUnfocus() -> void:
	Title.visible = true
	TitleEdit.visible = false
	

func OnTitleResized() -> void:
	rect_min_size.x = Title.rect_size.x + 25
	rect_min_size.y = (Editor.rect_global_position.y - rect_global_position.y) * 2
	

func SetError(Result: Reference, PrintContents := false) -> void:
	if not Result:
		return
	
	var Message = ""
	if not Result.Success:
		var Error = Result.GetError()
		var Top = Error.GetTop()
		
		if PrintContents:
			Log.Error("\n" + Error.Contents)
		
		if Top:
			Message = Top.Message
			Editor.SetLineState(Top.Line, BaseTextEdit.LINE_STATE.ERROR)
	
	UpdateStatusBar(Result.Success, Message)
	

func SetSnippet(Value: Snippet) -> void:
	This = Value
	if This:
		var _Error = This.connect("tree_exited", self, "OnSnippetExit")
	

func OnSnippetExit() -> void:
	queue_free()
	

func OnRuntimeStart() -> void:
	ToggleRunButtons(false)
	Editor.readonly = true
	Toolbar.Stop.disabled = false
	

func OnRuntimeBreak(Line: int) -> void:
	Toolbar.Stop.disabled = false
	Toolbar.SetResume(true)
	if Runtime.IsActiveSnippet(This.Data):
		Editor.SetLineState(Line + 1, BaseTextEdit.LINE_STATE.ERROR)
		Editor.HoverWordTimer.stop()
		Editor.HoverWordTimer.paused = false
	

func OnRuntimeEnd() -> void:
	ToggleRunButtons(true)
	Editor.readonly = false
	Toolbar.Stop.disabled = true
	

func OnBreakpointToggled(_Row: int) -> void:
	This.Data.Breakpoints = Editor.get_breakpoints()
	Runtime.UpdateBreakpoints(This.Data.Breakpoints)
	

func OnHoverWord(Word: String) -> void:
	var Variables: Dictionary = Debugger.FrameData
	if not Variables.has(Word):
		return
	
	var PopupsNode = get_node(Utility.POPUPS)
	var Offset: Vector2 = PopupsNode.VarInspector.rect_size
	PopupsNode.VarInspector.visible = true
	PopupsNode.VarInspector.rect_global_position = get_global_mouse_position() + Vector2(0.0, -Offset.y)
	PopupsNode.VarInspector.Data.text = Word + ":" + str(Variables[Word])
	PopupsNode.VarInspector.update()
	

func OnClosePressed() -> void:
	if This.Data.Name.empty():
		This.Destroy()
	
	.OnClosePressed()
	

func OnDebuggerStateChange(State: int) -> void:
	match (State):
		Debugger.STATE.FINISHED, Debugger.STATE.FAILED_TO_CONNECT:
			OnRuntimeEnd()
	
