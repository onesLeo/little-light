extends Node3D
## Belt-and-suspenders for alive brook packs.
## v6 welds cascade+join+pool into one Stream_Water mesh (no coplanar split).
## Keep hiding any leftover Stream_/Waterfall_/Foam_ *_Outline and lifting
## Ripple_/Waterfall_Sheet_ if an older pack is temporarily re-pointed.

@export var lift_overlay_y: float = 0.05


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var art := get_parent().get_node_or_null("Art")
	if art == null:
		art = get_parent()
	_clean(art)


func _clean(node: Node) -> void:
	for child in node.get_children():
		_clean(child)
	if not (node is Node3D):
		return
	var n3 := node as Node3D
	var n := String(node.name)
	if n.ends_with("_Outline") and (
		n.begins_with("Stream_")
		or n.begins_with("Waterfall_")
		or n.begins_with("Foam_")
	):
		n3.visible = false
		return
	if n.begins_with("Stream_Ripple_") or n.begins_with("Waterfall_Sheet_"):
		n3.position.y += lift_overlay_y
