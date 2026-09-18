extends Node3D
## Adds a soft pulsing rim glow to the 3 Wonder Items so they read from
## across the hillside while exploring, without a redesign of the models.
##
## Implementation: a shared ShaderMaterial assigned as material_overlay on
## each item's visual mesh (see assets/shaders/wonder_item_glow.gdshader).
## material_overlay renders as an extra pass on top of the paper-craft base
## material, so nothing about the imported mesh/material is touched — and
## the glow disappears for free when chapter_director hides the mesh on
## pickup, since there's nothing left to render it on.

const GLOW_SHADER := preload("res://assets/shaders/wonder_item_glow.gdshader")
const ITEM_NAMES := ["WonderItem_Stone", "WonderItem_Staff", "WonderItem_Lamb"]

func _ready() -> void:
	var visuals := get_node_or_null("WonderItemsVisual")
	if visuals == null:
		return
	var glow_material := ShaderMaterial.new()
	glow_material.shader = GLOW_SHADER
	for item_name in ITEM_NAMES:
		var mesh := visuals.find_child(item_name, true, false) as MeshInstance3D
		if mesh:
			mesh.material_overlay = glow_material
