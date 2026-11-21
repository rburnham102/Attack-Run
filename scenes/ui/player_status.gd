extends VBoxContainer
## One player's status in a bottom corner of the screen: a little plane for
## each life, a row of health and shield blocks, and the special bar.
##
## The HUD has two of these (one per player) and feeds them numbers; this
## script only draws. The blocks and icons are made in code because their
## number changes: one block per point of max health and max armor (shield),
## one icon per life.

## Little plane drawn for each life.
@export var life_icon: Texture2D
@export var life_icon_size := Vector2(28, 20)
## Player 2's icons are tinted blue like their plane.
@export var icon_tint := Color.WHITE
## Line everything up on the right edge instead (player 2's corner).
@export var right_aligned := false

@export_group("Blocks")
@export var block_size := Vector2(22, 12)
@export var health_color := Color(0.95, 0.25, 0.2)
@export var shield_color := Color(0.4, 0.8, 1.0)
@export var empty_color := Color(0.12, 0.12, 0.16, 0.85)

@export_group("Special Bar")
## How bright the full bar pulses (a modulate above 1 brightens).
@export var ready_flash := Color(2.0, 2.0, 2.0)
@export var flash_time := 0.25
@export_group("")

var _blocks: Array[ColorRect] = []
var _life_count := -1
var _flash: Tween

@onready var _lives: HBoxContainer = $Lives
@onready var _health: HBoxContainer = $Health
@onready var _special_bar: ProgressBar = $SpecialBar


func _ready() -> void:
	var align := BoxContainer.ALIGNMENT_END if right_aligned else BoxContainer.ALIGNMENT_BEGIN
	_lives.alignment = align
	_health.alignment = align
	_special_bar.size_flags_horizontal = Control.SIZE_SHRINK_END if right_aligned \
		else Control.SIZE_SHRINK_BEGIN
	# Hidden until the player's plane says it has a special (level 4 on).
	_special_bar.hide()


## Health blocks on the left, shield blocks always on the right: a block per
## point of max_hp, then a block per point of max_armor.
func set_health(hp: int, max_hp: int, armor: int, max_armor: int) -> void:
	if _blocks.size() != max_hp + max_armor:
		_make_blocks(max_hp + max_armor)
	for i in _blocks.size():
		if i < max_hp:
			_blocks[i].color = health_color if i < hp else empty_color
		else:
			_blocks[i].color = shield_color if i - max_hp < armor else empty_color


func _make_blocks(count: int) -> void:
	for block in _blocks:
		block.queue_free()
	_blocks.clear()
	for i in count:
		var block := ColorRect.new()
		block.custom_minimum_size = block_size
		_health.add_child(block)
		_blocks.append(block)


func set_lives(lives: int) -> void:
	# The HUD calls this on every score change too; only rebuild the icons
	# (there are only ever a few) when the number of lives has changed.
	if lives == _life_count:
		return
	_life_count = lives
	for icon in _lives.get_children():
		icon.queue_free()
	for i in lives:
		var icon := TextureRect.new()
		icon.texture = life_icon
		icon.custom_minimum_size = life_icon_size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# The plane art faces down; flipping both ways turns it to face up.
		icon.flip_h = true
		icon.flip_v = true
		icon.modulate = icon_tint
		_lives.add_child(icon)


## charge goes from 0 (just used) to 1 (ready). A full bar pulses.
func set_special(charge: float) -> void:
	_special_bar.show()
	_special_bar.value = charge
	var ready := charge >= 1.0
	if ready and not _flash:
		_flash = create_tween().set_loops()
		_flash.tween_property(_special_bar, "modulate", ready_flash, flash_time)
		_flash.tween_property(_special_bar, "modulate", Color.WHITE, flash_time)
	elif not ready and _flash:
		_flash.kill()
		_flash = null
		_special_bar.modulate = Color.WHITE
