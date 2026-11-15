class_name RadioLine
extends Resource
## One thing the comms officer says over the radio during a mission: the text
## and the face she makes while saying it.
##
## You don't make these as files. In a LevelData's Radio lists, click
## "Add Element", pick "New RadioLine", then click it to fill it in.

## Each mood is one of her portrait animations (the names in
## assets/Portraits/comms_officer/comms_officer.tres).
enum Mood { NEUTRAL, SHOCKED, DETERMINED }

@export var mood := Mood.NEUTRAL
@export_multiline var text := ""
