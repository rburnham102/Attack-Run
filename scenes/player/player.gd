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
## Where drones fly, relative to the plane, in the order they fill up:
## left, right, then a pair further back.
const DRONE_SLOTS: Array[Vector2] = [Vector2(-92, 20), Vector2(92, 20), Vector2(-48, 72), Vector2(48, 72)]
## Shield drones fly out in front instead, so their bubbles catch bullets
## before they reach the plane.
const SHIELD_DRONE_SLOTS: Array[Vector2] = [Vector2(-44, -88), Vector2(44, -88), Vector2(-112, -60), Vector2(112, -60)]

@export_range(1, 2) var player_id := 1
@export var speed := 300.0
## Extra speed per Speed pickup.
@export var speed_per_level := 45.0
@export var max_hp := 3
@export var bullet_scene: PackedScene
## The scene each drone pickup adds.
@export var gun_drone_scene: PackedScene
@export var missile_drone_scene: PackedScene
@export var shield_drone_scene: PackedScene
## Played by the explosion when this plane is shot down.
@export var death_sound: AudioStream
## Keeps the plane's body from going past the screen edge.
@export var screen_margin := Vector2(36, 36)
## Invulnerability after being hit, and after respawning.
@export var hit_invuln_time := 1.5
@export var respawn_invuln_time := 2.5

@export_group("Special")
## Each player has their own special weapon, pressed with "p1_special" or
## "p2_special". The plane adds the one for its player as a child when the
## level allows specials (LevelData > Specials Unlocked). A special scene
## needs an activate() function, a duration and a finished signal.
@export var p1_special_scene: PackedScene
@export var p2_special_scene: PackedScene
## Seconds for the special to charge back up after it's used.
@export var special_recharge := 30.0
@export_group("")

var hp := 0
var armor := 0
var weapon_level := 1
var speed_level := 0
var invulnerable := false
## Set by the laser while it fires: the normal guns hold their fire.
var guns_paused := false
## 0 = normal attack height. 1 = high in the sky (the level intro): the plane
## is drawn twice as big, and its shadow falls further away and fainter, the
## way a real shadow does the higher a plane flies. Main tweens this from 1
## to 0 for the dive at the start of a level.
var altitude := 0.0:
	set(value):
		altitude = value
		if is_node_ready():
			_apply_altitude()

var _prefix := ""
## One entry per DRONE_SLOTS position: the drone flying there, or null.
var _drones: Array[Drone] = [null, null, null, null]
var _spawn_position := Vector2.ZERO
var _blink: Tween
## The Shadow's offset and strength as set in the editor (at altitude 0).
var _shadow_offset := Vector2.ZERO
var _shadow_alpha := 0.0
## Our special weapon (a child node), or null on levels without specials.
var _special: Node = null
## 1 = ready. It drains while the special runs, then refills.
var _special_charge := 1.0
var _special_running := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shadow: Sprite2D = $Shadow
@onready var _muzzle: Marker2D = $Muzzle
@onready var _shot_timer: Timer = $ShotTimer
@onready var _armor_ring: Node2D = $ArmorRing
@onready var _gun_sound: AudioStreamPlayer2D = $GunSound


func _ready() -> void:
	_prefix = "p%d_" % player_id
	_spawn_position = position
	_shadow_offset = _shadow.position
	_shadow_alpha = _shadow.modulate.a
	hp = max_hp
	add_to_group("players")
	area_entered.connect(_on_area_entered)
	if player_id == 2:
		_sprite.self_modulate = Color(0.55, 0.8, 2.0)  # blue tint for player 2
	var special_scene := p1_special_scene if player_id == 1 else p2_special_scene
	if Game.specials_unlocked and special_scene:
		_special = special_scene.instantiate()
		_special.player = self
		add_child(_special)
		_special.finished.connect(_on_special_finished)
		Game.special_charge_changed.emit(player_id, _special_charge)
	_stats_changed()


func _process(delta: float) -> void:
	var dir := Input.get_vector(_prefix + "left", _prefix + "right", _prefix + "up", _prefix + "down")
	position += dir * (speed + speed_level * speed_per_level) * delta
	position = position.clamp(screen_margin, get_viewport_rect().size - screen_margin)

	if Input.is_action_pressed(_prefix + "fire") and _shot_timer.is_stopped() and not guns_paused:
		_shoot()
		_shot_timer.start()

	if _special:
		_update_special(delta)


## Charges the special, drains the bar while it runs, and fires it when the
## button is pressed with a full bar.
func _update_special(delta: float) -> void:
	var before := _special_charge
	if _special_running:
		# The bar empties over the special's run time.
		_special_charge = maxf(_special_charge - delta / _special.duration, 0.0)
	elif _special_charge < 1.0:
		_special_charge = minf(_special_charge + delta / special_recharge, 1.0)
	elif Input.is_action_just_pressed(_prefix + "special"):
		_special_running = true
		_special.activate()
	if _special_charge != before:
		Game.special_charge_changed.emit(player_id, _special_charge)


func _on_special_finished() -> void:
	_special_running = false
	_special_charge = 0.0
	Game.special_charge_changed.emit(player_id, _special_charge)


func _shoot() -> void:
	_gun_sound.play()
	for shot in WEAPON_PATTERNS[weapon_level - 1]:
		var bullet := bullet_scene.instantiate()
		bullet.position = _muzzle.global_position + Vector2(shot[0], 0)
		bullet.direction = Vector2.UP.rotated(deg_to_rad(shot[1]))
		bullet.shooter_id = player_id
		Game.add_to_world(bullet)
	for drone in _drones:
		# is_instance_valid: a drone that was shot down is freed, but our
		# list still points at it.
		if is_instance_valid(drone):
			drone.fire()


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
		Pickup.Kind.DRONE_GUN:
			_add_drone(gun_drone_scene)
		Pickup.Kind.DRONE_MISSILE:
			_add_drone(missile_drone_scene)
		Pickup.Kind.DRONE_SHIELD:
			_add_drone(shield_drone_scene)
	Game.pickup_collected.emit(player_id, kind)
	_stats_changed()


## Puts a new drone in the first free slot. With all four slots taken, the
## pickup is worth points instead.
func _add_drone(scene: PackedScene) -> void:
	var slot := -1
	for i in _drones.size():
		if not is_instance_valid(_drones[i]):
			slot = i
			break
	if slot == -1:
		Game.add_score(player_id, MAXED_OTHER_BONUS)
		return
	var drone: Drone = scene.instantiate()
	drone.player = self
	drone.player_id = player_id
	var slots := SHIELD_DRONE_SLOTS if drone.kind == Drone.Kind.SHIELD else DRONE_SLOTS
	drone.slot_offset = _free_offset(slots)
	drone.position = position + drone.slot_offset
	# Our parent is the Scroller, so the drone works in screen coordinates
	# like we do. It isn't our child, so it can trail behind us smoothly
	# instead of being locked to the plane.
	get_parent().add_child(drone)
	_drones[slot] = drone
	# When it's shot down, update the HUD. call_deferred: it's still on its
	# way out of the tree when tree_exited fires.
	drone.tree_exited.connect(_stats_changed, CONNECT_DEFERRED)



## The first spot in slots that no living drone is flying in.
func _free_offset(slots: Array[Vector2]) -> Vector2:
	for offset in slots:
		var taken := false
		for other in _drones:
			if is_instance_valid(other) and other.slot_offset == offset:
				taken = true
		if not taken:
			return offset
	return slots[0]

func _on_area_entered(area: Area2D) -> void:
	if area is Pickup:
		if area.try_collect():
			collect(area.kind)
	elif area is Enemy:
		# We collided with an enemy plane: both of us take damage.
		area.rammed(player_id)
		take_damage(1, 0)


func _die() -> void:
	var boom: Node2D = Enemy.EXPLOSION.instantiate()
	boom.position = global_position
	boom.scale = Vector2(2, 2)
	boom.sound = death_sound
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


## The spot this plane starts the level from, and respawns at.
func get_spawn_position() -> Vector2:
	return _spawn_position


func _apply_altitude() -> void:
	# Scaling the whole plane also scales the Shadow (it's a child), which
	# already pushes it twice as far out. The extra factor here exaggerates
	# that a bit more, and the shadow fades as the plane climbs.
	scale = Vector2.ONE * (1.0 + altitude)
	_shadow.position = _shadow_offset * (1.0 + altitude)
	_shadow.modulate.a = _shadow_alpha * (1.0 - 0.6 * altitude)


## Tells the HUD (through the Game autoload) and the armor ring what changed.
func _stats_changed() -> void:
	_armor_ring.level = armor
	Game.player_stats_changed.emit(player_id, {
		"hp": maxi(hp, 0),
		"max_hp": max_hp,
		"armor": armor,
		"max_armor": MAX_ARMOR,
		"weapon": weapon_level,
		"speed": speed_level,
		"drones": _drone_letters(),
	})


## The drones we have, as letters for the HUD: "G M S", or "" for none.
func _drone_letters() -> String:
	var letters := PackedStringArray()
	for drone in _drones:
		if is_instance_valid(drone) and not drone.is_queued_for_deletion():
			letters.append(["G", "M", "S"][drone.kind])
	return " ".join(letters)


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
