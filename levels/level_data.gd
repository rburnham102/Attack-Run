class_name LevelData
extends Resource
## Everything that makes one level different from another, stored as data.
##
## Each level is a .tres file made from this script (levels/level_01.tres...).
## Open one in the Inspector to edit the briefing, the map or the bosses.
## To add a level: duplicate a .tres file, edit it, then drag it into the
## Levels list on the Main node (scenes/main/main.tscn).

## Shown at the top of the briefing and as a banner when the fighting starts.
@export var title := "OPERATION"

@export_group("Briefing")
@export var general_name := "GENERAL"
@export var general_portrait: Texture2D
## One text box per line. The player presses fire to move to the next one.
## Each line picks its speaker, so Lt. Lilly can chime in too.
@export var briefing: Array[RadioLine] = []

@export_group("Map")
## Repeats under the planes during the briefing (open ocean for level 1).
@export var intro_chunk: PackedScene
## Placed once each, in this order, when the briefing ends. They join the
## intro terrain to the land (level 1: the coastline; level 2: the beach
## landing, with the allied boats).
@export var transition_chunks: Array[PackedScene] = []
## Picked at random once the fighting starts.
@export var chunks: Array[PackedScene] = []

@export_group("Ground Enemies")
## Vehicles that can appear on a chunk's land SpawnPoints. Add a scene more
## than once to make it more common.
@export var ground_enemies: Array[PackedScene] = []
## Vehicles that can appear on SpawnPoints marked "water".
@export var water_enemies: Array[PackedScene] = []
## How many SpawnPoints get filled in each chunk, picked at random between
## these. The top end also goes up by one after every boss (Game.stage), so
## each stage is busier than the last. A chunk never gets more enemies than
## it has SpawnPoints.
@export var min_ground_enemies := 1
@export var max_ground_enemies := 2

@export_group("Power-ups")
## Lets the gun, missile and shield drone pickups drop in this level. Off
## for the early levels, so drones arrive with level 3's story.
@export var drones_unlocked := false

@export_group("Air Enemies")
## The planes that fly in waves. Leave empty to use the one set on the Main
## node (the red bomber). Level 3 uses a white winter version.
@export var enemy_plane_scene: PackedScene
## Same for the helicopters.
@export var helicopter_scene: PackedScene

@export_group("Bosses")
## Fought in this order. The level ends when the last one is destroyed, so
## the number of bosses sets how long the level is.
@export var boss_scenes: Array[PackedScene] = []
## Optional, same order as Boss Scenes: while that boss is on its way and
## being fought, the map is built from this chunk only (level 3: open water
## under the submarine). Leave an entry empty, or the list short, for the
## normal chunks.
@export var boss_chunks: Array[PackedScene] = []
## Seconds of normal waves before each boss arrives.
@export var stage_length := 90.0

@export_group("Radio")
## What the comms officer says as each boss arrives, in the same order as
## Boss Scenes. Leave an entry out (or the whole list empty) for silence.
@export var boss_warnings: Array[RadioLine] = []
## What she says after each boss is destroyed, same order as Boss Scenes.
@export var boss_defeated_lines: Array[RadioLine] = []
## Played one after another once the last boss is down (after its line in
## Boss Defeated Lines, if it has one). The next level waits for these to
## finish, so they can be as long as you like.
@export var mission_complete_lines: Array[RadioLine] = []
