class_name RadioLine
extends Resource
## One line of dialogue: who says it, the text, and (for Lt. Lilly) the face
## she makes while saying it. Used for the briefing and for radio calls
## during the mission.
##
## You don't make these as files. In a LevelData's Briefing or Radio lists,
## click "Add Element", pick "New RadioLine", then click it to fill it in.

## Who is talking. The general's name and portrait come from the level
## (LevelData), Lt. Lilly's from the Radio and Briefing scenes.
enum Speaker { COMMS, GENERAL }
## Each mood is one of Lt. Lilly's portrait animations (the names in
## assets/Portraits/comms_officer/comms_officer.tres). The general has a
## single portrait, so his lines ignore this.
enum Mood { NEUTRAL, SHOCKED, DETERMINED }

## Lt. Lilly is the same character in every level, so her name and portraits
## live here, in one place, rather than in each LevelData (which holds the
## general's, since a later mission could have a different commander).
const COMMS_NAME := "LT. LILLY"
const COMMS_PORTRAITS: SpriteFrames = preload("res://assets/Portraits/comms_officer/comms_officer.tres")

@export var speaker := Speaker.COMMS
@export var mood := Mood.NEUTRAL
@export_multiline var text := ""


## The name of Lt. Lilly's portrait animation for this line's mood.
## Mood.SHOCKED -> "SHOCKED" -> "shocked".
func mood_animation() -> StringName:
	return StringName(Mood.keys()[mood].to_lower())
