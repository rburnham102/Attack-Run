extends Node2D
## The game manager for one level: plays the intro and briefing, then spawns
## the waves of planes, helicopters and the bosses:
##   intro -> [stage_length seconds of waves -> boss] x number of bosses -> next level
## What changes from level to level (briefing, map, bosses) comes from a
## LevelData resource in the Levels list. The map itself is handled by
## ChunkSpawner, and the UI by HUD, Briefing, Radio and GameOver.

@export var player_scene: PackedScene
@export var enemy_plane_scene: PackedScene
@export var helicopter_scene: PackedScene
## Every level in play order. Game.level_index picks which one is running.
@export var levels: Array[LevelData] = []
## Seconds between waves of planes on stage 1 (a random value in this range).
@export var wave_interval_min := 2.5
@export var wave_interval_max := 4.5
@export var max_planes_per_wave := 3
## Seconds between helicopters on stage 1.
@export var helicopter_interval_min := 14.0
@export var helicopter_interval_max := 20.0
## Pause before the boss appears (while WARNING shows), and after it dies.
@export var boss_delay := 3.0
## Seconds between the last end-of-mission radio line and the next level
## loading.
@export var level_end_delay := 2.0
## Seconds of waves before each boss when the dev menu's "Start at boss"
## is ticked (instead of the level's Stage Length).
@export var dev_stage_length := 3.0
## Seconds before a boss arrives that the map starts using the level's chunk
## for that boss (LevelData > Boss Chunks), so whatever is on screen,
## even a tall coastline, has scrolled away by the time the boss shows up.
@export var boss_chunk_lead := 40.0
## Seconds after a boss dies before the comms officer reports it, so her box
## doesn't hide the bonus pickups dropping where the boss was.
@export var radio_defeated_delay := 1.0

@export_group("Intro")
## The planes' screen height while the general talks (0.5 = middle).
@export_range(0.0, 1.0) var briefing_height := 0.42
## Seconds to climb from below the screen up to briefing_height.
@export var climb_time := 3.0
## Seconds to shrink down to attack size and drop to the start positions.
@export var dive_time := 2.5
## Top scroll speed during the dive, so the coastline sweeps into view fast.
@export var dive_scroll_speed := 1000.0
@export_group("")

var _level: LevelData
## Index in _level.boss_scenes of the next boss to fight.
var _boss_index := 0
var _players: Array[Node2D] = []

@onready var _scroller: Node2D = $Scroller
@onready var _camera: Camera2D = $Scroller/Camera2D
@onready var _wave_timer: Timer = $WaveTimer
@onready var _helicopter_timer: Timer = $HelicopterTimer
@onready var _stage_timer: Timer = $StageTimer
@onready var _chunk_spawner: Node2D = $ChunkSpawner
@onready var _hud: CanvasLayer = $HUD
@onready var _briefing: CanvasLayer = $Briefing
@onready var _radio: CanvasLayer = $Radio


func _ready() -> void:
	_level = levels[Game.level_index]
	# The level can swap in its own planes and helicopters (level 3's white
	# winter ones). Empty means keep the defaults set on this node.
	Game.drones_unlocked = _level.drones_unlocked
	# Before the players spawn: they check this when they're created.
	Game.specials_unlocked = _level.specials_unlocked
	if _level.enemy_plane_scene:
		enemy_plane_scene = _level.enemy_plane_scene
	if _level.helicopter_scene:
		helicopter_scene = _level.helicopter_scene
	_chunk_spawner.setup(_level)
	_radio.level = _level
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
	_play_intro()


func _spawn_player(id: int, screen_pos: Vector2) -> void:
	var player := player_scene.instantiate()
	player.player_id = id
	player.position = screen_pos  # screen coordinates, since the Scroller is its parent
	_scroller.add_child(player)
	_players.append(player)


## The level opening, written top to bottom with await: each await waits for
## a tween or signal to finish before moving to the next step.
##   1. The planes climb up from below the screen, big (high in the sky).
##   2. The general gives the briefing.
##   3. The planes shrink and drop to their start spots (the dive), while the
##      scroll speeds up so the coastline rushes into view.
##   4. Controls on, HUD on, first stage starts.
func _play_intro() -> void:
	var screen := get_viewport_rect().size
	_hud.hide()
	for player in _players:
		# set_process(false) stops player.gd's _process(), so no moving or
		# shooting until the intro is over.
		player.set_process(false)
		player.altitude = 1.0
		player.position.y = screen.y + 120.0

	var climb := create_tween().set_parallel()
	for player in _players:
		climb.tween_property(player, "position:y", screen.y * briefing_height, climb_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await climb.finished

	_briefing.start(_level)
	await _briefing.finished

	_chunk_spawner.begin_land()
	var dive := create_tween().set_parallel()
	for player in _players:
		dive.tween_property(player, "altitude", 0.0, dive_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		dive.tween_property(player, "position", player.get_spawn_position(), dive_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Speed the scrolling up and back down again (two steps in a row, so this
	# one is a separate tween that isn't parallel).
	var normal_speed: float = _scroller.scroll_speed
	var surge := create_tween()
	surge.tween_property(_scroller, "scroll_speed", dive_scroll_speed, dive_time * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	surge.tween_property(_scroller, "scroll_speed", normal_speed, dive_time * 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await dive.finished

	for player in _players:
		player.set_process(true)
	_hud.show()
	Game.level_started.emit(Game.level_index + 1, _level.title)
	_start_stage()


func _start_stage() -> void:
	Game.stage_started.emit(_boss_index + 1, _level.boss_scenes.size())
	var length := dev_stage_length if Game.dev_skip_to_boss \
		else _level.stage_length_for(_boss_index)
	_stage_timer.start(length)
	get_tree().create_timer(maxf(length - boss_chunk_lead, 0.0), false) \
		.timeout.connect(_switch_to_boss_chunk)
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


## If the level has a chunk for the coming boss, the map switches to it.
func _switch_to_boss_chunk() -> void:
	if _boss_index < _level.boss_chunks.size() and _level.boss_chunks[_boss_index]:
		_chunk_spawner.use_boss_chunk(_level.boss_chunks[_boss_index])


## Time's up: stop the waves, warn the players, then bring in the boss.
func _on_stage_timer_timeout() -> void:
	_wave_timer.stop()
	_helicopter_timer.stop()
	Game.boss_incoming.emit()
	_switch_to_boss_chunk()  # in case the stage was shorter than the lead
	_radio.say(_radio_line(_level.boss_warnings))
	# connect() instead of await: if this scene is freed first (back to the
	# title), Godot drops the connection and nothing runs on a freed node.
	get_tree().create_timer(boss_delay, false).timeout.connect(_spawn_boss)


## This boss's line from one of the level's Radio lists, as a radio call
## (a list of lines) holding just that line. The list is empty (silence) if
## the level doesn't have a line for this boss.
func _radio_line(lines: Array[RadioLine]) -> Array[RadioLine]:
	var lines_out: Array[RadioLine] = []
	if _boss_index < lines.size() and lines[_boss_index]:
		lines_out.append(lines[_boss_index])
	return lines_out


func _spawn_boss() -> void:
	var boss := _level.boss_scenes[_boss_index].instantiate()
	boss.position = Vector2(get_viewport_rect().size.x / 2, -150.0)
	_scroller.add_child(boss)


func _on_boss_defeated() -> void:
	# Before _boss_index goes up, so we get the line for the boss just beaten.
	var lines := _radio_line(_level.boss_defeated_lines)
	Game.stage += _level.stage_up_for(_boss_index)
	_boss_index += 1
	_chunk_spawner.use_boss_chunk(null)
	if _boss_index < _level.boss_scenes.size():
		_radio.say(lines, radio_defeated_delay)
		get_tree().create_timer(boss_delay, false).timeout.connect(_start_stage)
	else:
		# The last boss: its line, then the end-of-mission chatter.
		lines.append_array(_level.mission_complete_lines)
		_finish_level(lines)


## Last boss down. Players can't be hurt any more (stray ground fire). The
## final radio call plays, and once it's over (plus a short pause) the next
## level loads, or the campaign is won.
func _finish_level(lines: Array[RadioLine]) -> void:
	for player in get_tree().get_nodes_in_group("players"):
		player.invulnerable = true
	Game.level_complete.emit()
	# CONNECT_ONE_SHOT disconnects after the first time, so a radio call
	# later on (there isn't one now, but there could be) can't load the next
	# level twice.
	_radio.finished.connect(_on_final_call_finished, CONNECT_ONE_SHOT)
	_radio.say(lines, radio_defeated_delay)


func _on_final_call_finished() -> void:
	get_tree().create_timer(level_end_delay, false).timeout.connect(_go_to_next_level)


func _go_to_next_level() -> void:
	if Game.level_index + 1 < levels.size():
		Game.go_to_next_level()
	else:
		Game.campaign_complete.emit()
