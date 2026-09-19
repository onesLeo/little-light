extends Node
## DavidMentor-only belt-and-suspenders for OutlineInk shell.
## Walks ONLY the DavidMentor subtree — never the whole scene.
## v12 ships with correct inward outline normals; we still force
## CULL_FRONT + unshaded on Outline* meshes so a bad import cannot
## paint the body black again.

@export var david_path: NodePath = ^"DavidMentor"

func _ready() -> void:
	call_deferred("_apply")

func _apply() -> void:
	var david := get_node_or_null(david_path) as Node
	if david == null:
		push_warning("FixDavidMentorVisuals: DavidMentor not found at %s" % david_path)
		return
	_walk(david)

func _walk(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var nl := String(mi.name).to_lower()
		if nl.contains("outline"):
			_fix_outline_mesh(mi)
	for c in n.get_children():
		_walk(c)

func _fix_outline_mesh(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for i in range(mi.mesh.get_surface_count()):
		var mat := mi.get_active_material(i)
		var sm := mat as StandardMaterial3D
		if sm == null:
			sm = StandardMaterial3D.new()
		else:
			sm = sm.duplicate() as StandardMaterial3D
		sm.cull_mode = BaseMaterial3D.CULL_FRONT
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.albedo_color = Color(0.08, 0.06, 0.05, 1.0)
		mi.set_surface_override_material(i, sm)
