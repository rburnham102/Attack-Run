class_name SpawnPoint
extends Marker2D
## A spot in a chunk where a ground or water enemy might appear.
##
## Put these under a node called "SpawnPoints" in a chunk scene. Each time the
## chunk is placed, ChunkSpawner fills a random few of them with random
## vehicles from the level's lists (see LevelData), so the same chunk plays
## differently every time.
##
## Rotate the marker to choose which way the vehicle drives, the same way you
## would rotate a vehicle: at rotation 0 it drives down the screen,
## at -90 it drives right, at 90 it drives left.

## Spawn a boat (from the level's Water Enemies list) instead of a land vehicle.
## Only tick this on markers that sit on water.
@export var water := false
## The vehicle stays still here instead of driving. Its turret still aims
## and fires. Good for vehicles dug in at a base.
@export var parked := false
