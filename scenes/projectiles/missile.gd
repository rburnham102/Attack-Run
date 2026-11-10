extends Enemy
## A homing missile fired from the Super Bomber's wing pods.
##
## It's an Enemy rather than a bullet so the existing collision rules do all
## the work: it sits on the air_enemies layer, so player bullets can shoot it
## down, and a player who flies into it "rams" it and takes 1 damage, just
## like crashing into an enemy plane.
##
## While it has fuel it steers toward the nearest player, but only turn_speed
## degrees per second, so a quick sideways dodge can shake it off. Out of fuel
## it flies straight, and after lifetime seconds it blows itself up.

@export var speed := 210.0
## How fast it can turn toward its target, in degrees per second.
@export var turn_speed := 130.0
## Seconds of homing before it just flies straight.
@export var fuel_time := 3.0
@export var lifetime := 6.0

## Set by whoever fires the missile (Enemy.shoot), like a bullet's direction.
var direction := Vector2.DOWN

var _fuel := 0.0


func _ready() -> void:
	super()
	_fuel = fuel_time
	rotation = direction.angle() + PI / 2
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	get_tree().create_timer(lifetime, false).timeout.connect(_self_destruct)


func _process(delta: float) -> void:
	_fuel -= delta
	var target := Game.nearest_player(global_position)
	if _fuel > 0.0 and target:
		# Same idea as a tank turret: turn a limited amount toward the target
		# each frame, rather than snapping straight at it.
		var wanted := (target.global_position - global_position).angle()
		var angle := rotate_toward(direction.angle(), wanted, deg_to_rad(turn_speed) * delta)
		direction = Vector2.from_angle(angle)
	position += direction * speed * delta
	# The sprite points up, and Vector2.UP has an angle of -PI/2 (see bullet.gd).
	rotation = direction.angle() + PI / 2


## Flying into a missile destroys it, but nobody scores for getting hit.
func rammed(_player_id: int) -> void:
	take_damage(999, 0)


func _self_destruct() -> void:
	if not destroyed:
		die(0)  # shooter 0 = no one, so no points are given
