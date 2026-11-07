extends Enemy
## Flies straight down the screen and takes aimed shots at the nearest player.

@export var speed := 150.0
@export var bullet_scene: PackedScene

@onready var _fire_timer: Timer = $FireTimer
@onready var _on_screen: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var _muzzle: Marker2D = $Muzzle


func _ready() -> void:
	super()  # runs Enemy._ready(), which sets hp
	_on_screen.screen_exited.connect(queue_free)
	_fire_timer.timeout.connect(_on_fire_timer_timeout)
	# Random first delay so a group of planes doesn't fire in unison.
	_fire_timer.start(randf_range(0.4, _fire_timer.wait_time))


func _process(delta: float) -> void:
	position.y += speed * delta


func _on_fire_timer_timeout() -> void:
	var target := Game.nearest_player(global_position)
	# Only shoot while visible, and only at players still below us.
	if target and _on_screen.is_on_screen() and target.global_position.y > global_position.y:
		shoot(bullet_scene, _muzzle.global_position, target.global_position - _muzzle.global_position)
