extends Node
## Global game state. Registered as the "Game" autoload in Project Settings,
## so any script can call Game.add_score(...) etc. It survives scene changes,
## which is why the score and player count live here and not in main.tscn.

signal score_changed(player_id: int, score: int)
signal lives_changed(player_id: int, lives: int)
signal health_changed(player_id: int, hp: int)
signal game_over

const START_LIVES := 3
const MAIN_SCENE := "res://scenes/main/main.tscn"
const TITLE_SCENE := "res://scenes/title/title.tscn"

var player_count := 1
# Index 0 is player 1, index 1 is player 2.
var scores: Array[int] = [0, 0]
var lives: Array[int] = [0, 0]


func start_new_game(count: int) -> void:
	player_count = count
	scores = [0, 0]
	lives = [START_LIVES, START_LIVES if count == 2 else 0]
	get_tree().change_scene_to_file(MAIN_SCENE)


func go_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


func add_score(player_id: int, amount: int) -> void:
	if player_id < 1 or player_id > 2:
		return
	scores[player_id - 1] += amount
	score_changed.emit(player_id, scores[player_id - 1])


## Removes a life and returns how many are left.
func lose_life(player_id: int) -> int:
	var i := player_id - 1
	lives[i] = maxi(lives[i] - 1, 0)
	lives_changed.emit(player_id, lives[i])
	if lives[0] == 0 and lives[1] == 0:
		game_over.emit()
	return lives[i]


## Adds a node (bullet, explosion, enemy) to the current scene.
## Deferred because this is often called from inside a collision signal,
## and Godot doesn't allow adding physics objects while it's processing
## collisions ("Can't change this state while flushing queries").
func add_to_world(node: Node2D) -> void:
	get_tree().current_scene.add_child.call_deferred(node)


## Returns the closest living player to a world position, or null.
func nearest_player(from: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for p in get_tree().get_nodes_in_group("players"):
		var d := from.distance_squared_to(p.global_position)
		if d < best_dist:
			best_dist = d
			best = p
	return best
