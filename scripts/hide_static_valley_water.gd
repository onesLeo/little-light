extends Node3D
## Hides non-animated valley water / foam / fish meshes when the alive
## stream pack is present, so we don't double-draw paper water.

@export var name_prefixes: PackedStringArray = [
	"Stream_", "Waterfall_", "Foam_", "Fish_"
]


func _ready() -> void:
	call_deferred("_hide_matches", self)


func _hide_matches(node: Node) -> void:
	for child in node.get_children():
		_hide_matches(child)
	var n := String(node.name)
	for prefix in name_prefixes:
		if n.begins_with(prefix):
			if node is Node3D:
				(node as Node3D).visible = false
			return
