extends Enemy
## Flies in from the top, hovers while firing bursts at the nearest player,
## then peels off the side of the screen.
##
## Helicopters are children of the Scroller (like the players), so their
## position is in screen coordinates and "hover at y = 200" stays on screen.
## The whole flight path is one Tween: a list of steps that run in order.

@export var bullet_scene: PackedScene
@export var hover_time := 5.0
## Degrees per second.
@export var rotor_speed := 1080.0
@export var burst_count := 3
@export var burst_delay := 0.12

@onready var _rotor: Sprite2D = $Rotor
@onready var _muzzle: Marker2D = $Muzzle
@onready var _fire_timer: Timer = $FireTimer


func _ready() -> void:
	super()
	_fire_timer.timeout.connect(_fire_burst)

	var screen := get_viewport_rect().size
	var hover := Vector2(position.x, randf_range(140.0, 320.0))
	# Leave toward whichever side is closer.
	var exit_x := -140.0 if position.x < screen.x / 2 else screen.x + 140.0

	var path := create_tween()
	path.tween_property(self, "position", hover, 2.0) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	path.tween_callback(_fire_timer.start)
	path.tween_interval(hover_time)
	path.tween_callback(_fire_timer.stop)
	path.tween_property(self, "position", Vector2(exit_x, hover.y + 160.0), 2.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	path.tween_callback(queue_free)


func _process(delta: float) -> void:
	_rotor.rotation += deg_to_rad(rotor_speed) * delta


func _fire_burst() -> void:
	var burst := create_tween()
	for i in burst_count:
		burst.tween_callback(_fire_once)
		burst.tween_interval(burst_delay)


func _fire_once() -> void:
	var target := Game.nearest_player(global_position)
	if target:
		shoot(bullet_scene, _muzzle.global_position, target.global_position - _muzzle.global_position)
