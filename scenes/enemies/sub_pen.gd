extends "res://scenes/enemies/super_tank.gd"
## Level 3's final boss: the enemy's submarine pen, with a sub docked inside.
##
## Every other boss flies or drives, so it lives on the Scroller and keeps up
## with the camera. The pen is a building, so it works the other way round:
## on arrival it moves off the Scroller onto the map, and the camera glides
## up to it and stops. The map doesn't scroll again for the rest of the level.
##
## The fight is super_tank.gd: the guns around the docks must all be destroyed
## before the docked sub (the hull) can be hurt. Sweep Time is 0, so it holds
## still.

## Seconds for the camera to glide up to the base and stop.
@export var arrive_time := 5.0
## The garage art's rectangle around our origin (the docked sub). Ground
## vehicles inside it would be hidden under the buildings, so they're removed.
@export var cover_rect := Rect2(-320, -300, 640, 1363)

var _gliding := false

@onready var _garage: Node2D = $Garage


func _enter() -> void:
	# Main has just added us to the Scroller, like every boss. A node can't be
	# moved while its parent is still adding it, so wait until the end of the
	# frame (call_deferred) before moving.
	_arrive.call_deferred()


func _arrive() -> void:
	var scroller: Node2D = get_parent()
	# How far the camera travels: far enough that the whole base starts hidden
	# above the top of the screen.
	var travel := battle_y + cover_rect.end.y + 40.0
	# reparent() moves us to another parent but keeps us where we are on
	# screen. Then we put ourselves where the camera will stop.
	reparent(scroller.get_parent())
	global_position = scroller.global_position + Vector2(position.x, battle_y - travel)

	# Take over the scrolling: stop the Scroller's own movement and glide it
	# up instead, speeding up then easing to a stop on the base.
	scroller.scroll_speed = 0.0
	_gliding = true
	var glide := create_tween()
	glide.tween_property(scroller, "position:y", scroller.position.y - travel, arrive_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glide.tween_callback(_on_arrived)


func _on_arrived() -> void:
	_gliding = false
	_bury_vehicles()
	_start_fight()


func _process(delta: float) -> void:
	super(delta)
	if _gliding:
		_bury_vehicles()


## Removes any ground vehicle the base has slid over. Tanks and turrets join
## the "ground_vehicles" group in tank.gd.
func _bury_vehicles() -> void:
	var area := Rect2(global_position + cover_rect.position, cover_rect.size)
	for vehicle in get_tree().get_nodes_in_group("ground_vehicles"):
		if area.has_point(vehicle.global_position):
			vehicle.queue_free()


func die(shooter_id: int) -> void:
	# Boss.die() fades us out. The buildings should stay, so move the garage
	# art onto the map first.
	_garage.reparent(get_parent())
	super(shooter_id)
