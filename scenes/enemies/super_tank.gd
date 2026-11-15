extends Boss
## The Super Tank: level 2's final boss, a huge tank bristling with guns.
## Like the Super Bomber, it reuses everything in boss.gd (drive-in, sweep,
## health bar, main gun attacks, death explosions) and adds:
##   - deck turrets (BossTurret) that must ALL be destroyed before the hull
##     can be hurt. Until then the hull is armored: hits on it do nothing,
##     and it's tinted a dull steel colour so the player can see why.
##   - a big main turret that swings to follow the nearest player. The
##     aimed attack fires from its barrel.
##
## It's a ground vehicle, so it sits on the ground_enemies layer: the
## players' planes fly over it instead of ramming it.
##
## The health bar covers the whole tank: hull plus every turret. Each turret
## knocked out takes its share off the bar, so the turret phase shows
## progress even though the hull itself isn't taking damage yet.

## Hull colour while the turrets protect it.
@export var armored_tint := Color(0.5, 0.56, 0.72)
## How fast the main turret swings, in degrees per second.
@export var main_turret_turn_speed := 45.0

var _armored := true

@onready var _turrets: Array[Node] = $Turrets.get_children()
@onready var _main_turret: Sprite2D = $MainTurret
## Boss fires its aimed shots from the markers under Muzzles. Muzzles sits on
## the main turret's pivot, and we turn it along with the turret, so the shots
## always leave from the end of the barrel.
@onready var _muzzle_pivot: Node2D = $Muzzles


func _ready() -> void:
	super()  # runs Boss._ready(): sets hp and starts the drive-in
	for turret in _turrets:
		turret.boss = self
		# The turrets already ran their own _ready() (children are ready
		# before their parent), so their hp is set. Add it to the bar.
		hp += turret.hp
	_max_hp = hp
	Game.boss_health_changed.emit(hp, _max_hp)
	_sprite.self_modulate = armored_tint
	_main_turret.self_modulate = armored_tint


func _start_fight() -> void:
	super()
	for turret in _turrets:
		turret.activate()


func _process(delta: float) -> void:
	if not _active:
		return
	var target := Game.nearest_player(_main_turret.global_position)
	if target:
		# The turret sprite points down (+Y), whose angle is PI/2, so subtract it.
		var wanted := (target.global_position - _main_turret.global_position).angle() - PI / 2
		_main_turret.rotation = rotate_toward(
			_main_turret.rotation, wanted, deg_to_rad(main_turret_turn_speed) * delta)
	_muzzle_pivot.rotation = _main_turret.rotation


## While armored, hits on the hull are simply ignored (the bullet still
## breaks on the armor, so it can't pass through to something behind).
func take_damage(amount: int, shooter_id: int) -> void:
	if _armored:
		return
	super(amount, shooter_id)


## A turret was knocked out: take its health off the bar directly. Calling
## take_damage() here would be blocked by the armor.
func turret_destroyed(turret_hp: int, _shooter_id: int) -> void:
	hp -= turret_hp
	Game.boss_health_changed.emit(maxi(hp, 0), _max_hp)
	_flash()
	# Wrecked turrets stop catching bullets. On the Super Bomber a wreck
	# passes its hits on to the boss, but here the rear turrets sit right
	# behind the front ones, so a front wreck would shield the turret behind
	# it (and while the armor is up, the hits it passed on would be wasted).
	# set_deferred: we may be inside a collision callback.
	for turret in _turrets:
		if turret.destroyed:
			turret.set_deferred("monitorable", false)
	if _armored and _turrets.all(func(t): return t.destroyed):
		_drop_armor()


## Every turret is gone: the hull loses its tint and starts taking damage.
func _drop_armor() -> void:
	_armored = false
	var fade := create_tween().set_parallel()
	fade.tween_property(_sprite, "self_modulate", Color.WHITE, 0.4)
	fade.tween_property(_main_turret, "self_modulate", Color.WHITE, 0.4)


func die(shooter_id: int) -> void:
	for turret in _turrets:
		turret.deactivate()
		turret.set_deferred("monitorable", false)
	_main_turret.self_modulate = Color(0.35, 0.35, 0.35)
	super(shooter_id)
