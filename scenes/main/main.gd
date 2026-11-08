extends Node2D
## The game manager: spawns the players, waves of planes, helicopters and the
## boss, and runs the stage cycle:
##   stage_length seconds of waves -> boss fight -> next stage (harder) -> ...
## The map itself is handled by ChunkSpawner, and the UI by HUD and GameOver.

@export var player_scene: PackedScene
@export var enemy_plane_scene: PackedScene
@export var helicopter_scene: PackedScene
@export var boss_scene: PackedScene
## Seconds of normal waves before the boss arrives.
@export var stage_length := 90.0
## Seconds between waves of planes on stage 1 (a random value in this range).
@export var wave_interval_min := 2.5
@export var wave_interval_max := 4.5
@export var max_planes_per_wave := 3
## Seconds between helicopters on stage 1.
@export var helicopter_interval_min := 14.0
@export var helicopter_interval_max := 20.0
## Pause before the boss appears (while WARNING shows), and after it dies.
@export var boss_delay := 3.0

@onready var _scroller: Node2D = $Scroller
@onready var _camera: Camera2D = $Scroller/Camera2D
@onready var _wave_timer: Timer = $WaveTimer
@onready var _helicopter_timer: Timer = $HelicopterTimer
@onready var _stage_timer: Timer = $StageTimer


func _ready() -> void:
	var screen := get_viewport_rect().size
	if Game.player_count == 1:
		_spawn_player(1, Vector2(screen.x * 0.5, screen.y - 140))
	else:
		_spawn_player(1, Vector2(screen.x * 0.33, screen.y - 140))
		_spawn_player(2, Vector2(screen.x * 0.67, screen.y - 140))
	_wave_timer.timeout.connect(_spawn_wave)
	_helicopter_timer.timeout.connect(_spawn_helicopter)
	_stage_timer.timeout.connect(_on_stage_timer_timeout)
	Game.boss_defeated.connect(_on_boss_defeated)
	_start_stage()


func _spawn_player(id: int, screen_pos: Vector2) -> void:
	var player := player_scene.instantiate()
	player.player_id = id
	player.position = screen_pos  # screen coordinates, since the Scroller is its parent
	_scroller.add_child(player)


func _start_stage() -> void:
	Game.stage_started.emit(Game.stage)
	_stage_timer.start(stage_length)
	_wave_timer.start(3.0)
	_helicopter_timer.start(_helicopter_wait())


## Waves come more often on later stages. Each stage divides the wait by a
## bigger number: 1.0, 1.15, 1.3...
func _difficulty() -> float:
	return 1.0 + 0.15 * (Game.stage - 1)


func _helicopter_wait() -> float:
	return randf_range(helicopter_interval_min, helicopter_interval_max) / _difficulty()


## Spawns planes in a V formation just above the screen. Later stages send
## bigger waves (up to 6 planes).
func _spawn_wave() -> void:
	var biggest := mini(max_planes_per_wave + Game.stage - 1, 6)
	var count := randi_range(1, biggest)
	var spacing := 90.0
	var half_width := spacing * (count - 1) / 2.0
	var screen_width := get_viewport_rect().size.x
	var center_x := randf_range(60.0 + half_width, screen_width - 60.0 - half_width)
	var top := _camera.global_position.y - 60.0

	# The planes become children of a Wave node, which drops a bonus pickup
	# if they are all shot down.
	var wave := Wave.new()
	add_child(wave)
	for i in count:
		var offset := i * spacing - half_width
		var plane := enemy_plane_scene.instantiate()
		# Planes further from the middle start a little higher: a V shape.
		plane.position = Vector2(center_x + offset, top - absf(offset) * 0.5)
		wave.add_plane(plane)

	_wave_timer.start(randf_range(wave_interval_min, wave_interval_max) / _difficulty())


func _spawn_helicopter() -> void:
	var heli := helicopter_scene.instantiate()
	heli.position = Vector2(randf_range(80.0, get_viewport_rect().size.x - 80.0), -80.0)
	_scroller.add_child(heli)  # screen coordinates, like the players
	_helicopter_timer.start(_helicopter_wait())


## Time's up: stop the waves, warn the players, then bring in the boss.
func _on_stage_timer_timeout() -> void:
	_wave_timer.stop()
	_helicopter_timer.stop()
	Game.boss_incoming.emit()
	# connect() instead of await: if this scene is freed first (back to the
	# title), Godot drops the connection and nothing runs on a freed node.
	get_tree().create_timer(boss_delay, false).timeout.connect(_spawn_boss)


func _spawn_boss() -> void:
	var boss := boss_scene.instantiate()
	boss.position = Vector2(get_viewport_rect().size.x / 2, -150.0)
	_scroller.add_child(boss)


func _on_boss_defeated() -> void:
	Game.stage += 1
	get_tree().create_timer(boss_delay, false).timeout.connect(_start_stage)
