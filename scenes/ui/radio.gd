extends CanvasLayer
## Live radio calls during a mission (boss warnings, "target down", the
## end-of-mission chatter). Usually Lt. Lilly, but any line can be the
## general instead: each RadioLine says who is talking.
##
## Main calls say(lines). Unlike the Briefing, this never pauses the game or
## waits for input: the box fades in, each line types itself out while the
## speaker's portrait shows, stays up for hold_time, then the next line
## starts. After the last one the box fades away and finished is emitted.
## If a new call comes in while one is playing, it cuts the old one off.

## The whole call (every line) has been played and the box has faded out.
signal finished

@export var characters_per_second := 40.0
## Seconds each finished line stays on screen before the next one (or the
## fade out).
@export var hold_time := 2.5
@export var fade_time := 0.25
## Name colours, matching the Briefing's.
@export var general_color := Color(1, 0.8, 0.35)
@export var comms_color := Color(0.55, 1, 0.85)

## One tween runs the whole call: wait, fade in, then type and hold each
## line, fade out. Killing it cancels everything at once.
var _call: Tween
var _typing := false
## The general's name and portrait come from the level. Main sets this.
var level: LevelData

@onready var _box: Control = $Box
@onready var _portrait: AnimatedSprite2D = $Box/Margin/HBox/Frame/Window/Portrait
@onready var _general_portrait: TextureRect = $Box/Margin/HBox/Frame/Window/GeneralPortrait
@onready var _speaker: Label = $Box/Margin/HBox/VBox/Speaker
@onready var _text: Label = $Box/Margin/HBox/VBox/Text


func _ready() -> void:
	hide()
	_portrait.animation_finished.connect(_on_portrait_finished)


## Plays a radio call: one or more lines, one after another. delay is how
## many seconds to wait before it starts (used so the box doesn't cover the
## boss's death explosions). An empty list is a silent call: finished is
## still emitted, so anyone waiting on it doesn't hang.
func say(lines: Array[RadioLine], delay := 0.0) -> void:
	if _call:
		_call.kill()
	if lines.is_empty():
		# Deferred, so a caller that connects to finished right after calling
		# say() still hears it.
		finished.emit.call_deferred()
		return
	_call = create_tween()
	_call.tween_interval(delay)
	for i in lines.size():
		var line := lines[i]
		_call.tween_callback(_open.bind(line))
		if i == 0:
			_call.tween_property(_box, "modulate:a", 1.0, fade_time)
		_call.tween_property(_text, "visible_ratio", 1.0,
			line.text.length() / characters_per_second)
		_call.tween_callback(func(): _typing = false)
		_call.tween_interval(hold_time)
	_call.tween_property(_box, "modulate:a", 0.0, fade_time)
	_call.tween_callback(hide)
	_call.tween_callback(finished.emit)


## Shows the box (if hidden) and sets it up for one line: who's talking and
## what they say.
func _open(line: RadioLine) -> void:
	_text.text = line.text
	_text.visible_ratio = 0.0
	if not visible:
		_box.modulate.a = 0.0
		show()
	_typing = true
	var is_general := line.speaker == RadioLine.Speaker.GENERAL
	_portrait.visible = not is_general
	_general_portrait.visible = is_general
	if is_general:
		_speaker.text = level.general_name if level else "GENERAL"
		_speaker.label_settings.font_color = general_color
		_general_portrait.texture = level.general_portrait if level else null
	else:
		_speaker.text = RadioLine.COMMS_NAME
		_speaker.label_settings.font_color = comms_color
		_portrait.play(line.mood_animation())


## Her animations don't loop on their own (in comms_officer.tres). While the
## text is still typing we restart the animation so she keeps talking. Once
## it's typed out we let it end, and it stops on its last frame, where her
## mouth is closed.
func _on_portrait_finished() -> void:
	if _typing:
		_portrait.frame = 0
		_portrait.play()
