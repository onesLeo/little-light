extends Node3D
## Swaps the alive-brook pack's flat water material for the flowing water
## shader (assets/shaders/stream_water.gdshader): depth tint, ripples that move
## downstream, foam along the banks and streaks down the waterfall.
## Lives under StreamFishAlive, next to the pack instance called "Art".

const WATER_SHADER := preload("res://assets/shaders/stream_water.gdshader")

@export var water_mesh_name: String = "Stream_Water"


func _ready() -> void:
	# Deferred so the imported pack (and the cleanup scripts) have run first.
	call_deferred("_apply")


func _apply() -> void:
	var art := get_parent().get_node_or_null("Art")
	if art == null:
		return
	var water := art.find_child(water_mesh_name, true, false) as MeshInstance3D
	if water == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	water.material_override = mat
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
