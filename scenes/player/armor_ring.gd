extends Node2D
## Draws a faint ring around the plane while it has armor. There's no shield
## sprite in the assets, so this uses Godot's built-in drawing instead:
## queue_redraw() asks Godot to call _draw() again on the next frame.

@export var radius := 40.0
@export var color := Color(0.55, 0.85, 1.0)

## Number of armor points. Setting it redraws the ring.
var level := 0:
	set(value):
		level = value
		queue_redraw()


func _draw() -> void:
	if level <= 0:
		return
	var strength := 0.25 + 0.2 * level
	draw_circle(Vector2.ZERO, radius, Color(color, strength * 0.25))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, strength), 3.0, true)
