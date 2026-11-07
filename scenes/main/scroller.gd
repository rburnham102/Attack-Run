extends Node2D
## Moves steadily up the map. The Camera2D and the players are children of
## this node, so they ride along with it automatically.

## Pixels per second.
@export var scroll_speed := 40.0


func _process(delta: float) -> void:
	position.y -= scroll_speed * delta
