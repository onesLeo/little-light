extends Node3D
## Belt-and-suspenders for alive brook packs (v6+).
## Hide leftover outline slabs (water/bank/rock) that read as black side blocks,
## and lift any old Ripple_/Waterfall_Sheet_ overlays if present.

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
	# Black paper outlines on water/banks/rocks show as thick side blocks.
	if n.ends_with("_Outline") and (
		n.begins_with("Stream_")
		or n.begins_with("Waterfall_")
		or n.begins_with("Foam_")
		or n.begins_with("Bank_")
		or n.begins_with("Rock_")
		or n.begins_with("WF_Rock_")
	):
		n3.visible = false
		return
	if n.begins_with("Stream_Ripple_") or n.begins_with("Waterfall_Sheet_"):
		n3.position.y += lift_overlay_y
