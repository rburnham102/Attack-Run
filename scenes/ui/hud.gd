extends CanvasLayer
## Shows each player's score, health and lives. It never asks the players
## directly; it just listens to the Game autoload's signals.

@onready var _labels: Array[Label] = [$Margin/HBox/P1Label, $Margin/HBox/P2Label]

var _hp: Array[int] = [3, 3]


func _ready() -> void:
	$Margin/HBox/P2Label.visible = Game.player_count == 2
	Game.score_changed.connect(func(_id, _score): _refresh())
	Game.lives_changed.connect(func(_id, _lives): _refresh())
	Game.health_changed.connect(_on_health_changed)
	_refresh()


func _on_health_changed(player_id: int, hp: int) -> void:
	_hp[player_id - 1] = hp
	_refresh()


func _refresh() -> void:
	for i in 2:
		_labels[i].text = "P%d  %07d\nHP %d   LIVES %d" % [i + 1, Game.scores[i], _hp[i], Game.lives[i]]
