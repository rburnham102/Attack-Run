extends Enemy
## The Bomber boss at the end of each stage. Like helicopters it's a child of
## the Scroller, so its position is in screen coordinates.
##
## It flies in (taking no damage), then sweeps side to side and alternates
## between two attacks: an aimed burst and a wide fan of bullets.

const BROKEN_TEXTURE := preload("res://assets/Bomber/Broken/Bomber Broken 01.png")
const BONUS_DROPS := 2
## Two players deal about twice the damage, so the boss gets extra health.
const TWO_PLAYER_HP_SCALE := 1.7

@export var bullet_scene: PackedScene
## Screen position the boss flies to before fighting.
@export var battle_y := 170.0
@export var sweep_left := 150.0
@export var sweep_right := 490.0
@export var sweep_time := 3.5
@export var aimed_burst_count := 6
@export var fan_count := 9
@export var fan_angle := 12.0

var _active := false
var _max_hp := 0
var _next_attack := 0
var _sweep: Tween

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _attack_timer: Timer = $AttackTimer
@onready var _muzzles: Array[Node] = $Muzzles.get_children()


func _ready() -> void:
	super()
	if Game.player_count == 2:
		hp = ceili(hp * TWO_PLAYER_HP_SCALE)
	_max_hp = hp
	_attack_timer.wait_time /= Game.enemy_fire_rate_scale()
	_attack_timer.timeout.connect(_attack)
	Game.boss_health_changed.emit(hp, _max_hp)

	var entry := create_tween()
	entry.tween_property(self, "position:y", battle_y, 3.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	entry.tween_callback(_start_fight)


func _start_fight() -> void:
	_active = true
	_attack_timer.start()
	# An endless back-and-forth sweep. set_loops() with no number loops forever.
	_sweep = create_tween().set_loops()
	_sweep.tween_property(self, "position:x", sweep_right, sweep_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sweep.tween_property(self, "position:x", sweep_left, sweep_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func take_damage(amount: int, shooter_id: int) -> void:
	if not _active:
		return  # can't be hurt while flying in
	super(amount, shooter_id)
	Game.boss_health_changed.emit(maxi(hp, 0), _max_hp)


## Crashing into the boss hurts it a little, not instantly.
func rammed(player_id: int) -> void:
	take_damage(3, player_id)


func _attack() -> void:
	if not Game.nearest_player(global_position):
		return
	if _next_attack == 0:
		var burst := create_tween()
		for i in aimed_burst_count:
			burst.tween_callback(_fire_aimed)
			burst.tween_interval(0.1)
	else:
		_fire_fan()
	_next_attack = 1 - _next_attack


## One shot from each wing gun, aimed at the nearest player.
func _fire_aimed() -> void:
	var target := Game.nearest_player(global_position)
	if not target:
		return
	for muzzle in _muzzles:
		shoot(bullet_scene, muzzle.global_position, target.global_position - muzzle.global_position)


## A fan of bullets spread straight down from the nose.
func _fire_fan() -> void:
	for i in fan_count:
		var angle := deg_to_rad((i - (fan_count - 1) / 2.0) * fan_angle)
		shoot(bullet_scene, global_position + Vector2(0, 50), Vector2.DOWN.rotated(angle))


## Instead of vanishing, the boss breaks apart in a chain of explosions.
func die(shooter_id: int) -> void:
	destroyed = true
	_active = false
	_attack_timer.stop()
	if _sweep:
		_sweep.kill()
	Game.add_score(shooter_id, score_value)
	_sprite.texture = BROKEN_TEXTURE
	# Stop colliding: set_deferred because we may be inside a collision callback.
	set_deferred("monitorable", false)

	var death := create_tween()
	for i in 8:
		death.tween_callback(_small_explosion)
		death.tween_interval(0.15)
	death.tween_property(self, "modulate:a", 0.0, 0.5)
	death.tween_callback(_finish_death)


func _small_explosion() -> void:
	var boom := EXPLOSION.instantiate()
	boom.position = global_position + Vector2(randf_range(-80, 80), randf_range(-40, 40))
	boom.scale = Vector2.ONE * randf_range(1.5, 2.5)
	Game.add_to_world(boom)


func _finish_death() -> void:
	for i in BONUS_DROPS:
		var at := global_position + Vector2((i - 0.5) * 80.0, 0)
		Game.spawn_pickup(Game.random_pickup_kind(Game.BONUS_WEIGHTS), at)
	Game.boss_defeated.emit()
	queue_free()
