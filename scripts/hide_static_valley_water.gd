extends Node3D
## Hides only the static valley pieces the animated brook replaces (pool,
## splash foam, static fish). The cliff waterfall and the upstream/downstream
## river stay so the water still reads as one continuous river.

@export var name_prefixes: PackedStringArray = [
	"Stream_Pool", "Foam_Splash", "Foam_Spray", "Fish_"
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
