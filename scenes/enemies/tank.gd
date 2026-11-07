extends Enemy
## A ground vehicle with a rotating turret. Place tanks inside chunk scenes.
## Rotate the tank in the editor to choose which way it drives:
## at rotation 0 it drives down the screen (the way the sprite faces).

@export var move_speed := 20.0
## How fast the turret can swing toward its target, in degrees per second.
@export var turret_turn_speed := 90.0
@export var shell_scene: PackedScene
## Sprite left behind on the ground after the tank is destroyed.
@export var wreck_texture: Texture2D

@onready var _turret: Node2D = $Turret
@onready var _muzzle: Marker2D = $Turret/Muzzle
@onready var _fire_timer: Timer = $FireTimer


func _ready() -> void:
	super()
	_fire_timer.timeout.connect(_on_fire_timer_timeout)
	_fire_timer.start(randf_range(0.8, _fire_timer.wait_time))


func _process(delta: float) -> void:
	position += Vector2.DOWN.rotated(rotation) * move_speed * delta

	var target := Game.nearest_player(global_position)
	if target:
		# The turret sprite points down (+Y), whose angle is PI/2, so subtract it.
		var wanted := (target.global_position - _turret.global_position).angle() - PI / 2
		_turret.global_rotation = rotate_toward(
			_turret.global_rotation, wanted, deg_to_rad(turret_turn_speed) * delta)


func _on_fire_timer_timeout() -> void:
	if Game.nearest_player(global_position):
		shoot(shell_scene, _muzzle.global_position, Vector2.DOWN.rotated(_turret.global_rotation))


func die(shooter_id: int) -> void:
	# Leave a wreck in the chunk (our parent) so it scrolls away with the map.
	if wreck_texture:
		var wreck := Sprite2D.new()
		wreck.texture = wreck_texture
		wreck.transform = transform
		get_parent().add_child.call_deferred(wreck)
	super(shooter_id)
