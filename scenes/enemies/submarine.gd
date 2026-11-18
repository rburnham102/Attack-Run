extends "res://scenes/enemies/super_tank.gd"
## Level 3's first boss: a submarine that surfaces in the open sea.
##
## The fighting all comes from super_tank.gd: every deck gun must be destroyed
## before the hull can be hurt, the main turret swings to follow the nearest
## player, and boss.gd adds the sweep and the two attacks. (super_tank.gd has
## no class_name, so we extend it by its path.) This script only changes:
##   - the arrival: it rises up where it will fight instead of driving in.
##   - the hitbox: its guns sit on top of the hull, all over it. If the hull
##     could catch bullets while armored it would shield the guns, so its
##     hitbox (Hull) starts switched off: bullets pass over the hull to the
##     guns. It switches on once the last gun is gone and the armor drops.

## Seconds to come up from the depths.
@export var surface_time := 3.0
## How it looks while still deep under water: dark and see-through.
@export var submerged_color := Color(0.25, 0.4, 0.45, 0.0)

@onready var _hull: CollisionShape2D = $Hull


func _enter() -> void:
	position.y = battle_y
	modulate = submerged_color
	# The whole sub (and the ring of foam around it, the Wake sprite) fades
	# up from dark and see-through, as if rising to the surface.
	var rise := create_tween()
	rise.tween_property(self, "modulate", Color.WHITE, surface_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	rise.tween_callback(_start_fight)


func _drop_armor() -> void:
	super()
	# set_deferred: this can happen inside a collision callback.
	_hull.set_deferred("disabled", false)
