extends Area2D
## A player-controlled plane. The same scene is used for both players;
## player_id picks the input actions ("p1_..." or "p2_...").
##
## The player is a child of the Scroller, so its position is in *screen*
## coordinates: (0, 0) is the top-left of the screen. That makes keeping
## it on screen a simple clamp.

## Each weapon level is a list of shots, and each shot is
## [sideways offset in pixels, angle in degrees]. Negative angles lean left.
const WEAPON_PATTERNS := [
	[[0, 0]],
	[[-8, 0], [8, 0]],
	[[0, 0], [-6, -10], [6, 10]],
	[[-8, 0], [8, 0], [-12, -12], [12, 12]],
	[[0, 0], [-8, -8], [8, 8], [-14, -18], [14, 18]],
]
const MAX_WEAPON_LEVEL := 5
const MAX_SPEED_LEVEL := 2
const MAX_ARMOR := 3
## Points given instead, when a pickup can't improve you any further.
const MAXED_WEAPON_BONUS := 500
const MAXED_OTHER_BONUS := 200
const MONEY_SMALL := 100
const MONEY_BIG := 500

@export_range(1, 2) var player_id := 1
@export var speed := 300.0
## Extra speed per Speed pickup.
@export var speed_per_level := 45.0
@export var max_hp := 3
@export var bullet_scene: PackedScene
## Keeps the plane's body from going past the screen edge.
@export var screen_margin := Vector2(36, 36)
## Invulnerability after being hit, and after respawning.
@export var hit_invuln_time := 1.0
@export var respawn_invuln_time := 2.5

var hp := 0
var armor := 0
var weapon_level := 1
var speed_level := 0
var invulnerable := false

var _prefix := ""
var _spawn_position := Vector2.ZERO
var _blink: Tween

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _muzzle: Marker2D = $Muzzle
@onready var _shot_timer: Timer = $ShotTimer
@onready var _armor_ring: Node2D = $ArmorRing


func _ready() -> void:
	_prefix = "p%d_" % player_id
	_spawn_position = position
	hp = max_hp
	add_to_group("players")
	area_entered.connect(_on_area_entered)
	if player_id == 2:
		_sprite.self_modulate = Color(0.55, 0.8, 2.0)  # blue tint for player 2
	_stats_changed()


func _process(delta: float) -> void:
	var dir := Input.get_vector(_prefix + "left", _prefix + "right", _prefix + "up", _prefix + "down")
	position += dir * (speed + speed_level * speed_per_level) * delta
	position = position.clamp(screen_margin, get_viewport_rect().size - screen_margin)

	if Input.is_action_pressed(_prefix + "fire") and _shot_timer.is_stopped():
		_shoot()
		_shot_timer.start()


func _shoot() -> void:
	for shot in WEAPON_PATTERNS[weapon_level - 1]:
		var bullet := bullet_scene.instantiate()
		bullet.position = _muzzle.global_position + Vector2(shot[0], 0)
		bullet.direction = Vector2.UP.rotated(deg_to_rad(shot[1]))
		bullet.shooter_id = player_id
		Game.add_to_world(bullet)


## Called by enemy bullets. Armor absorbs a hit before HP does.
func take_damage(amount: int, _shooter_id: int) -> void:
	if invulnerable:
		return
	if armor > 0:
		armor -= 1
	else:
		hp -= amount
	_stats_changed()
	if hp <= 0:
		_die()
	else:
		_start_invulnerability(hit_invuln_time)


func collect(kind: Pickup.Kind) -> void:
	match kind:
		Pickup.Kind.WEAPON:
			if weapon_level < MAX_WEAPON_LEVEL:
				weapon_level += 1
			else:
				Game.add_score(player_id, MAXED_WEAPON_BONUS)
		Pickup.Kind.HEALTH:
			if hp < max_hp:
				hp += 1
			else:
				Game.add_score(player_id, MAXED_OTHER_BONUS)
		Pickup.Kind.ARMOR:
			if armor < MAX_ARMOR:
				armor += 1
			else:
				Game.add_score(player_id, MAXED_OTHER_BONUS)
		Pickup.Kind.SPEED:
			if speed_level < MAX_SPEED_LEVEL:
				speed_level += 1
			else:
				Game.add_score(player_id, MAXED_OTHER_BONUS)
		Pickup.Kind.MONEY_SMALL:
			Game.add_score(player_id, MONEY_SMALL)
		Pickup.Kind.MONEY_BIG:
			Game.add_score(player_id, MONEY_BIG)
	Game.pickup_collected.emit(player_id, kind)
	_stats_changed()


func _on_area_entered(area: Area2D) -> void:
	if area is Pickup:
		if area.try_collect():
			collect(area.kind)
	elif area is Enemy:
		# We collided with an enemy plane: both of us take damage.
		area.take_damage(99, player_id)
		take_damage(1, 0)


func _die() -> void:
	var boom: Node2D = Enemy.EXPLOSION.instantiate()
	boom.position = global_position
	boom.scale = Vector2(2, 2)
	Game.add_to_world(boom)

	# Dying costs one level of weapon and speed, and all armor.
	weapon_level = maxi(weapon_level - 1, 1)
	speed_level = maxi(speed_level - 1, 0)
	armor = 0

	if Game.lose_life(player_id) > 0:
		# Respawn at the start position with full health.
		position = _spawn_position
		hp = max_hp
		_stats_changed()
		_start_invulnerability(respawn_invuln_time)
	else:
		queue_free()


## Tells the HUD (through the Game autoload) and the armor ring what changed.
func _stats_changed() -> void:
	_armor_ring.level = armor
	Game.player_stats_changed.emit(player_id, {
		"hp": maxi(hp, 0),
		"armor": armor,
		"weapon": weapon_level,
		"speed": speed_level,
	})


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
