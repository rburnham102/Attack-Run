extends Area2D
## Player 2's special: a huge laser from the plane's nose to the top of the
## screen, for Duration seconds.
##
## The plane (player.gd) adds this as its child, so the beam moves with it,
## and calls activate() when the special button is pressed with a full bar.
## While it fires, the plane's normal guns hold their fire (guns_paused).
##
## The beam is an Area2D, so Godot tells us everything inside it:
##   - every Tick Time seconds, each enemy in the beam takes Damage. That's
##     the normal gun's rate of fire and a bullet's damage, so every target
##     takes what one stream of bullets would deal, all at once. A hit effect
##     plays on each one.
##   - enemy bullets and shells (collision layer 5, "enemy shots") are wiped
##     out the moment they touch it, so the beam cuts a safe path.
## Nothing blocks the beam: it passes through everything.

signal finished

## Seconds the beam lasts. The plane drains its special bar over this time.
@export var duration := 6.0
## Damage each target takes per tick.
@export var damage := 1
## Seconds between damage ticks (the same as the plane's ShotTimer).
@export var tick_time := 0.12
## Played on each target the beam hits.
@export var hit_texture: Texture2D
@export var hit_frames := 3
## Beam animation speed, in frames per second.
@export var beam_fps := 18.0
## Seconds for the beam to grow to full width, and to shrink away.
@export var fade_time := 0.15

## Collision layer 5 (value 16): enemy bullets and shells.
const ENEMY_SHOTS := 16

## Set by the plane before we're added.
var player: Node2D

var _firing := false
var _tick_left := 0.0
var _time := 0.0
var _full_width := 1.0

@onready var _beam: Node2D = $Beam
@onready var _segments: Array[Node] = $Beam.get_children()
@onready var _shape: RectangleShape2D = $CollisionShape2D.shape
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _fire_sound: AudioStreamPlayer2D = $FireSound
@onready var _hit_sound: AudioStreamPlayer2D = $HitSound


func _ready() -> void:
	_full_width = _beam.scale.x
	_beam.hide()
	monitoring = false
	area_entered.connect(_on_area_entered)


func activate() -> void:
	_firing = true
	_tick_left = 0.0
	player.guns_paused = true
	_fire_sound.play()
	_beam.show()
	_beam.scale.x = 0.0
	set_deferred("monitoring", true)
	var beam := create_tween()
	beam.tween_property(_beam, "scale:x", _full_width, fade_time)
	beam.tween_interval(duration - 2.0 * fade_time)
	beam.tween_property(_beam, "scale:x", 0.0, fade_time)
	beam.tween_callback(_stop)


func _stop() -> void:
	_firing = false
	_beam.hide()
	set_deferred("monitoring", false)
	player.guns_paused = false
	finished.emit()


func _process(delta: float) -> void:
	if not _firing:
		return
	# Stretch the hitbox from the nose (our origin) to the top of the
	# screen. The plane's position is in screen coordinates, so it's also
	# the distance down from the top of the screen.
	var length := player.position.y + 20.0
	_shape.size.y = length
	_collision.position.y = -length / 2.0
	# Animate the beam: every segment shows the same frame.
	_time += delta
	for segment: Sprite2D in _segments:
		segment.frame = int(_time * beam_fps) % segment.hframes
	_tick_left -= delta
	if _tick_left <= 0.0:
		_tick_left += tick_time
		_damage_tick()


func _damage_tick() -> void:
	# monitoring is switched on at the end of the frame activate() ran in.
	if not monitoring:
		return
	var hit_any := false
	for area in get_overlapping_areas():
		# Enemies already destroyed, knocked-out boss turrets and the like
		# have monitorable off: leave them alone.
		if area.has_method("take_damage") and area.monitorable and not area.get("destroyed"):
			area.take_damage(damage, player.player_id)
			_show_hit(area.global_position)
			hit_any = true
	if hit_any and not _hit_sound.playing:
		_hit_sound.play()


## Enemy shots vanish the moment they touch the beam.
func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer & ENEMY_SHOTS:
		area.queue_free()


## Plays the hit effect once where the beam meets a target.
func _show_hit(at: Vector2) -> void:
	var hit := Sprite2D.new()
	hit.texture = hit_texture
	hit.hframes = hit_frames
	hit.z_index = 5
	hit.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hit.position = at + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
	Game.add_to_world(hit)
	var play := hit.create_tween()
	play.tween_property(hit, "frame", hit_frames - 1, tick_time * 1.5).from(0)
	play.tween_callback(hit.queue_free)
