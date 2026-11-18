extends "res://scenes/enemies/tank.gd"
## A gun emplacement: level 3's ice turrets and the ice cannon bunker.
##
## It's a vehicle that never drives, so it extends tank.gd (with the script's
## path, since tank.gd has no class_name) and gets the aiming, bursts,
## spreads and wreck for free. On top of that it adds:
##   - a recoil animation: if the Turret sprite is a strip (Hframes > 1) it
##     plays through its frames each time it fires.
##   - an optional hatch: with Opens ticked, the Base sprite's frames play
##     once when the bunker scrolls onto the screen (the ice cannon sliding
##     out). Until then it can't be hurt and doesn't fire.
##
## To make a turret that can't turn (the ice cannon), set Turret Turn Speed
## to 0: it then always fires the way it faces.

@export var opens := false
## Seconds for the hatch to open.
@export var open_time := 0.8
## Seconds for one recoil animation.
@export var recoil_time := 0.18

var _open := true

@onready var _notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenEnabler2D


func _ready() -> void:
	super()
	move_speed = 0.0  # emplacements never drive, even on a moving SpawnPoint
	if opens:
		_open = false
		_base.frame = 0
		# VisibleOnScreenEnabler2D is a kind of VisibleOnScreenNotifier2D, so
		# it has the screen_entered signal. ONE_SHOT: only open once.
		_notifier.screen_entered.connect(_open_hatch, CONNECT_ONE_SHOT)


func _open_hatch() -> void:
	var tween := create_tween()
	tween.tween_property(_base, "frame", _base.hframes - 1, open_time)
	tween.tween_callback(func(): _open = true)


func take_damage(amount: int, shooter_id: int) -> void:
	if _open:
		super(amount, shooter_id)


func _fire() -> void:
	if _open:
		super()


func _fire_volley() -> void:
	super()
	var sprite := _turret as Sprite2D
	if sprite and sprite.hframes > 1:
		var recoil := create_tween()
		recoil.tween_property(sprite, "frame", sprite.hframes - 1, recoil_time).from(0)
		recoil.tween_property(sprite, "frame", 0, 0.0)
