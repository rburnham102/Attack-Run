extends CanvasLayer
## The mission briefing: a portrait and a text box along the bottom of the
## screen. Each line types itself out; fire (or Enter) finishes the line
## early, or moves on to the next one once it's all shown.
## Emits finished after the last line, then hides itself.
##
## Each line is a RadioLine, which says who is talking, so the general and
## Lt. Lilly can take turns. The portrait and name swap for every line.
##
## Main calls start(level) and awaits finished. This scene doesn't know
## anything about planes or the map, so it could be reused for any dialogue.

signal finished

## Typing speed for the text.
@export var characters_per_second := 45.0
## Fade time when the box appears and disappears.
@export var fade_time := 0.3
## Name colours, so you can tell at a glance who is talking. Lilly's matches
## the teal of her radio box.
@export var general_color := Color(1, 0.8, 0.35)
@export var comms_color := Color(0.55, 1, 0.85)

var _level: LevelData
var _lines: Array[RadioLine] = []
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
	_level = level
	_lines = level.briefing
	_title.text = level.title
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
	var line := _lines[_index]
	_show_speaker(line)
	_text.text = line.text
	_text.visible_ratio = 0.0
	_hint.hide()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, _text.text.length() / characters_per_second)
	_typing.tween_callback(_hint.show)


## Puts the right name and face up for this line.
func _show_speaker(line: RadioLine) -> void:
	if line.speaker == RadioLine.Speaker.GENERAL:
		_speaker.text = _level.general_name
		_speaker.label_settings.font_color = general_color
		_portrait.texture = _level.general_portrait
		# The general is a painted portrait: smooth scaling suits it.
		_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		_speaker.text = RadioLine.COMMS_NAME
		_speaker.label_settings.font_color = comms_color
		# A still from her mood animation. The last frame is the one with her
		# mouth closed (see radio.gd).
		var frames := RadioLine.COMMS_PORTRAITS
		var anim := line.mood_animation()
		_portrait.texture = frames.get_frame_texture(anim, frames.get_frame_count(anim) - 1)
		# She's pixel art: nearest-neighbour keeps her crisp when scaled up.
		_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


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
