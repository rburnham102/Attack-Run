extends Control
## Title screen: choose 1 or 2 players. Buttons work with the mouse, or with
## the arrow keys + Enter/Space (Godot's built-in "ui_" actions).

@onready var _one_player: Button = $Center/VBox/OnePlayer
@onready var _two_players: Button = $Center/VBox/TwoPlayers


func _ready() -> void:
	_one_player.pressed.connect(Game.start_new_game.bind(1))
	_two_players.pressed.connect(Game.start_new_game.bind(2))
	_one_player.grab_focus()
