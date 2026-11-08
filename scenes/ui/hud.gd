extends CanvasLayer
## Shows each player's score, health, lives and power-ups. It never asks the
## players directly; it just listens to the Game autoload's signals.

@onready var _labels: Array[Label] = [$Margin/HBox/P1Label, $Margin/HBox/P2Label]

## Latest stats for each player, as sent by player_stats_changed.
var _stats: Array[Dictionary] = [
	{"hp": 3, "armor": 0, "weapon": 1, "speed": 0},
	{"hp": 3, "armor": 0, "weapon": 1, "speed": 0},
]


func _ready() -> void:
	$Margin/HBox/P2Label.visible = Game.player_count == 2
	Game.score_changed.connect(func(_id, _score): _refresh())
	Game.lives_changed.connect(func(_id, _lives): _refresh())
	Game.player_stats_changed.connect(_on_player_stats_changed)
	_refresh()


func _on_player_stats_changed(player_id: int, stats: Dictionary) -> void:
	_stats[player_id - 1] = stats
	_refresh()


func _refresh() -> void:
	for i in 2:
		var s := _stats[i]
		_labels[i].text = "P%d  %07d\nHP %d   LIVES %d\nGUN %d  ARMOR %d  SPD %d" % [
			i + 1, Game.scores[i], s.hp, Game.lives[i], s.weapon, s.armor, s.speed]
