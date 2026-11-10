extends Boss
## The Super Bomber: the Bomber's big brother. It reuses everything from
## boss.gd (fly-in, sweep, health bar, nose gun attacks, death explosions)
## and adds:
##   - two gun turrets (BossTurret) that can be shot off separately
##   - a homing missile from each wing pod every MissileTimer seconds
##
## Its hull hitbox leaves a gap under each turret, so bullets aimed at a
## turret reach it instead of being stopped by the wing in front of it.

@export var missile_scene: PackedScene
## Missiles leave the pods angled this many degrees outward, so they swing in
## from the sides instead of flying straight down into the player's bullets.
@export var missile_launch_angle := 40.0

@onready var _missile_timer: Timer = $MissileTimer
@onready var _missile_sound: AudioStreamPlayer2D = $MissileSound
@onready var _pods: Array[Node] = $MissilePods.get_children()
@onready var _turrets: Array[Node] = $Turrets.get_children()


func _ready() -> void:
	super()  # runs Boss._ready(), which starts the fly-in
	_missile_timer.wait_time /= Game.enemy_fire_rate_scale()
	_missile_timer.timeout.connect(_launch_missiles)
	for turret in _turrets:
		turret.boss = self


## Boss calls this when the fly-in ends. We add our own weapons on top.
func _start_fight() -> void:
	super()
	_missile_timer.start()
	for turret in _turrets:
		turret.activate()


func _launch_missiles() -> void:
	if not Game.nearest_player(global_position):
		return
	_missile_sound.play()
	for pod in _pods:
		# -1 for the left pod, +1 for the right. Rotating DOWN by a positive
		# angle turns it toward the left of the screen, hence the minus.
		var side := signf(pod.position.x)
		var dir := Vector2.DOWN.rotated(deg_to_rad(missile_launch_angle) * -side)
		shoot(missile_scene, pod.global_position, dir)


func die(shooter_id: int) -> void:
	_missile_timer.stop()
	for turret in _turrets:
		turret.deactivate()
		turret.set_deferred("monitorable", false)
	super(shooter_id)
