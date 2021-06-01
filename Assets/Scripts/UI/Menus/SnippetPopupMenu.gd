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

class_name SnippetPopupMenu
extends BasePopupMenu

# Context menu options when the developer has selected a snippet.

# List of actions that can be taken on a snippet.
enum {
	EDIT,
	EDIT_TITLE,
	DELETE
}

# The snippet the popup menu is referencing.
var SnippetRef: Snippet = null

func _ready():
	var _Error = connect("popup_hide", self, "OnHide")
	

func SetSnippet(InSnippetRef: Snippet) -> void:
	clear()
	
	SnippetRef = InSnippetRef
	if SnippetRef:
		add_item("Edit", EDIT)
		add_item("Edit Name", EDIT_TITLE)
		add_item("Delete", DELETE)
		
		var SnippetGraphNode: SnippetGraph = get_node_or_null(Utility.GRAPH)
		if SnippetGraphNode.MainSnippet == SnippetRef:
			set_item_disabled(EDIT_TITLE, true)
			set_item_disabled(DELETE, true)
		
		SnippetRef.SetState(Snippet.STATE.LOCKED)
	

func OnPressed(Id: int) -> void:
	match (Id):
		EDIT:
			ShowSnippetEditor(Id)
		EDIT_TITLE:
			ShowSnippetEditor(Id)
		DELETE:
			SnippetRef.Clean()
			SnippetRef.queue_free()
	

func OnHide() -> void:
	if SnippetRef:
		SnippetRef.SetState(Snippet.STATE.NORMAL)
		SnippetRef.OnMouseExited()
	

func ShowSnippetEditor(Op: int) -> void:
	var Items: Array = get_tree().get_nodes_in_group("SnippetWindows")
	for I in Items:
		if I.This == SnippetRef:
			if Op == EDIT_TITLE:
				I.EditTitle()
			return
	
	var UIFactoryNode: UIFactory = get_node_or_null(Utility.UIFACTORY)
	if UIFactoryNode.SnippetWindowTemplate:
		var Instance: SnippetWindow = UIFactoryNode.SnippetWindowTemplate.instance()
		get_parent().add_child(Instance)
		Instance.Show(SnippetRef)
		
		if Op == EDIT_TITLE:
			Instance.EditTitle()
	
