extends Node
## Lets the valley's trees and bushes show the colours painted into their vertices.
## Every leaf, trunk and bush shares one material ("FoliageVertexColour") so a tree costs two
## draw calls instead of five to seven. The colour is stored in the mesh vertices, but Godot's
## glTF importer leaves "use vertex colour as albedo" off, so the foliage would come out white.
## This switches it on once, on the shared material.

const MATERIAL_NAME := "FoliageVertexColour"

@export var valley_path: NodePath = ^"../BethlehemValley"


func _ready() -> void:
	var valley := get_node_or_null(valley_path)
	if valley == null:
		return
	var done: Dictionary = {}
	for node in valley.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i) as BaseMaterial3D
			if mat != null and mat.resource_name == MATERIAL_NAME and not done.has(mat):
				mat.vertex_color_use_as_albedo = true
				done[mat] = true
