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
@export_multiline var briefing: Array[String] = []

@export_group("Map")
## Repeats under the planes during the briefing (open ocean for level 1).
@export var intro_chunk: PackedScene
## Placed once when the briefing ends, joining the intro terrain to the land.
@export var transition_chunk: PackedScene
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

@export_group("Bosses")
## Fought in this order. The level ends when the last one is destroyed, so
## the number of bosses sets how long the level is.
@export var boss_scenes: Array[PackedScene] = []
## Seconds of normal waves before each boss arrives.
@export var stage_length := 90.0
