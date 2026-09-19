extends Node3D
## Softens alive-brook render while art finishes continuous cascade:
## 1) Hide Stream_/Waterfall_/Foam_ *_Outline (black OL slabs).
## 2) Lift leftover Ripple_/Waterfall_Sheet_ if present.
## 3) Separate coplanar water bodies (Main / Pool / Waterfall) on Y so
##    overlapping WaterPaper faces stop z-fighting black patches.

@export var lift_overlay_y: float = 0.05
@export var waterfall_y: float = 0.03
@export var pool_y: float = -0.02
@export var main_y: float = 0.0


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
		return
	# Break coplanar WaterPaper overlaps at cascade→pool joins.
	if n == "Waterfall_Main":
		n3.position.y += waterfall_y
	elif n == "Stream_Pool":
		n3.position.y += pool_y
	elif n == "Stream_Main" or n == "Stream_Join":
		n3.position.y += main_y
