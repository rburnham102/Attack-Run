extends Node2D
## An allied landing boat (a "boat tank") hitting the beach in level 2.
## It's scenery that fights: it drives up toward the shore, stops at the
## waterline, and shells any enemy vehicle in range. It can't be shot or
## rammed (it's a plain Node2D, not an Area2D), so the player never has to
## worry about it.
##
## Place these straight into a chunk scene, like props. Rotate one the same
## way as a vehicle or SpawnPoint: at rotation 0 it drives down the screen,
## at 180 it drives up (toward the beach).

@export var move_speed := 26.0
## How far it drives before stopping, in pixels. Set it so the boat stops
## with its bow on the sand.
@export var drive_distance := 150.0
@export var shell_scene: PackedScene
## How fast the cannon can swing toward its target, in degrees per second.
@export var turret_turn_speed := 80.0

var _driven := 0.0

@onready var _turret: Node2D = $Turret
@onready var _muzzle: Marker2D = $Turret/Muzzle
@onready var _radar: Area2D = $Radar
@onready var _fire_timer: Timer = $FireTimer
@onready var _wake: AnimatedSprite2D = $Wake


func _ready() -> void:
	_fire_timer.timeout.connect(_fire)
	# A random first delay so a line of boats doesn't fire in unison.
	_fire_timer.start(randf_range(0.5, _fire_timer.wait_time))


func _process(delta: float) -> void:
	if _driven < drive_distance:
		var step := minf(move_speed * delta, drive_distance - _driven)
		position += Vector2.DOWN.rotated(rotation) * step
		_driven += step
	elif _wake.visible:
		# Beached: no more bow wave.
		_wake.hide()

	var target := _nearest_target()
	if target:
		# The cannon sprite points down (+Y), whose angle is PI/2, so subtract it.
		var wanted := (target.global_position - _turret.global_position).angle() - PI / 2
		_turret.global_rotation = rotate_toward(
			_turret.global_rotation, wanted, deg_to_rad(turret_turn_speed) * delta)


## The closest enemy vehicle inside the Radar circle, or null.
## The Radar's mask only includes the ground_enemies layer, so planes and
## the players are never picked.
func _nearest_target() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for area in _radar.get_overlapping_areas():
		if area is Enemy and not area.destroyed:
			var d := global_position.distance_squared_to(area.global_position)
			if d < best_dist:
				best_dist = d
				best = area
	return best


## Only fires once the cannon is roughly lined up, so shells go where the
## barrel points.
func _fire() -> void:
	var target := _nearest_target()
	if not target:
		return
	var to_target := target.global_position - _muzzle.global_position
	var aim := Vector2.DOWN.rotated(_turret.global_rotation)
	if absf(aim.angle_to(to_target)) > deg_to_rad(15.0):
		return
	var shell := shell_scene.instantiate()
	shell.position = _muzzle.global_position
	shell.direction = aim
	# shooter_id stays 0: allied kills give no points (Game.add_score
	# ignores 0), so the players can't farm score off the landing.
	Game.add_to_world(shell)
