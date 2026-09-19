extends Node3D
## Hides valley water / foam / fish the animated brook pack replaces.
## Alive pack draws Stream_Main + Waterfall_Main + join/pool; leaving the
## valley Stream_*/Waterfall_* visible causes z-fighting (black flicker)
## and color mismatch with WaterPaper.

@export var name_prefixes: PackedStringArray = [
	"Stream_",
	"Waterfall_",
	"Foam_",
	"Fish_",
]


func _ready() -> void:
	call_deferred("_hide_matches", get_parent())


func _hide_matches(node: Node) -> void:
	for child in node.get_children():
		_hide_matches(child)
	var n := String(node.name)
	for prefix in name_prefixes:
		if n.begins_with(prefix):
			if node is Node3D:
				(node as Node3D).visible = false
			return
