extends Area2D
## One script for every projectile. Each bullet *scene* sets its own sprite,
## speed, damage and collision layer/mask in the Inspector, so the player's
## bullets only hit enemies and enemy bullets only hit players.

@export var speed := 900.0
@export var damage := 1
## Seconds before the bullet removes itself, as a safety net in case it never
## leaves the screen (for example, if it spawned off-screen).
@export var lifetime := 4.0

## Set by whoever fires the bullet, before it is added to the scene.
var direction := Vector2.UP
## Which player fired this (1 or 2) so kills are credited. 0 = an enemy fired it.
var shooter_id := 0

var _spent := false


func _ready() -> void:
	# The sprites point up, and Vector2.UP has an angle of -PI/2,
	# so adding PI/2 turns "up" into a rotation of 0.
	rotation = direction.angle() + PI / 2
	area_entered.connect(_on_area_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _process(delta: float) -> void:
	position += direction * speed * delta


func _on_area_entered(area: Area2D) -> void:
	# _spent stops one bullet from damaging two overlapping targets.
	if _spent:
		return
	if area.has_method("take_damage"):
		_spent = true
		area.take_damage(damage, shooter_id)
		queue_free()
