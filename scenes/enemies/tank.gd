extends Enemy
## Any ground or water vehicle: tank, BTR, ACS, Humvee or gunboat. Each one is
## its own scene using this script, with different sprites and Inspector values.
##
## Rotate a vehicle in the editor to choose which way it drives: at rotation 0
## it drives down the screen. The Turret child is optional; a vehicle without
## one (the Humvee) just drives and never shoots.

@export var move_speed := 20.0
## How fast the turret can swing toward its target, in degrees per second.
@export var turret_turn_speed := 90.0
@export var shell_scene: PackedScene
## Shots fired one after another each time FireTimer runs out (a burst).
@export var burst_count := 1
@export var burst_delay := 0.15
## Shots fired at the same moment in a fan. 1 = a single shot.
@export var spread_count := 1
@export var spread_angle := 15.0
## Sprite left behind on the ground after the vehicle is destroyed.
@export var wreck_texture: Texture2D
## Tint for the wreck. Darkening a normal sprite makes it look burnt out.
@export var wreck_tint := Color.WHITE

@onready var _base: Node2D = $Base
@onready var _turret: Node2D = get_node_or_null("Turret")
@onready var _muzzle: Marker2D = get_node_or_null("Turret/Muzzle")
@onready var _fire_timer: Timer = get_node_or_null("FireTimer")


func _ready() -> void:
	super()
	if _turret and _fire_timer:
		_fire_timer.timeout.connect(_fire)
		_fire_timer.start(randf_range(0.8, _fire_timer.wait_time))


func _process(delta: float) -> void:
	position += Vector2.DOWN.rotated(rotation) * move_speed * delta

	if not _turret:
		return
	var target := Game.nearest_player(global_position)
	if target:
		# The turret sprite points down (+Y), whose angle is PI/2, so subtract it.
		var wanted := (target.global_position - _turret.global_position).angle() - PI / 2
		_turret.global_rotation = rotate_toward(
			_turret.global_rotation, wanted, deg_to_rad(turret_turn_speed) * delta)


## A burst is a Tween of callbacks with pauses between them. Tweens made with
## create_tween() belong to this node, so they stop if the vehicle is destroyed.
func _fire() -> void:
	if not Game.nearest_player(global_position):
		return
	var burst := create_tween()
	for i in burst_count:
		burst.tween_callback(_fire_volley)
		burst.tween_interval(burst_delay)


## Fires spread_count shots in a fan around the turret's direction.
func _fire_volley() -> void:
	var forward := Vector2.DOWN.rotated(_turret.global_rotation)
	for i in spread_count:
		var angle := deg_to_rad((i - (spread_count - 1) / 2.0) * spread_angle)
		shoot(shell_scene, _muzzle.global_position, forward.rotated(angle))


func die(shooter_id: int) -> void:
	# Leave a wreck in the chunk (our parent) so it scrolls away with the map.
	# It copies the hull's flip so it faces the same way the vehicle did.
	if wreck_texture:
		var wreck := Sprite2D.new()
		wreck.texture = wreck_texture
		wreck.transform = transform
		wreck.modulate = wreck_tint
		if _base is Sprite2D:
			wreck.flip_v = _base.flip_v
		get_parent().add_child.call_deferred(wreck)
	super(shooter_id)
