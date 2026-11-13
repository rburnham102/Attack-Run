extends CanvasLayer
## The mission briefing: the general's portrait and a text box along the
## bottom of the screen. Each line types itself out; fire (or Enter) finishes
## the line early, or moves on to the next one once it's all shown.
## Emits finished after the last line, then hides itself.
##
## Main calls start(level) and awaits finished. This scene doesn't know
## anything about planes or the map, so it could be reused for any dialogue.

signal finished

## Typing speed for the text.
@export var characters_per_second := 45.0
## Fade time when the box appears and disappears.
@export var fade_time := 0.3

var _lines: Array[String] = []
var _index := 0
var _typing: Tween

@onready var _box: Control = $Box
@onready var _portrait: TextureRect = $Box/Margin/HBox/Frame/Portrait
@onready var _title: Label = $Box/Margin/HBox/VBox/Title
@onready var _speaker: Label = $Box/Margin/HBox/VBox/Speaker
@onready var _text: Label = $Box/Margin/HBox/VBox/Text
@onready var _hint: Label = $Box/Margin/HBox/VBox/Hint


func _ready() -> void:
	hide()
	# Only listen for key presses while a briefing is running.
	set_process_unhandled_input(false)
	# A gentle endless blink on the "press fire" hint.
	var blink := create_tween().set_loops()
	blink.tween_property(_hint, "modulate:a", 0.25, 0.5)
	blink.tween_property(_hint, "modulate:a", 1.0, 0.5)


func start(level: LevelData) -> void:
	_lines = level.briefing
	_title.text = level.title
	_speaker.text = level.general_name
	_portrait.texture = level.general_portrait
	_index = 0
	if _lines.is_empty():
		finished.emit()
		return
	_box.modulate.a = 0.0
	show()
	set_process_unhandled_input(true)
	create_tween().tween_property(_box, "modulate:a", 1.0, fade_time)
	_show_line()


## Types out the current line by animating Label.visible_ratio from 0 to 1.
## visible_ratio is built into Label: 0.5 shows the first half of the text.
func _show_line() -> void:
	_text.text = _lines[_index]
	_text.visible_ratio = 0.0
	_hint.hide()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, _text.text.length() / characters_per_second)
	_typing.tween_callback(_hint.show)


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed("p1_fire") or event.is_action_pressed("p2_fire")
			or event.is_action_pressed("ui_accept")):
		return
	# Stop the same key press from reaching anything else.
	get_viewport().set_input_as_handled()

	if _typing and _typing.is_running():
		# Still typing: skip to the full line.
		_typing.kill()
		_text.visible_ratio = 1.0
		_hint.show()
	elif _index < _lines.size() - 1:
		_index += 1
		_show_line()
	else:
		_close()


func _close() -> void:
	set_process_unhandled_input(false)
	var fade := create_tween()
	fade.tween_property(_box, "modulate:a", 0.0, fade_time)
	fade.tween_callback(hide)
	finished.emit()
