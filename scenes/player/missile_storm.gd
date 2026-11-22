extends Node2D
## Player 1's special: a barrage of homing missiles fired from under the
## wings, to clear the sky around the plane.
##
## The plane (player.gd) adds this as its child and calls activate() when the
## special button is pressed with a full bar. Missiles leave the two wing
## markers in turn, at Launch Rate per second. Each one kicks out sideways,
## then curves onto its own target: the first goes for the nearest enemy on
## screen, the second for the next nearest, and so on, so the barrage spreads
## out instead of all 16 piling into one plane.

signal finished

## The missile drone's homing missile (homing_bullet.gd).
@export var missile_scene: PackedScene
## Total missiles in the barrage, shared between the two wings.
@export var missile_count := 32
## Missiles per second.
@export var launch_rate := 8.0
## How far out from straight ahead each missile starts, in degrees. The
## missile's turning brings it round onto its target in an arc.
@export var launch_angle := 20.0

## Set by the plane before we're added.
var player: Node2D
## Seconds the barrage lasts. The plane drains its special bar over this time.
var duration: float:
	get:
		return missile_count / launch_rate

@onready var _wings: Array[Marker2D] = [$LeftWing, $RightWing]
@onready var _sound: AudioStreamPlayer2D = $LaunchSound


func activate() -> void:
	# A tween as a timeline: fire, wait, fire, wait... then report back.
	var barrage := create_tween()
	for i in missile_count:
		barrage.tween_callback(_launch.bind(i))
		barrage.tween_interval(1.0 / launch_rate)
	barrage.tween_callback(finished.emit)


func _launch(index: int) -> void:
	var side := -1 if index % 2 == 0 else 1  # left wing, then right
	var missile := missile_scene.instantiate()
	missile.position = _wings[index % 2].global_position
	var angle := deg_to_rad(side * launch_angle + randf_range(-12.0, 12.0))
	missile.direction = Vector2.UP.rotated(angle)
	missile.shooter_id = player.player_id
	var targets := _enemies_on_screen()
	if not targets.is_empty():
		missile.target = targets[index % targets.size()]
	Game.add_to_world(missile)
	_sound.play()


## The enemies on screen that a missile could hit, nearest first.
func _enemies_on_screen() -> Array[Node2D]:
	# The canvas transform moves the map to the screen, so its inverse turns
	# the screen rectangle into map coordinates.
	var screen := get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	var found: Array[Node2D] = []
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if not enemy.destroyed and enemy.monitorable and screen.has_point(enemy.global_position):
			found.append(enemy)
	var from := global_position
	found.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return from.distance_squared_to(a.global_position) < from.distance_squared_to(b.global_position))
	return found
