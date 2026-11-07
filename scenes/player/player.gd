extends Area2D
## A player-controlled plane. The same scene is used for both players;
## player_id picks the input actions ("p1_..." or "p2_...").
##
## The player is a child of the Scroller, so its position is in *screen*
## coordinates: (0, 0) is the top-left of the screen. That makes keeping
## it on screen a simple clamp.

@export_range(1, 2) var player_id := 1
@export var speed := 300.0
@export var max_hp := 3
@export var bullet_scene: PackedScene
## Keeps the plane's body from going past the screen edge.
@export var screen_margin := Vector2(36, 36)
## Invulnerability after being hit, and after respawning.
@export var hit_invuln_time := 1.0
@export var respawn_invuln_time := 2.5

var hp := 0
var invulnerable := false

var _prefix := ""
var _spawn_position := Vector2.ZERO
var _blink: Tween

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _muzzle: Marker2D = $Muzzle
@onready var _shot_timer: Timer = $ShotTimer


func _ready() -> void:
	_prefix = "p%d_" % player_id
	_spawn_position = position
	hp = max_hp
	add_to_group("players")
	area_entered.connect(_on_area_entered)
	if player_id == 2:
		_sprite.self_modulate = Color(0.55, 0.8, 2.0)  # blue tint for player 2


func _process(delta: float) -> void:
	var dir := Input.get_vector(_prefix + "left", _prefix + "right", _prefix + "up", _prefix + "down")
	position += dir * speed * delta
	position = position.clamp(screen_margin, get_viewport_rect().size - screen_margin)

	if Input.is_action_pressed(_prefix + "fire") and _shot_timer.is_stopped():
		_shoot()
		_shot_timer.start()


func _shoot() -> void:
	var bullet := bullet_scene.instantiate()
	bullet.position = _muzzle.global_position
	bullet.direction = Vector2.UP
	bullet.shooter_id = player_id
	Game.add_to_world(bullet)


## Called by enemy bullets.
func take_damage(amount: int, _shooter_id: int) -> void:
	if invulnerable:
		return
	hp -= amount
	Game.health_changed.emit(player_id, maxi(hp, 0))
	if hp <= 0:
		_die()
	else:
		_start_invulnerability(hit_invuln_time)


## We collided with an enemy plane: both of us take damage.
func _on_area_entered(area: Area2D) -> void:
	if area is Enemy:
		area.take_damage(99, player_id)
		take_damage(1, 0)


func _die() -> void:
	var boom: Node2D = Enemy.EXPLOSION.instantiate()
	boom.position = global_position
	boom.scale = Vector2(2, 2)
	Game.add_to_world(boom)

	if Game.lose_life(player_id) > 0:
		# Respawn at the start position with full health.
		position = _spawn_position
		hp = max_hp
		Game.health_changed.emit(player_id, hp)
		_start_invulnerability(respawn_invuln_time)
	else:
		queue_free()


## Blinks the plane and ignores damage for a while.
func _start_invulnerability(duration: float) -> void:
	invulnerable = true
	if _blink:
		_blink.kill()
	var blinks := int(duration / 0.2)
	_blink = create_tween().set_loops(blinks)
	_blink.tween_property(_sprite, "modulate:a", 0.25, 0.1)
	_blink.tween_property(_sprite, "modulate:a", 1.0, 0.1)
	_blink.finished.connect(func(): invulnerable = false)
