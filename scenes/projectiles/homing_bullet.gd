extends "res://scenes/projectiles/bullet.gd"
## A player missile that curves toward the nearest enemy (fired by the
## missile drone). Everything else, like hitting, damage and cleaning up,
## is bullet.gd's.
##
## Like the enemy missile it can only turn turn_speed degrees per second, so
## it swings round in an arc instead of snapping onto its target.

## How fast it can turn, in degrees per second.
@export var turn_speed := 220.0
## Only enemies closer than this are chased.
@export var seek_range := 700.0

## Optional: the enemy to chase, set by whoever fires us (the missile storm
## spreads its missiles over different enemies this way). Once it's gone,
## we chase the nearest enemy instead.
var target: Node2D = null


func _process(delta: float) -> void:
	if not _can_chase(target):
		target = _nearest_enemy()
	if target:
		var wanted := (target.global_position - global_position).angle()
		var angle := rotate_toward(direction.angle(), wanted, deg_to_rad(turn_speed) * delta)
		direction = Vector2.from_angle(angle)
		rotation = direction.angle() + PI / 2
	super(delta)  # bullet.gd moves us along direction


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_distance := seek_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		# monitorable is off for knocked-out boss turrets and the like:
		# nothing could hit them, so don't chase them.
		if not _can_chase(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


## False once an enemy is freed or destroyed, or for knocked-out boss turrets
## and the like (monitorable is off): nothing could hit them, so don't chase.
## The argument has no type on purpose: a typed one refuses a freed enemy
## before is_instance_valid() gets to check it.
func _can_chase(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.destroyed and enemy.monitorable
