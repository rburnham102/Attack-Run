extends Node2D
## Builds the map by stacking chunk scenes on top of each other as the
## camera scrolls up, and deletes chunks once they scroll off the bottom.
##
## Every chunk scene must be CHUNK_HEIGHT pixels tall, with its origin (0, 0)
## at its top-left corner.

const CHUNK_HEIGHT := 512.0

## Used to fill the first screen, so the game starts calm.
@export var start_chunk: PackedScene
## Picked at random after the start. Drag chunk scenes into this list.
@export var chunks: Array[PackedScene] = []
@export var camera: Camera2D

## World y of the top edge of the highest chunk placed so far.
var _top_y := 0.0
var _last_chunk: PackedScene


func _ready() -> void:
	var screen_height := get_viewport_rect().size.y
	_top_y = screen_height
	while _top_y > 0.0:
		_place(start_chunk)


func _process(_delta: float) -> void:
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


## Random chunk, avoiding the same one twice in a row.
func _pick_chunk() -> PackedScene:
	var options := chunks.filter(func(c): return c != _last_chunk)
	if options.is_empty():
		options = chunks
	return options.pick_random()
