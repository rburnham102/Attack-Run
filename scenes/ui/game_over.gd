extends CanvasLayer
## Hidden until Game emits game_over. Then it pauses the game and waits for
## Enter/Space. Its Process Mode is "Always", so it keeps running while the
## rest of the game is paused.

var _can_continue := false

@onready var _scores: Label = $Center/VBox/Scores


func _ready() -> void:
	hide()
	Game.game_over.connect(_on_game_over)


func _on_game_over() -> void:
	# Let the last explosion play out before freezing everything.
	await get_tree().create_timer(1.0).timeout
	get_tree().paused = true
	var text := "P1  %07d" % Game.scores[0]
	if Game.player_count == 2:
		text += "\nP2  %07d" % Game.scores[1]
	_scores.text = text
	show()
	# A short delay so a held fire key doesn't skip this screen instantly.
	await get_tree().create_timer(1.0).timeout
	_can_continue = true


func _unhandled_input(event: InputEvent) -> void:
	if _can_continue and event.is_action_pressed("ui_accept"):
		Game.go_to_title()
