class_name Drone
extends Area2D
## A small helper drone that flies in formation beside a player's plane.
## Picked up from level 3 on. One script covers all three kinds, the same
## way pickup.gd covers every pickup: each drone scene just sets Kind and
## its own sprites.
##
##   GUN      fires a player bullet straight up every time the plane fires.
##   MISSILE  while the plane fires, launches a homing missile every
##            Missile Cooldown seconds.
##   SHIELD   projects a bubble that stops enemy bullets. Each bullet costs
##            a charge (its lights show how many are left); with none left
##            the bubble drops and bullets hit the drone itself. Charges
##            come back over time.
##
## A drone sits on the "player" collision layer and has take_damage(), so
## enemy bullets already hit it with no extra wiring. When its HP runs out
## it's gone for good: the plane's slot frees up for the next drone pickup.

enum Kind { GUN, MISSILE, SHIELD }

@export var kind := Kind.GUN
@export var max_hp := 5
## Seconds it can't be hurt after a hit, like the plane. Stops one burst of
## bullets from shredding a drone all at once.
@export var hit_invuln_time := 0.8
## How quickly it catches up with its spot beside the plane. Lower = it
## lags further behind when the plane moves.
@export var follow_speed := 9.0
## Gun: the player bullet. Missile: the homing missile.
@export var bullet_scene: PackedScene
@export var missile_cooldown := 1.2
@export var max_shield := 3
## Seconds to get one shield charge back.
@export var shield_recharge_time := 6.0
@export var shield_radius := 52.0
@export var shield_color := Color(0.45, 0.95, 1.0)
@export var death_sound: AudioStream

## Set by the player that owns this drone, before adding it to the scene.
var player: Node2D
var player_id := 1
## Where it flies relative to the plane.
var slot_offset := Vector2.ZERO

var hp := 0
var shield := 0
var _invulnerable := false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _muzzle: Marker2D = $Muzzle
@onready var _bubble: CollisionShape2D = get_node_or_null("Bubble")
@onready var _cooldown: Timer = $Cooldown


func _ready() -> void:
	hp = max_hp
	if kind == Kind.MISSILE:
		_cooldown.wait_time = missile_cooldown
	elif kind == Kind.SHIELD:
		shield = max_shield
		_cooldown.wait_time = shield_recharge_time
		_cooldown.timeout.connect(_recharge)
		_cooldown.start()  # a Timer without One Shot repeats on its own
		_update_shield()


func _process(delta: float) -> void:
	# Our player was destroyed for good (game over): go with it.
	if not is_instance_valid(player):
		queue_free()
		return
	# Move part of the way toward our spot each frame. 1 - exp(-k * delta)
	# makes the catching-up the same speed at any frame rate.
	var target := player.position + slot_offset
	position = position.lerp(target, 1.0 - exp(-follow_speed * delta))


## The plane calls this every time it fires.
func fire() -> void:
	match kind:
		Kind.GUN:
			_launch()
		Kind.MISSILE:
			if _cooldown.is_stopped():
				_launch()
				_cooldown.start()


func _launch() -> void:
	var shot := bullet_scene.instantiate()
	shot.position = _muzzle.global_position
	shot.direction = Vector2.UP
	shot.shooter_id = player_id  # kills are credited to our player
	Game.add_to_world(shot)
	_sprite.play("fire")


## Called by enemy bullets. The shield takes the hit while it has charges.
func take_damage(amount: int, _shooter_id: int) -> void:
	if shield > 0:
		shield -= 1
		_update_shield()
		return
	if _invulnerable:
		return
	hp -= amount
	if hp <= 0:
		_die()
		return
	# Blink while invulnerable, then switch it off again.
	_invulnerable = true
	var blink := create_tween().set_loops(int(hit_invuln_time / 0.2))
	blink.tween_property(_sprite, "modulate:a", 0.3, 0.1)
	blink.tween_property(_sprite, "modulate:a", 1.0, 0.1)
	blink.finished.connect(func(): _invulnerable = false)


func _recharge() -> void:
	if shield < max_shield:
		shield += 1
		_update_shield()


## Shows the charges on the drone's lights, turns the bubble's hitbox on or
## off, and redraws the bubble.
func _update_shield() -> void:
	_sprite.frame = shield  # the "charges" animation: frame 0-3 = 0-3 lights
	# set_deferred: this can run inside a collision callback.
	_bubble.set_deferred("disabled", shield == 0)
	queue_redraw()


## The shield bubble. A node draws itself before its children, so it sits
## behind the drone's sprite.
func _draw() -> void:
	if kind != Kind.SHIELD or shield == 0:
		return
	var strength := float(shield) / max_shield
	draw_circle(Vector2.ZERO, shield_radius, Color(shield_color, 0.12 + 0.12 * strength))
	draw_arc(Vector2.ZERO, shield_radius, 0.0, TAU, 48, Color(shield_color, 0.4 + 0.5 * strength), 2.0, true)


func _die() -> void:
	var boom: Node2D = Enemy.EXPLOSION.instantiate()
	boom.position = global_position
	boom.sound = death_sound
	Game.add_to_world(boom)
	queue_free()
