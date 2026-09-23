extends Node3D
## Jonathan, the king's son. Built here so he is not a recolour of David.
## David is the shepherd: short wavy hair, a long golden tunic, a green sash.
## Jonathan is a little taller, with straight hair to his shoulders, a longer
## face, wider eyes, a wine-red tunic and a gold sash. No crown and no sword.

const SKIN := Color(0.79, 0.52, 0.32)
const HAIR := Color(0.08, 0.035, 0.02)
const TUNIC := Color(0.55, 0.18, 0.24)
const GOLD := Color(0.86, 0.68, 0.28)
const INK := Color(0.1, 0.06, 0.04)


func _ready() -> void:
	_body()
	_head()


func _process(delta: float) -> void:
	var breath := 1.0 + sin(Time.get_ticks_msec() * 0.002) * 0.012
	var tunic := get_node_or_null("Tunic") as MeshInstance3D
	if tunic:
		tunic.scale.y = breath


func _body() -> void:
	_shape("Tunic", CylinderMesh.new(), TUNIC, Vector3(0, 0.86, 0), Vector3(0.34, 0.72, 0.28))
	var hem := TorusMesh.new()
	hem.inner_radius = 0.3
	hem.outer_radius = 0.36
	hem.ring_segments = 8
	hem.rings = 4
	_shape("Hem", hem, GOLD, Vector3(0, 0.52, 0), Vector3(1, 1, 1))
	_shape("Sash", BoxMesh.new(), GOLD, Vector3(0, 0.9, -0.02), Vector3(0.46, 0.1, 0.32))
	var collar := TorusMesh.new()
	collar.inner_radius = 0.11
	collar.outer_radius = 0.14
	collar.ring_segments = 8
	collar.rings = 4
	_shape("Collar", collar, GOLD, Vector3(0, 1.26, 0), Vector3(1, 1, 1))
	for side in [-1.0, 1.0]:
		_shape("Leg", CapsuleMesh.new(), SKIN, Vector3(0.09 * side, 0.34, 0), Vector3(0.07, 0.36, 0.07))
		_shape("Sandal", BoxMesh.new(), Color(0.22, 0.12, 0.06), Vector3(0.09 * side, 0.06, -0.02), Vector3(0.1, 0.04, 0.2))
		_shape("Sleeve", CapsuleMesh.new(), TUNIC, Vector3(0.28 * side, 1.02, 0), Vector3(0.07, 0.34, 0.07))
		_shape("Hand", SphereMesh.new(), SKIN, Vector3(0.3 * side, 0.78, -0.04), Vector3(0.07, 0.07, 0.07))


func _head() -> void:
	# Longer than David's round shepherd face.
	_shape("Face", SphereMesh.new(), SKIN, Vector3(0, 1.52, 0), Vector3(0.16, 0.21, 0.15))
	# Straight hair to the shoulders. Not David's short wavy cap.
	_shape("HairCap", SphereMesh.new(), HAIR, Vector3(0, 1.64, 0.02), Vector3(0.175, 0.12, 0.16))
	_shape("HairSide", CapsuleMesh.new(), HAIR, Vector3(-0.13, 1.4, 0.0), Vector3(0.045, 0.32, 0.05))
	_shape("HairSide", CapsuleMesh.new(), HAIR, Vector3(0.13, 1.4, 0.0), Vector3(0.045, 0.32, 0.05))
	_shape("HairBack", CapsuleMesh.new(), HAIR, Vector3(0, 1.38, 0.1), Vector3(0.1, 0.34, 0.05))
	var band_mesh := TorusMesh.new()
	band_mesh.inner_radius = 0.15
	band_mesh.outer_radius = 0.175
	band_mesh.ring_segments = 8
	band_mesh.rings = 4
	_shape("HairBand", band_mesh, GOLD, Vector3(0, 1.66, 0), Vector3(1, 1, 1))
	for side in [-1.0, 1.0]:
		_shape("Eye", SphereMesh.new(), Color(0.95, 0.93, 0.88), Vector3(0.055 * side, 1.56, -0.12), Vector3(0.032, 0.034, 0.02), false)
		_shape("Pupil", SphereMesh.new(), Color(0.28, 0.14, 0.06), Vector3(0.055 * side, 1.555, -0.135), Vector3(0.016, 0.018, 0.012), false)
		var brow := _shape("Brow", BoxMesh.new(), HAIR, Vector3(0.055 * side, 1.61, -0.12), Vector3(0.05, 0.012, 0.012), false)
		brow.rotation.z = -0.25 * side
	_shape("Nose", SphereMesh.new(), SKIN, Vector3(0, 1.5, -0.145), Vector3(0.025, 0.04, 0.025), false)
	_shape("Mouth", BoxMesh.new(), Color(0.62, 0.32, 0.28), Vector3(0, 1.42, -0.13), Vector3(0.07, 0.014, 0.012), false)
	_shape("Smile", SphereMesh.new(), Color(0.62, 0.32, 0.28), Vector3(-0.03, 1.424, -0.128), Vector3(0.012, 0.01, 0.01), false)
	_shape("Smile", SphereMesh.new(), Color(0.62, 0.32, 0.28), Vector3(0.03, 1.424, -0.128), Vector3(0.012, 0.01, 0.01), false)


func _shape(part_name: String, mesh: PrimitiveMesh, color: Color, at: Vector3, size: Vector3, outlined: bool = true) -> MeshInstance3D:
	if mesh is CylinderMesh:
		(mesh as CylinderMesh).radial_segments = 8
	elif mesh is SphereMesh:
		(mesh as SphereMesh).radial_segments = 8
		(mesh as SphereMesh).rings = 6
	elif mesh is CapsuleMesh:
		(mesh as CapsuleMesh).radial_segments = 6
		(mesh as CapsuleMesh).rings = 2
	elif mesh is TorusMesh:
		(mesh as TorusMesh).ring_segments = 8
		(mesh as TorusMesh).rings = 4
	mesh.material = _mat(color)
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = at
	part.scale = size
	add_child(part)
	if outlined:
		var ink := MeshInstance3D.new()
		ink.name = part_name + "Ink"
		ink.mesh = mesh
		ink.material_override = _mat(INK)
		ink.scale = Vector3(1.08, 1.08, 1.08)
		part.add_child(ink)
	return part


func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return mat
