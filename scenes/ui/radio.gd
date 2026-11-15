extends CanvasLayer
## The comms officer's live radio calls during a mission (boss warnings,
## "target down", and so on). The general only does the briefing.
##
## Main calls say(line). Unlike the Briefing, this never pauses the game or
## waits for input: the box fades in, the line types itself out while her
## portrait talks, it stays up for hold_time, then fades away on its own.
## If a new line comes in while she's talking, it cuts the old one off.

## Her name above the text. It's the same character in every level, so it
## lives here rather than in LevelData (which has the general's name).
@export var speaker_name := "COMMS OFFICER"
@export var characters_per_second := 40.0
## Seconds the finished line stays on screen before the box fades.
@export var hold_time := 2.5
@export var fade_time := 0.25

## One tween runs the whole call: wait, fade in, type, hold, fade out.
## Killing it cancels everything at once.
var _call: Tween
var _typing := false

@onready var _box: Control = $Box
@onready var _portrait: AnimatedSprite2D = $Box/Margin/HBox/Frame/Window/Portrait
@onready var _speaker: Label = $Box/Margin/HBox/VBox/Speaker
@onready var _text: Label = $Box/Margin/HBox/VBox/Text


func _ready() -> void:
	hide()
	_speaker.text = speaker_name
	_portrait.animation_finished.connect(_on_portrait_finished)


## Plays one radio call. delay is how many seconds to wait before it starts
## (used so she doesn't cover the boss's death explosions).
func say(line: RadioLine, delay := 0.0) -> void:
	if not line:
		return
	if _call:
		_call.kill()
	_call = create_tween()
	_call.tween_interval(delay)
	_call.tween_callback(_open.bind(line))
	_call.tween_property(_box, "modulate:a", 1.0, fade_time)
	_call.tween_property(_text, "visible_ratio", 1.0,
		line.text.length() / characters_per_second)
	_call.tween_callback(func(): _typing = false)
	_call.tween_interval(hold_time)
	_call.tween_property(_box, "modulate:a", 0.0, fade_time)
	_call.tween_callback(hide)


func _open(line: RadioLine) -> void:
	_text.text = line.text
	_text.visible_ratio = 0.0
	_box.modulate.a = 0.0
	show()
	_typing = true
	# Mood.SHOCKED -> "SHOCKED" -> "shocked", the animation's name.
	_portrait.play(RadioLine.Mood.keys()[line.mood].to_lower())


## Her animations don't loop on their own (in comms_officer.tres). While the
## text is still typing we restart the animation so she keeps talking. Once
## it's typed out we let it end, and it stops on its last frame, where her
## mouth is closed.
func _on_portrait_finished() -> void:
	if _typing:
		_portrait.frame = 0
		_portrait.play()
