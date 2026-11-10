extends Enemy
## A gun turret mounted on the Super Bomber. It aims at the nearest player
## and fires short bursts, like a tank turret.
##
## It's its own Enemy so it can be shot off separately. It sits on the
## ground_enemies layer: player bullets hit that layer, but the player's plane
## doesn't, so flying over a turret never counts as ramming it.
##
## Damage spent on a turret is never wasted: when it's destroyed it passes its
## full health on to the boss as damage. After that it stays on the boss as a
## dark wreck, and any hits it takes are passed on to the boss too, so the gap
## left in the boss's hull under each turret never becomes a blind spot.

@export var bullet_scene: PackedScene
## How fast the turret can swing toward its target, in degrees per second.
@export var turn_speed := 120.0
@export var burst_count := 3
@export var burst_delay := 0.12

## The boss this turret is mounted on. Set by the boss.
var boss: Enemy
## False while the boss is flying in and after it's destroyed.
var active := false

var _start_hp := 0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _muzzle: Marker2D = $Muzzle
@onready var _fire_timer: Timer = $FireTimer


func _ready() -> void:
	super()  # sets hp for this stage, and speeds up FireTimer on later stages
	_start_hp = hp
	_fire_timer.timeout.connect(_fire)


func activate() -> void:
	active = true
	# A random first delay so the two turrets don't fire in unison.
	_fire_timer.start(randf_range(0.5, _fire_timer.wait_time))


func deactivate() -> void:
	active = false
	_fire_timer.stop()


func _process(delta: float) -> void:
	if not active:
		return
	var target := Game.nearest_player(global_position)
	if target:
		# The sprite points down (+Y), whose angle is PI/2, so subtract it.
		var wanted := (target.global_position - global_position).angle() - PI / 2
		global_rotation = rotate_toward(global_rotation, wanted, deg_to_rad(turn_speed) * delta)


func _fire() -> void:
	if not Game.nearest_player(global_position):
		return
	var burst := create_tween()
	for i in burst_count:
		burst.tween_callback(_fire_once)
		burst.tween_interval(burst_delay)


func _fire_once() -> void:
	if active:  # the burst may still be running when the turret is knocked out
		shoot(bullet_scene, _muzzle.global_position, Vector2.DOWN.rotated(global_rotation))


func take_damage(amount: int, shooter_id: int) -> void:
	if destroyed:
		boss.take_damage(amount, shooter_id)
	elif active:
		super(amount, shooter_id)


## Instead of disappearing, the turret explodes and leaves a burnt wreck.
func die(shooter_id: int) -> void:
	destroyed = true
	deactivate()
	Game.add_score(shooter_id, score_value)
	_sprite.self_modulate = Color(0.3, 0.3, 0.3)
	var boom := EXPLOSION.instantiate()
	boom.position = global_position
	boom.scale = Vector2.ONE * explosion_scale
	boom.sound = death_sound
	Game.add_to_world(boom)
	boss.take_damage(_start_hp, shooter_id)
