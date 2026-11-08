extends AudioStreamPlayer
## Background music, registered as the "Music" autoload.
##
## It's an autoload *scene* (music.tscn) rather than just a script, so the
## track list can be edited in the Inspector. Autoloads are never freed when
## the scene changes, so one track plays on through the title screen, the game
## and game over without restarting.
##
## The tracks loop because "Loop" is ticked in each file's Import settings.

@export var tracks: Array[AudioStream] = []


func _ready() -> void:
	if tracks.is_empty():
		return
	stream = tracks.pick_random()
	play()
