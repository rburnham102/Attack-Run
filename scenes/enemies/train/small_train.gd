extends Node2D
## A small enemy train for level 4: an engine pulling a few cars along a
## track. ChunkSpawner puts these on SpawnPoints marked "track".
##
## The train moves as one: this root node drives forward (down the screen at
## rotation 0, the same rule as tank.gd), carrying the cars with it. Each
## car is its own enemy (a vehicle scene using tank.gd, with Move Speed 0),
## so the train can be shot apart car by car, and each wrecked car stays
## coupled in place. The engine is at the front (our origin), and the cars
## trail behind it, up the screen.
##
## If the engine is destroyed the train coasts to a stop.

## Pixels per second along the track. ChunkSpawner sets this to 0 on a
## "parked" SpawnPoint, for trains standing at a platform.
@export var move_speed := 30.0
## How quickly a train with no engine slows down, in pixels per second each
## second.
@export var coast_braking := 15.0

## Our engine car. Cars free themselves when destroyed, and a freed node
## reads as false, so this is how we notice the engine is gone.
@onready var _engine: Node = get_node_or_null("Engine")


func _process(delta: float) -> void:
	if not is_instance_valid(_engine):
		move_speed = move_toward(move_speed, 0.0, coast_braking * delta)
	position += Vector2.DOWN.rotated(rotation) * move_speed * delta
