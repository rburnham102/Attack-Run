extends AnimatedSprite2D
## Plays the explosion animation (and an optional sound) once, then deletes
## itself. The animation is set to autoplay with "loop" off, which is what
## makes animation_finished fire.
##
## The sound usually lasts longer than the 4-frame animation, so when the
## animation ends we only hide, and delete ourselves once the sound is done.

## Set by whoever spawns the explosion, before adding it to the scene.
var sound: AudioStream

@onready var _audio: AudioStreamPlayer2D = $Sound


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	if sound:
		_audio.stream = sound
		_audio.play()


func _on_animation_finished() -> void:
	hide()
	if _audio.playing:
		_audio.finished.connect(queue_free)
	else:
		queue_free()
