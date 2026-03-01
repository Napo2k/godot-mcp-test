extends Node
## DataLog autoload — scrolling text buffer for Pane D.

signal message_logged(text: String)

var _history: Array[String] = []
const MAX_HISTORY := 200

func log(text: String) -> void:
	_history.append(text)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	emit_signal("message_logged", text)

func get_history() -> Array[String]:
	return _history.duplicate()

func clear() -> void:
	_history.clear()
