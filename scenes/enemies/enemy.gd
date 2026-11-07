class_name Enemy
extends Area2D
## Base class for every enemy. Tanks and planes "extend Enemy", so they all
## share health, scoring, the hit flash and the explosion on death.

const EXPLOSION := preload("res://scenes/effects/explosion.tscn")

@export var max_hp := 3
@export var score_value := 100
## Size of the explosion when this enemy dies.
@export var explosion_scale := 1.5

var hp := 0
var _dead := false


func _ready() -> void:
	hp = max_hp


## Called by bullets (and by a player ramming this enemy).
func take_damage(amount: int, shooter_id: int) -> void:
	if _dead:
		return
	hp -= amount
	if hp <= 0:
		die(shooter_id)
	else:
		_flash()


func die(shooter_id: int) -> void:
	_dead = true
	Game.add_score(shooter_id, score_value)
	var boom := EXPLOSION.instantiate()
	boom.position = global_position
	boom.scale = Vector2.ONE * explosion_scale
	Game.add_to_world(boom)
	queue_free()


## Fires one projectile from a world position in a direction.
func shoot(bullet_scene: PackedScene, from: Vector2, dir: Vector2) -> void:
	var bullet := bullet_scene.instantiate()
	bullet.position = from
	bullet.direction = dir.normalized()
	Game.add_to_world(bullet)


## Brief bright flash so the player can see their hits landing.
func _flash() -> void:
	modulate = Color(2.5, 2.5, 2.5)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.12)
