extends Control
## Title screen: choose 1 or 2 players. Buttons work with the mouse, or with
## the arrow keys + Enter/Space (Godot's built-in "ui_" actions).
##
## When running from the editor (a debug build), picking players opens the
## dev menu to choose a level. An exported release build skips it and starts
## level 1, so players never see it.

const DEV_MENU_SCENE := "res://scenes/title/dev_menu.tscn"

@onready var _one_player: Button = $Center/VBox/OnePlayer
@onready var _two_players: Button = $Center/VBox/TwoPlayers


func _ready() -> void:
	_one_player.pressed.connect(_choose_players.bind(1))
	_two_players.pressed.connect(_choose_players.bind(2))
	_one_player.grab_focus()


func _choose_players(count: int) -> void:
	# OS.is_debug_build() is true when you press Play in the editor (and in
	# exports made with "Export With Debug" ticked), false in a release export.
	if OS.is_debug_build():
		Game.player_count = count  # the dev menu reads it back
		get_tree().change_scene_to_file(DEV_MENU_SCENE)
	else:
		Game.start_new_game(count)
