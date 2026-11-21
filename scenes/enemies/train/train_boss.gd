extends "res://scenes/enemies/super_tank.gd"
## Level 4's armoured train: an engine pulling four wagons bristling with
## guns. Levels 2 and 3 used super_tank.gd for one big vehicle, and the train
## is the same fight spread along a long body (super_tank.gd has no
## class_name, so we extend it by its path):
##   - every gun (BossTurret) must be destroyed before the engine can be hurt,
##   - the main cannon swings to follow the nearest player,
##   - boss.gd's aimed burst and fan fire from the main cannon.
##
## What this script adds is the chase. The players catch the train up from
## behind, so the last wagon appears at the top of the screen first. The
## train slides down the screen and stops each time a wagon reaches Car
## Stop Y, until every gun on that wagon is destroyed, then moves on to the
## next one. The engine comes last; once it reaches Battle Y the main cannon
## opens fire.
##
## Which wagon a gun belongs to is worked out from where it sits: drag a
## turret onto a wagon in the editor and it's part of that wagon's fight.
##
## Like a boss, the train lives on the Scroller (screen coordinates). It
## doesn't really move backwards: holding still on screen means it's racing
## along the track as fast as the players fly.
##
## When it's destroyed it doesn't fade away: the burning wreck falls behind
## and rolls off the bottom of the screen. With Big Finish ticked (the second
## train) its cargo then goes up in a huge explosion behind the players.

## Screen x of the middle of the train: which pair of tracks it runs on.
@export var track_x := 150.0
## Screen y where each wagon stops while its guns are fought.
@export var car_stop_y := 380.0
## How fast the train slides between stops, in pixels per second.
@export var travel_speed := 150.0
## Colour of the wreck.
@export var wreck_tint := Color(0.35, 0.35, 0.35)
## Seconds for the wreck to fall behind, off the bottom of the screen.
@export var roll_away_time := 3.0

@export_group("Big Finish")
## The train's cargo explodes once it has rolled off screen: a white flash,
## a screen shake and a huge blast behind the players.
@export var big_finish := false
@export var big_finish_sound: AudioStream
## Seconds the flash takes to fade.
@export var flash_time := 1.5
## How far the screen shakes, in pixels, and for how long.
@export var shake_strength := 18.0
@export var shake_time := 1.2
## Seconds after the blast before the radio chatter starts.
@export var after_blast_delay := 1.5
@export_group("")

## The cars, rear wagon first, the engine last. The engine is boss.gd's main
## sprite ($Sprite2D); the wagons are the sprites under Cars.
var _cars: Array[Sprite2D] = []
## The guns on each car: car -> Array of turrets.
var _car_turrets := {}
## Index in _cars of the car we're heading for, or stopped at.
var _car_index := 0
## True while stopped at a wagon, waiting for its guns to be destroyed.
var _holding := false
## The whole train's rectangle, around our origin. Ground vehicles under it
## are removed (a small train on the same tracks would show through).
var _cover := Rect2()

@onready var _hull: CollisionShape2D = $Hull
@onready var _wagons: Node2D = $Cars
@onready var _wheels: Sprite2D = $Wheels


func _ready() -> void:
	# The cars have to be listed before super(): boss.gd's _ready() ends by
	# calling _enter(), which starts the chase. (@onready variables, ours and
	# super_tank.gd's _turrets, are already set when _ready() starts.)
	# assign() fills a typed array from an untyped one.
	_cars.assign(_wagons.get_children())
	# Rear first: the further down the train (bigger y), the sooner we meet it.
	_cars.sort_custom(func(a: Sprite2D, b: Sprite2D) -> bool: return a.position.y > b.position.y)
	_cars.append(_sprite)
	_cover = _rect_of(_sprite)
	for car in _cars:
		var rect := _rect_of(car)
		_car_turrets[car] = _turrets.filter(
			func(t: Node2D) -> bool: return rect.has_point(to_local(t.global_position)))
		_cover = _cover.merge(rect)
	super()  # super_tank.gd: health bar covers the engine plus every gun


## A car's rectangle in our coordinates. get_rect() is the sprite's own
## rectangle, before its position and scale.
func _rect_of(car: Sprite2D) -> Rect2:
	var rect := car.get_rect()
	return Rect2(car.position + rect.position * car.scale, rect.size * car.scale)


## Called by boss.gd instead of the usual drive-in: put the last wagon just
## above the top of the screen and start the chase.
func _enter() -> void:
	position = Vector2(track_x, -_cover.end.y - 20.0)
	_go_to_next_car()


func _go_to_next_car() -> void:
	var car := _cars[_car_index]
	# The engine stops with our origin (the main cannon) at battle_y; a wagon
	# stops with its middle at car_stop_y.
	var stop := battle_y if car == _sprite else car_stop_y - car.position.y
	var slide := create_tween()
	slide.tween_property(self, "position:y", stop, absf(stop - position.y) / travel_speed) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	slide.tween_callback(_on_car_reached)


func _on_car_reached() -> void:
	if _cars[_car_index] == _sprite:
		_start_fight()
	else:
		_holding = true
		_check_car_cleared()


## Moves on once every gun on the wagon we're stopped at is destroyed.
func _check_car_cleared() -> void:
	if not _holding:
		return
	var guns: Array = _car_turrets[_cars[_car_index]]
	if guns.all(func(t: Node) -> bool: return t.destroyed):
		_holding = false
		_car_index += 1
		_go_to_next_car()


## The engine has arrived. Replaces super_tank.gd's version, which switches
## on every turret at once: here each one switched on as it came into view
## (see _process()), and the destroyed ones must stay off.
func _start_fight() -> void:
	_active = true
	_attack_timer.start()


func _process(delta: float) -> void:
	super(delta)  # aims the main cannon (once the fight has started)
	if destroyed:
		return
	# Guns open fire once they're on screen. Our position is in screen
	# coordinates, so a gun's screen y is ours plus its y on the train.
	for turret: Node2D in _turrets:
		if not turret.active and not turret.destroyed \
				and position.y + to_local(turret.global_position).y > 40.0:
			turret.activate()
	_bury_vehicles()


## Removes any ground vehicle under the train. Tanks, trucks and train cars
## all join the "ground_vehicles" group in tank.gd.
func _bury_vehicles() -> void:
	var area := Rect2(global_position + _cover.position, _cover.size)
	for vehicle: Node2D in get_tree().get_nodes_in_group("ground_vehicles"):
		if area.has_point(vehicle.global_position):
			vehicle.queue_free()


func turret_destroyed(turret_hp: int, shooter_id: int) -> void:
	super(turret_hp, shooter_id)
	_check_car_cleared()


func _drop_armor() -> void:
	super()
	# Like the submarine, the engine's hitbox starts switched off so it
	# doesn't shield its own side guns. set_deferred: we may be inside a
	# collision callback.
	_hull.set_deferred("disabled", false)


## The main cannon plays its recoil frames with each aimed shot.
func _fire_aimed() -> void:
	super()
	if _main_turret.hframes > 1:
		var recoil := create_tween()
		recoil.tween_property(_main_turret, "frame", _main_turret.hframes - 1, 0.15).from(0)
		recoil.tween_property(_main_turret, "frame", 0, 0.0)


func die(shooter_id: int) -> void:
	_holding = false
	super(shooter_id)  # explosions; boss.gd calls _finish_death() at the end
	_wagons.modulate = wreck_tint
	_wheels.modulate = wreck_tint
	$Turrets.modulate = wreck_tint


## Replaces boss.gd's version. Drops the bonus pickups where the engine was,
## then the wreck rolls away off the bottom of the screen before the level
## hears the boss is beaten.
func _finish_death() -> void:
	for i in BONUS_DROPS:
		var at := global_position + Vector2((i - 0.5) * 80.0, 0)
		Game.spawn_pickup(Game.random_pickup_kind(Game.BONUS_WEIGHTS), at)
	# Far enough that the front of the engine is below the screen.
	var off_screen := get_viewport_rect().size.y - _cover.position.y + 40.0
	var roll := create_tween()
	roll.tween_property(self, "position:y", off_screen, roll_away_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if big_finish:
		roll.tween_callback(_big_explosion)
		roll.tween_interval(after_blast_delay)
	roll.tween_callback(_report_defeat)


## The cargo goes up behind the players: a few huge explosions along the
## bottom edge of the screen, a white flash and a screen shake.
func _big_explosion() -> void:
	var screen := get_viewport_rect().size
	for i in 3:
		var boom := EXPLOSION.instantiate()
		# Explosions go on the map. Our position is on the screen and our
		# global_position on the map, so this is the bottom of the screen.
		boom.position = global_position + Vector2((i - 1) * 220.0, screen.y - position.y - 60.0)
		boom.scale = Vector2.ONE * (9.0 if i == 1 else 6.0)
		if i == 1:
			boom.sound = big_finish_sound
		Game.add_to_world(boom)
	Game.flash_screen(Color.WHITE, flash_time)
	Game.shake_camera(shake_strength, shake_time)


func _report_defeat() -> void:
	Game.boss_defeated.emit()
	queue_free()
