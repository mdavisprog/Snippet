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

tool
class_name SnippetToolbar
extends HBoxContainer

# OnAction
#
# Action: ACTION
signal OnAction(Action)

enum ACTION {
	RUN,
	RUNUT,
	RESUME,
	STOP
}

# The scale applied to all texture buttons based on their normal texture.
export var Scale = 0.5 setget SetScale

# The default tooltip text for running the unit test. This will be restored after debugging is complete.
var RunUTTooltip = ""

# The 'Run' button.
onready var Run: TextureButton = $Run

# The 'Run Unit Tests' button.
onready var RunUT: TextureButton = $RunUT

# The 'Resume' button used to continue a paused debug execution.
onready var Resume: TextureButton = $Resume

# The 'Stop' button.
onready var Stop: TextureButton = $Stop

func _ready() -> void:
	var _Error = connect("resized", self, "OnResized")
	
	OnResized()
	
	# Game and editor initialization ends here.
	if Engine.editor_hint:
		return
	
	# Begin game initialization only.
	_Error = Run.connect("pressed", self, "OnRun")
	_Error = RunUT.connect("pressed", self, "OnRunUT")
	_Error = Resume.connect("pressed", self, "OnResume")
	_Error = Stop.connect("pressed", self, "OnStop")
	
	RunUTTooltip = RunUT.hint_tooltip
	

func _enter_tree() -> void:
	# Called every time the scene is focused in the editor.
	if Engine.editor_hint:
		OnResized()
		return

func OnResized() -> void:
	var Height = 64
	var Children: Array = get_children()
	for I in Children:
		var Item = I as TextureButton
		if Item:
			var Size = Vector2(64, 64)
			if Item.texture_normal:
				Size = Item.texture_normal.get_size()
			
			Item.expand = true
			Item.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			Item.rect_min_size = Size * Scale
			Item.rect_size = Item.rect_min_size
			Height = min(Height, Item.rect_size.y)
	
	rect_size.y = Height
	

func SetScale(Value: float) -> void:
	Scale = Value
	OnResized()
	

func OnRun() -> void:
	emit_signal("OnAction", ACTION.RUN)
	

func OnRunUT() -> void:
	emit_signal("OnAction", ACTION.RUNUT)
	

func OnResume() -> void:
	emit_signal("OnAction", ACTION.RESUME)
	

func OnStop() -> void:
	emit_signal("OnAction", ACTION.STOP)
	

func SetResume(Enabled: bool) -> void:
	RunUT.disabled = not Enabled
	RunUT.hint_tooltip = "Step" if Enabled else RunUTTooltip
	Resume.disabled = not Enabled
	
