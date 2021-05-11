extends Node

# Singleton utility class to manage logging and allow multiple listeners to
# handle logging requests.

# OnLog
#
# Type: TYPE
# Contents: String
signal OnLog(Type, Contents)

# Types of logs that can be dispatched.
enum TYPE {INFO, WARN, ERROR}

func Info(Contents: String) -> void:
	emit_signal("OnLog", TYPE.INFO, Contents)
	

func Warn(Contents: String) -> void:
	emit_signal("OnLog", TYPE.WARN, Contents)
	

func Error(Contents: String) -> void:
	emit_signal("OnLog", TYPE.ERROR, Contents)
	
