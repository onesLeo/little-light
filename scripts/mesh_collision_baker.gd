extends Node3D
## Builds StaticBody3D colliders for every MeshInstance3D under this node.
## Use on imported GLB roots (valley, props) that ship without physics.

@export var collision_layer: int = 1
## "Bank_" are the stream pack's duplicate banks, hidden at runtime (see stream_alive_clean.gd); baking them left an invisible wall.
@export var skip_name_contains: PackedStringArray = ["Outline", "Shadow", "Stream", "Waterfall", "Foam", "Fish_", "Bank_", "Ledge"]


func _ready() -> void:
	_bake(self)


func _bake(node: Node) -> void:
	for child in node.get_children():
		_bake(child)
	if not (node is MeshInstance3D):
		return
	var mi := node as MeshInstance3D
	if mi.mesh == null:
		return
	for part in skip_name_contains:
		if String(mi.name).findn(part) >= 0:
			return
	# Avoid double-bake if reloaded.
	for c in mi.get_children():
		if c is StaticBody3D and c.has_meta("baked_mesh_collision"):
			return

	# Shape3D so trimesh (concave) or convex fallback both type-check.
	# Bushes and cypress columns are many small spiky leaves: a trimesh would snag the walker, so use a solid hull.
	var shape: Shape3D = null
	if String(mi.name).begins_with("Shrub") or String(mi.name).begins_with("Cypress"):
		shape = mi.mesh.create_convex_shape(true, true)
	if shape == null:
		shape = mi.mesh.create_trimesh_shape()
	if shape == null:
		shape = mi.mesh.create_convex_shape(true, true)
	if shape == null:
		return

	var body := StaticBody3D.new()
	body.name = "BakedCollision"
	body.collision_layer = collision_layer
	body.collision_mask = 0
	body.set_meta("baked_mesh_collision", true)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	mi.add_child(body)
