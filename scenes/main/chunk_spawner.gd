extends Node2D
## Builds the map by stacking chunk scenes on top of each other as the
## camera scrolls up, and deletes chunks once they scroll off the bottom.
##
## Every chunk scene must be CHUNK_HEIGHT pixels tall, with its origin (0, 0)
## at its top-left corner.
##
## Which chunks to use comes from the level (LevelData), in three phases:
##   intro       - the level's intro chunk, repeated (open ocean in level 1)
##   transition  - the level's transition chunk, placed once (the coastline)
##   fighting    - random picks from the level's chunk list

const CHUNK_HEIGHT := 512.0

@export var camera: Camera2D

## World y of the top edge of the highest chunk placed so far.
var _top_y := 0.0
var _last_chunk: PackedScene
var _level: LevelData
var _in_intro := true
## True after begin_land(), until the transition chunk has been placed.
var _transition_pending := false


## Main calls this from its _ready(). It can't happen in our own _ready():
## children are ready before their parent, so Main wouldn't have picked the
## level yet.
func setup(level: LevelData) -> void:
	_level = level
	_top_y = get_viewport_rect().size.y
	while _top_y > 0.0:
		_place(_pick_chunk())


## The briefing is over: stop repeating the intro chunk. The next chunk is
## the transition (if the level has one), then random level chunks.
func begin_land() -> void:
	_in_intro = false
	_transition_pending = _level.transition_chunk != null
	# Intro chunks waiting above the screen haven't been seen yet, so throw
	# them away. That way the transition chunk goes in right above the top of
	# the screen, instead of after a long stretch of queued-up ocean.
	var screen_top := camera.global_position.y
	for chunk in get_children():
		if chunk.position.y + CHUNK_HEIGHT <= screen_top:
			chunk.queue_free()
			_top_y += CHUNK_HEIGHT


func _process(_delta: float) -> void:
	if not _level:
		return
	var screen_top := camera.global_position.y
	var screen_bottom := screen_top + get_viewport_rect().size.y

	# Keep one full chunk ready above the screen, so enemies already exist
	# before they scroll into view.
	while _top_y > screen_top - CHUNK_HEIGHT:
		_place(_pick_chunk())

	for chunk in get_children():
		if chunk.position.y > screen_bottom:
			chunk.queue_free()


func _place(scene: PackedScene) -> void:
	_top_y -= CHUNK_HEIGHT
	var chunk := scene.instantiate()
	chunk.position = Vector2(0, _top_y)
	add_child(chunk)
	_last_chunk = scene


func _pick_chunk() -> PackedScene:
	if _in_intro and _level.intro_chunk:
		return _level.intro_chunk
	if _transition_pending:
		_transition_pending = false
		return _level.transition_chunk
	# Random chunk, avoiding the same one twice in a row.
	var options := _level.chunks.filter(func(c): return c != _last_chunk)
	if options.is_empty():
		options = _level.chunks
	return options.pick_random()
