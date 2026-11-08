extends CanvasLayer
## Shows each player's score, health, lives and power-ups, the stage number,
## the boss health bar and big center-screen banners. It never asks other
## nodes for anything; it just listens to the Game autoload's signals.

@onready var _labels: Array[Label] = [$Margin/HBox/P1Label, $Margin/HBox/P2Label]
@onready var _stage_label: Label = $Margin/HBox/Center/StageLabel
@onready var _boss_bar: ProgressBar = $Margin/HBox/Center/BossBar
@onready var _banner: Label = $Banner

## Latest stats for each player, as sent by player_stats_changed.
var _stats: Array[Dictionary] = [
	{"hp": 3, "armor": 0, "weapon": 1, "speed": 0},
	{"hp": 3, "armor": 0, "weapon": 1, "speed": 0},
]
var _banner_tween: Tween


func _ready() -> void:
	$Margin/HBox/P2Label.modulate.a = 1.0 if Game.player_count == 2 else 0.0
	_boss_bar.hide()
	_banner.hide()
	Game.score_changed.connect(func(_id, _score): _refresh())
	Game.lives_changed.connect(func(_id, _lives): _refresh())
	Game.player_stats_changed.connect(_on_player_stats_changed)
	Game.stage_started.connect(_on_stage_started)
	Game.boss_incoming.connect(_on_boss_incoming)
	Game.boss_health_changed.connect(_on_boss_health_changed)
	Game.boss_defeated.connect(_on_boss_defeated)
	_refresh()


func _on_player_stats_changed(player_id: int, stats: Dictionary) -> void:
	_stats[player_id - 1] = stats
	_refresh()


func _refresh() -> void:
	for i in 2:
		var s := _stats[i]
		_labels[i].text = "P%d  %07d\nHP %d   LIVES %d\nGUN %d  ARMOR %d  SPD %d" % [
			i + 1, Game.scores[i], s.hp, Game.lives[i], s.weapon, s.armor, s.speed]


func _on_stage_started(stage: int) -> void:
	_stage_label.text = "STAGE %d" % stage
	_show_banner("STAGE %d" % stage, Color(1, 0.85, 0.3))


func _on_boss_incoming() -> void:
	_show_banner("WARNING!", Color(1, 0.3, 0.25), 3)


func _on_boss_health_changed(hp: int, max_hp: int) -> void:
	_boss_bar.max_value = max_hp
	_boss_bar.value = hp
	_boss_bar.show()


func _on_boss_defeated() -> void:
	_boss_bar.hide()
	_show_banner("BOSS DESTROYED", Color(0.6, 1, 0.6))


## Fades a big message in and out in the middle of the screen.
## blinks > 1 flashes it that many times (used for the boss warning).
func _show_banner(text: String, color: Color, blinks := 1) -> void:
	_banner.text = text
	_banner.label_settings.font_color = color
	_banner.modulate.a = 0.0
	_banner.show()
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	for i in blinks:
		_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.25)
		_banner_tween.tween_interval(0.6 if blinks > 1 else 1.5)
		_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.4)
	_banner_tween.tween_callback(_banner.hide)
