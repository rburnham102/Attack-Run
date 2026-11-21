extends "res://scenes/enemies/sub_pen.gd"
## Level 4's first boss: a fortress wall across the tracks, built from the
## Mid Boss bunker pieces.
##
## It arrives exactly like the sub pen (sub_pen.gd): it's a building, so it
## moves onto the map and the camera glides up to it and stops. The fight is
## super_tank.gd's: every gun on the wall (the two side heads and the little
## cannons that pop out of the bunker windows) must be destroyed before the
## centre bunker can be hurt. Sweep Time is 0, so it holds still.
##
## What's new here:
##   - the sub pen is the last boss of its level, so the map never scrolls
##     again. The fortress is in the middle of level 4, so once it falls the
##     scrolling speeds back up to normal.
##   - the wall stays behind as a burnt-out ruin.
##   - like the submarine, the centre bunker's hitbox (Hull) starts switched
##     off, so bullets fly over it to the guns sitting on top of it. It
##     switches on when the last gun is gone.

## Seconds for the map to get back up to its normal scroll speed.
@export var resume_time := 2.0
## Colour of the ruins left behind.
@export var ruin_tint := Color(0.4, 0.4, 0.4)

var _scroller: Node2D
var _normal_scroll_speed := 0.0

@onready var _hull: CollisionShape2D = $Hull


func _enter() -> void:
	# Main has just added us to the Scroller. Remember how fast it was going
	# before sub_pen.gd stops it.
	_scroller = get_parent()
	_normal_scroll_speed = _scroller.scroll_speed
	super()


func _drop_armor() -> void:
	super()
	# set_deferred: this can happen inside a collision callback.
	_hull.set_deferred("disabled", false)


func die(shooter_id: int) -> void:
	super(shooter_id)  # sub_pen.gd moves the Garage (side bunkers) onto the map
	# Keep the centre bunker and the wrecked guns too. Moving nodes that have
	# collision shapes isn't allowed in the middle of a collision callback,
	# so do it at the end of the frame.
	_leave_ruins.call_deferred()
	# The tween belongs to the Scroller, so it keeps running after we're gone.
	var resume := _scroller.create_tween()
	resume.tween_property(_scroller, "scroll_speed", _normal_scroll_speed, resume_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


## Moves the centre bunker, its head and the wrecked guns into the Garage,
## which sub_pen.gd has already put on the map, and darkens it all.
func _leave_ruins() -> void:
	for part: Node in [_sprite, _main_turret, $Turrets]:
		part.reparent(_garage)
	# Boss.die() darkened these two already; undo that so the whole ruin
	# gets the same tint (the wrecked guns stay extra dark, burnt out).
	_sprite.self_modulate = Color.WHITE
	_main_turret.self_modulate = Color.WHITE
	_garage.modulate = ruin_tint
