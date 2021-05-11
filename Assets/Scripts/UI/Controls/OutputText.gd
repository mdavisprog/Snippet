class_name OutputText
extends RichTextLabel

# Manages displaying output from the application or developer.

func _ready() -> void:
	var _Error = Log.connect("OnLog", self, "OnLog")
	

func OnLog(_Type: int, Contents: String) -> void:
	print(Contents)
	AddLine(Contents)
	

func AddLine(Line: String) -> void:
	add_text(Line + "\n")
	
