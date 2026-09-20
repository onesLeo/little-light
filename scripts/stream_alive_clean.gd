extends Node3D
## Placement helpers for the alive brook pack.
## - Hide outline slabs and duplicate Bank_* meshes (valley owns the banks;
##   pack banks clip trees and read as dark side walls).
## - Lift any leftover Ripple_/Waterfall_Sheet_ overlays.

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
	# Duplicate banks from the stream pack fight valley trees/land.
	if n.begins_with("Bank_"):
		n3.visible = false
		return
	if node.has_meta("stone_restyled"):
		return   # a rock outline stream_rocks.gd gave the valley's stone outline to
	if n.ends_with("_Outline") and (
		n.begins_with("Stream_")
		or n.begins_with("Waterfall_")
		or n.begins_with("Foam_")
		or n.begins_with("Rock_")
		or n.begins_with("WF_Rock_")
	):
		n3.visible = false
		return
	if n.begins_with("Stream_Ripple_") or n.begins_with("Waterfall_Sheet_"):
		n3.position.y += lift_overlay_y
