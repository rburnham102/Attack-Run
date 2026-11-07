extends AnimatedSprite2D
## Plays the explosion animation once, then deletes itself.
## The animation is set to autoplay, and its "loop" is off, which is what
## makes animation_finished fire.


func _ready() -> void:
	animation_finished.connect(queue_free)
