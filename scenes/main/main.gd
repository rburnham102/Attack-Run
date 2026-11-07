extends Node2D
## The game manager: spawns the players and the waves of enemy planes.
## The map itself is handled by ChunkSpawner, and the UI by HUD and GameOver.

@export var player_scene: PackedScene
@export var enemy_plane_scene: PackedScene
## Seconds between waves of planes (a random value in this range).
@export var wave_interval_min := 1.5
@export var wave_interval_max := 3.0
@export var max_planes_per_wave := 4

@onready var _scroller: Node2D = $Scroller
@onready var _camera: Camera2D = $Scroller/Camera2D
@onready var _wave_timer: Timer = $WaveTimer


func _ready() -> void:
	var screen := get_viewport_rect().size
	if Game.player_count == 1:
		_spawn_player(1, Vector2(screen.x * 0.5, screen.y - 140))
	else:
		_spawn_player(1, Vector2(screen.x * 0.33, screen.y - 140))
		_spawn_player(2, Vector2(screen.x * 0.67, screen.y - 140))
	_wave_timer.timeout.connect(_spawn_wave)


func _spawn_player(id: int, screen_pos: Vector2) -> void:
	var player := player_scene.instantiate()
	player.player_id = id
	player.position = screen_pos  # screen coordinates, since the Scroller is its parent
	_scroller.add_child(player)


## Spawns 1 to max_planes_per_wave planes in a V formation just above the screen.
func _spawn_wave() -> void:
	var count := randi_range(1, max_planes_per_wave)
	var spacing := 90.0
	var half_width := spacing * (count - 1) / 2.0
	var screen_width := get_viewport_rect().size.x
	var center_x := randf_range(60.0 + half_width, screen_width - 60.0 - half_width)
	var top := _camera.global_position.y - 60.0

	for i in count:
		var offset := i * spacing - half_width
		var plane := enemy_plane_scene.instantiate()
		# Planes further from the middle start a little higher: a V shape.
		plane.position = Vector2(center_x + offset, top - absf(offset) * 0.5)
		add_child(plane)

	_wave_timer.start(randf_range(wave_interval_min, wave_interval_max))
