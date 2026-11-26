extends Control
## Dev menu, shown after the title in debug builds only (see title.gd).
## Pick any level to start on, optionally jumping straight to its bosses.
## In a one-player game, PLAY AS PLAYER 2 flies player 2's plane instead
## (its special, its blue tint and its controls: arrows, Enter, Numpad 0).
##
## The level buttons are made in code from Main's Levels list, so a new
## level added there shows up here automatically.

## Buttons look like the title screen's.
const BUTTON_SIZE := Vector2(460, 52)
const FONT_SIZE := 24

@onready var _levels_box: VBoxContainer = $Center/VBox/Levels
@onready var _skip_to_boss: CheckButton = $Center/VBox/SkipToBoss
@onready var _play_as_p2: CheckButton = $Center/VBox/PlayAsP2
@onready var _back: Button = $Center/VBox/Back

## Main's Levels list, in play order.
var _levels: Array[LevelData] = []


func _ready() -> void:
	_levels = _read_levels()
	for i in _levels.size():
		var button := Button.new()
		button.text = "LEVEL %d  -  %s" % [i + 1, _levels[i].title]
		button.custom_minimum_size = BUTTON_SIZE
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		button.pressed.connect(_start_level.bind(i))
		_levels_box.add_child(button)
	# With two players, both planes are already in the game.
	_play_as_p2.visible = Game.player_count == 1
	_back.pressed.connect(get_tree().change_scene_to_file.bind(Game.TITLE_SCENE))
	if _levels_box.get_child_count() > 0:
		_levels_box.get_child(0).grab_focus()


## Main's Levels list is an @export on the Main scene. Instantiating a scene
## builds its nodes and sets their exported values, but _ready() only runs
## once a node is added to the tree. So we can make a copy, read the list,
## and free it, without starting a game.
func _read_levels() -> Array[LevelData]:
	var main: Node = load(Game.MAIN_SCENE).instantiate()
	var levels: Array[LevelData] = main.levels
	main.free()
	return levels


func _start_level(index: int) -> void:
	# Every boss in the earlier levels would have raised Game.stage (usually
	# by one), so start at that stage: the level is exactly as tough as in a
	# real playthrough.
	var stage := 1
	for i in index:
		for boss in _levels[i].boss_scenes.size():
			stage += _levels[i].stage_up_for(boss)
	var solo_id := 2 if _play_as_p2.button_pressed else 1
	Game.start_new_game(Game.player_count, index, stage,
			_skip_to_boss.button_pressed, solo_id)


## Escape (ui_cancel) goes back to the title, like the BACK button.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back.pressed.emit()
