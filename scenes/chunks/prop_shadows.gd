extends Node2D
## Attach to a chunk's Props node. When the chunk loads, every Sprite2D or
## TileMapLayer directly under this node gets a soft drop shadow, so trees,
## houses and rocks look like they stand up off the ground instead of being
## painted on. Ground tiles belong outside Props, so they stay flat.
##
## The shadow is a darkened copy of the prop's own sprite, so its shape always
## matches. It uses the same light direction as the aircraft shadows
## (down and to the right), but a much shorter offset: a short shadow reads as
## "tall object on the ground", a long one as "high up in the air".

## How far the shadow falls from its prop, in screen pixels.
@export var shadow_offset := Vector2(5, 8)
## Black at partial alpha darkens the ground without hiding it.
@export var shadow_color := Color(0, 0, 0, 0.35)


func _ready() -> void:
	for prop in get_children():
		if prop is Sprite2D or prop is TileMapLayer:
			_add_shadow(prop)


func _add_shadow(prop: Node2D) -> void:
	# duplicate() copies the texture plus anything else that affects which
	# pixels are drawn (offset, flip, region, frames), so the shadow matches
	# even for props that use a sprite sheet. Passing 0 skips copying the
	# prop's script, signals and groups, which a shadow doesn't need.
	# For a TileMapLayer it copies the placed tiles.
	var shadow: Node2D = prop.duplicate(0)
	shadow.name = "Shadow"
	# The shadow is a child of the prop, so it already inherits the prop's
	# position, rotation and scale. Reset its own transform, then convert the
	# screen-space offset into the prop's local space, so a rotated or scaled
	# prop still casts its shadow down and to the right.
	shadow.transform = Transform2D.IDENTITY
	shadow.position = prop.transform.affine_inverse().basis_xform(shadow_offset)
	shadow.z_index = 0
	shadow.modulate = shadow_color
	shadow.self_modulate = Color.WHITE
	# Draw the shadow before (underneath) its prop, but still on top of the
	# ground tiles, with no z_index juggling.
	shadow.show_behind_parent = true
	# A shadow is only a picture: if the tiles ever get collision shapes,
	# the copy must not add a second, offset set of walls.
	if shadow is TileMapLayer:
		shadow.collision_enabled = false
	prop.add_child(shadow)
