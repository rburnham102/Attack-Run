class_name Wave
extends Node2D
## Groups the planes of one wave. Planes are added as children, so the scene
## tree itself tracks who is left. If every plane in a big enough wave is
## shot down (none escape), a guaranteed pickup drops where the last one fell.

## Waves smaller than this never give a bonus.
@export var bonus_min_size := 3

var _size := 0
var _all_destroyed := true


func _ready() -> void:
	child_exiting_tree.connect(_on_child_exiting_tree)


func add_plane(plane: Enemy) -> void:
	add_child(plane)
	_size += 1


func _on_child_exiting_tree(plane: Node) -> void:
	if not plane.destroyed:
		_all_destroyed = false
	# The leaving child still counts here, so 1 means it's the last one.
	if get_child_count() > 1:
		return
	if _all_destroyed and _size >= bonus_min_size:
		Game.spawn_pickup(Game.random_pickup_kind(Game.BONUS_WEIGHTS), plane.global_position)
	queue_free()
