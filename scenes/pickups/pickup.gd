class_name Pickup
extends Area2D
## A power-up floating over the battlefield. The player who touches it calls
## try_collect(), and if that succeeds the player applies the effect.
## One scene covers every kind: choosing a kind just swaps the icon.

enum Kind { WEAPON, HEALTH, ARMOR, SPEED, MONEY_SMALL, MONEY_BIG }

const ICONS := {
	Kind.WEAPON: preload("res://upgrades/Ammo/Ammo.png"),
	Kind.HEALTH: preload("res://upgrades/HP/HP.png"),
	Kind.ARMOR: preload("res://upgrades/Armor/Armor.png"),
	Kind.SPEED: preload("res://upgrades/Speed/Iocn_Speed_01.png"),
	Kind.MONEY_SMALL: preload("res://upgrades/Money/Money Small.png"),
	Kind.MONEY_BIG: preload("res://upgrades/Money/Money Big.png"),
}

@export var kind := Kind.WEAPON
## Extra downward drift on top of the map scrolling, so pickups don't linger.
@export var fall_speed := 30.0
## Soft disc drawn behind the icon so pickups stand out against the ground.
@export var glow_radius := 28.0
@export var glow_color := Color(1.0, 0.95, 0.6, 0.45)

var _taken := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.texture = ICONS[kind]
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	# Gentle pulse so pickups stand out from the scenery.
	var base := _sprite.scale
	var pulse := create_tween().set_loops()
	pulse.tween_property(_sprite, "scale", base * 1.2, 0.4).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_sprite, "scale", base, 0.4).set_trans(Tween.TRANS_SINE)


## Drawn behind the Sprite2D child, because a node draws itself before its children.
func _draw() -> void:
	draw_circle(Vector2.ZERO, glow_radius, glow_color)
	draw_arc(Vector2.ZERO, glow_radius, 0.0, TAU, 40, Color(1, 1, 1, 0.8), 2.0, true)


func _process(delta: float) -> void:
	position.y += fall_speed * delta


## Returns true the first time it's called, then removes the pickup.
## This stops both players from collecting the same pickup on the same frame.
func try_collect() -> bool:
	if _taken:
		return false
	_taken = true
	queue_free()
	return true
