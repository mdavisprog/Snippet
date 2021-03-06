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

class_name BottomDock
extends TabContainer

# Controls to be displayed on the bottom of the main viewport.

# The height of this dock. Used to restore the value when being expanded.
var Height = 0.0

# The output window used to display output from snippets.
onready var Output: OutputText = $Output

# The sizer used for this dock.
onready var Sizer: DynamicSizer = $DynamicSizer

func _ready() -> void:
	Sizer.MarginN = get_constant("top_margin")
	
	var _Error = connect("tab_selected", self, "OnTabSelected")
	

func OnTabSelected(Tab: int) -> void:
	if Tab == current_tab:
		var TopMargin = get_constant("top_margin")
		if margin_top == -TopMargin:
			margin_top = Height
		else:
			Height = margin_top
			margin_top = -TopMargin
	
