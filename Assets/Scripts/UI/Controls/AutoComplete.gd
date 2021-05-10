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

class_name AutoComplete
extends PopupDialog

# Popup that is displayed to aid the developer in completing typed text.

# Emitted when the developer has selected an item.
#
# Item: String
signal OnConfirm(Item)

enum ACTION {
	NONE,
	NAV_UP,
	NAV_DOWN,
	CONFIRM,
	CANCEL
}

# ItemList reference for quick access.
onready var List: ItemList = $ScrollContainer/ItemList

func _ready() -> void:
	var _Error = List.connect("item_selected", self, "OnItemSelected")
	

func _input(event: InputEvent) -> void:
	# Prevent handling any input when not visible.
	if not visible:
		return
	
	# Prevent overriding input if the ItemList control is focused.
	if get_focus_owner() == List:
		return
	
	var Action = ACTION.NONE
	
	var Key = event as InputEventKey
	if Key:
		if Key.pressed:
			match (Key.scancode):
				KEY_UP: Action = ACTION.NAV_UP
				KEY_DOWN: Action = ACTION.NAV_DOWN
				KEY_TAB: Action = ACTION.CONFIRM
				KEY_ENTER: Action = ACTION.CONFIRM
				KEY_ESCAPE: Action = ACTION.CANCEL
	
	if Action == ACTION.NONE:
		return
	
	var Index = 0
	var Selected: PoolIntArray = List.get_selected_items()
	if Selected and Selected.size() > 0:
		Index = Selected[0]
	
	if Action == ACTION.NAV_UP or Action == ACTION.NAV_DOWN:
		List.unselect_all()
		Index += 1 if Action == ACTION.NAV_DOWN else -1
		Index = clamp(Index, 0, List.get_item_count() - 1)
		
		List.select(Index)
	elif Action == ACTION.CONFIRM:
		visible = false
		emit_signal("OnConfirm", List.get_item_text(Index))
	elif Action == ACTION.CANCEL:
		visible = false
	
	# Prevent the focused editor window from handling auto complete input.
	get_tree().set_input_as_handled()
	

func OnItemSelected(Index: int) -> void:
	visible = false
	emit_signal("OnConfirm", List.get_item_text(Index))
	
