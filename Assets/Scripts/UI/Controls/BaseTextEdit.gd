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

class_name BaseTextEdit
extends TextEdit

# List of states a line can be in.
enum LINE_STATE {WARNING, ERROR}

const LINE_STATE_COLORS = {
	LINE_STATE.WARNING: Color("#66dfe629"),
	LINE_STATE.ERROR: Color("#66762929")
}

# The SyntaxColor resource to instance for setting the colors for highlighting.
# This will be an array to allow multiple colors to be defined.
export(Array, Resource) var SyntaxColors

# List of keywords to look for in the previous line to determine if indentation
# is required.
export(Array, String) var IndentKeywords

# Dictionary of lines and it's state.
var Lines = {}

# Appends a tab after the 'text_changed' signal is emitted. This is determined
# by IndentKeywords.
var AppendTab = false

func _ready() -> void:
	var _Error = connect("text_changed", self, "OnTextChanged")
	
	clear_colors()
	for Item in SyntaxColors:
		for Keyword in Item.Keywords:
			add_keyword_color(Keyword, Item.Highlight)
	

func _gui_input(event: InputEvent) -> void:
	var Key = event as InputEventKey
	if Key:
		if Key.pressed:
			if Key.scancode == KEY_ENTER:
				var Line: String = get_line(cursor_get_line())
				for I in IndentKeywords:
					if Line.find(I) != -1:
						AppendTab = true
						break
	

func _draw() -> void:
	var LineSize = Vector2(rect_size.x, GetLineHeight())
	
	for Key in Lines:
		var State = Lines[Key]
		var Line = max(Key - 1, 0)
		var Position = Vector2(0.0, LineSize.y * Line + GetLineSpacing())
		draw_rect(Rect2(Position, LineSize), LINE_STATE_COLORS[State])
	

func SetLineState(Line: int, State := LINE_STATE.WARNING) -> void:
	Lines[Line] = State
	update()
	

func ClearLineStates() -> void:
	Lines = {}
	update()
	

func Select(Text: String) -> void:
	var Result: PoolIntArray = search(Text, SEARCH_WHOLE_WORDS, 0, 0)
	if not Result.empty():
		var Line = Result[SEARCH_RESULT_LINE]
		var Column = Result[SEARCH_RESULT_COLUMN]
		var End = Column + Text.length()
		select(Line, Column, Line, End)
		cursor_set_column(End)
		grab_focus()
	

func GetLineSpacing() -> float:
	return get_constant("line_spacing") as float

func GetLineHeight() -> float:
	var ThemeFont: Font = get_font("font")
	if not ThemeFont:
		return 0.0
	
	return ThemeFont.get_height() + GetLineSpacing()

func GetWordAtCursorStart() -> int:
	var Result: PoolIntArray = search(" ", SEARCH_BACKWARDS, cursor_get_line(), cursor_get_column())
	if not Result:
		return 0
	
	var Line: int = Result[SEARCH_RESULT_LINE]
	var Col: int = Result[SEARCH_RESULT_COLUMN]
	
	if Line != cursor_get_line():
		# Did not find a space. Check for tab.
		Result = search("\t", SEARCH_BACKWARDS, cursor_get_line(), cursor_get_column())
		if not Result:
			return 0
		
		Line = Result[SEARCH_RESULT_LINE]
		Col = Result[SEARCH_RESULT_COLUMN]
		
		if Line != cursor_get_line():
			return cursor_get_column()
	
	return Col + 1

func GetWordAtCursor() -> String:
	var Line: int = cursor_get_line()
	var Column: int = GetWordAtCursorStart()
	
	select(Line, Column, Line, cursor_get_column())
	var Result: String = get_selection_text()
	deselect()
	return Result

func SetWordAtCursor(Word: String) -> void:
	var Line: int = cursor_get_line()
	var Column: int = GetWordAtCursorStart()
	
	select(Line, Column, Line, cursor_get_column())
	insert_text_at_cursor(Word)
	

func GetKeywords() -> Array:
	var Result = Array()
	
	for Item in SyntaxColors:
		Result.append_array(Item.Keywords)
	
	return Result

func GetCursorPos() -> Vector2:
	var Result = Vector2.ZERO
	
	Result.y = (cursor_get_line() - int(scroll_vertical)) * GetLineHeight()
	
	var Line: String = get_line(cursor_get_line())
	var Text: String = Line.substr(0, cursor_get_column())
	var ThemeFont: Font = get_font("font")
	
	# This is close enough. Might have issues with tabs/spaces/other non standard characters.
	var Size: Vector2 = ThemeFont.get_string_size(Text)
	Result.x = Size.x + GetLineNumberOffset() + GetBreakpointOffset() + 16.0
	
	return Result

func GetLineNumberOffset() -> float:
	# The code below was taken from text_edit.cpp::_notification. This is the offset
	# from the left margin if the 'show_line_numbers' flag is set to true.
	
	var Result = 0.0
	if not show_line_numbers:
		return Result
	
	var ThemeFont: Font = get_font("font")
	if not ThemeFont:
		return Result
	
	var Width = 0
	var Count: int = get_line_count()
	while (Count):
		Width += 1
		Count /= 10
	
	Result = (Width + 1) * ThemeFont.get_string_size("0").x
	
	return Result

func OnTextChanged() -> void:
	if AppendTab:
		insert_text_at_cursor("\t")
		AppendTab = false
	

func GetBreakpointOffset() -> float:
	if not breakpoint_gutter:
		return 0.0
	
	# Taken from text_edit.cpp::_notification
	return GetLineHeight() * 55 / 100
