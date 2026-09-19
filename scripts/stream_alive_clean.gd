extends Node3D
## Softens alive-brook render until art ships continuous cascade:
## hide Stream_/Waterfall_/Foam_ *_Outline (black OL slabs),
## lift Ripple_/Waterfall_Sheet_ so they don't z-fight WaterPaper.

@export var lift_y: float = 0.05


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
		n3.position.y += lift_y
