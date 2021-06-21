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

class_name TextureButtonMenu
extends TextureButton

# This class acts as a custom menu button using a texture, but will make the
# the popup instance a child of the root control to prevent any scaling applied to
# the direct parent.

# The popup instance that will be displayed for this item.
var Instance: PopupMenu = null

func _ready() -> void:
	var _Error = null
	
	if not Instance:
		Instance = PopupMenu.new()
		
		# The the top most control
		var Top: Control = Utility.GetTop(self)
		Top.call_deferred("add_child", Instance)
		
		_Error = Instance.connect("id_pressed", self, "OnSelected")
	

func _pressed():
	if Instance:
		Instance.popup()
		Instance.set_global_position(get_global_mouse_position())
	

#
# OnSelected
#
# Virtual function that sub-classes can override when the user selects an option.
#
func OnSelected(_Id: int) -> void:
	pass
	
