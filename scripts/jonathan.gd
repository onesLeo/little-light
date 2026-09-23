extends Node3D
## Jonathan, the king's son. Built here so he is not a recolour of David.
## David is the shepherd: short wavy hair, a long golden tunic, a green sash.
## Jonathan is a little taller, with straight hair to his shoulders, a longer
## face, wider eyes, a wine-red tunic and a gold sash. No crown and no sword.
## Same big-headed paper-doll proportions as David and the Wonder-Walker, so the
## three read as friends of one age. Faces -Z.

const Paper := preload("res://scripts/camp_paper.gd")

const SKIN := Color(0.79, 0.52, 0.32)
const HAIR := Color(0.08, 0.035, 0.02)
const TUNIC := Color(0.55, 0.18, 0.24)
const GOLD := Color(0.86, 0.68, 0.28)
const SANDAL := Color(0.22, 0.12, 0.06)
const EYE_WHITE := Color(0.95, 0.93, 0.88)
const PUPIL := Color(0.28, 0.14, 0.06)
const LIPS := Color(0.62, 0.32, 0.28)


func _ready() -> void:
	_body()
	_head()


func _process(_delta: float) -> void:
	var breath := 1.0 + sin(Time.get_ticks_msec() * 0.002) * 0.012
	var tunic := get_node_or_null("Tunic") as MeshInstance3D
	if tunic:
		tunic.scale.y = breath


func _body() -> void:
	for side in [-1.0, 1.0]:
		_shape("Leg", Paper.capsule(0.055, 0.38), SKIN, Vector3(0.075 * side, 0.2, 0.0))
		_shape("Sandal", Paper.box(Vector3(0.1, 0.045, 0.17)), SANDAL, Vector3(0.075 * side, 0.025, -0.025))
	_shape("Tunic", Paper.cylinder(0.215, 0.54, 8, 0.15), TUNIC, Vector3(0.0, 0.63, 0.0))
	_shape("Hem", _ring(0.2, 0.232), GOLD, Vector3(0.0, 0.375, 0.0), Vector3.ZERO, 0.012)
	_shape("Chest", Paper.sphere(0.15), TUNIC, Vector3(0.0, 0.88, 0.0), Vector3.ZERO, 0.02, Vector3(1.12, 0.55, 0.85))
	_shape("Sash", Paper.cylinder(0.172, 0.07, 8), GOLD, Vector3(0.0, 0.72, 0.0), Vector3.ZERO, 0.012)
	# The gold sash also runs over one shoulder.
	_shape("SashBand", Paper.box(Vector3(0.07, 0.34, 0.3)), GOLD, Vector3(0.0, 0.83, 0.0), Vector3(0.0, 0.0, 0.62), 0.0, Vector3(1.0, 1.0, 1.0))
	_shape("Collar", _ring(0.07, 0.1), GOLD, Vector3(0.0, 0.94, 0.0), Vector3.ZERO, 0.01)
	for side in [-1.0, 1.0]:
		_shape("Sleeve", Paper.capsule(0.052, 0.34), TUNIC, Vector3(0.195 * side, 0.75, 0.0), Vector3(0.0, 0.0, 0.14 * side))
		_shape("Hand", Paper.sphere(0.052), SKIN, Vector3(0.22 * side, 0.56, -0.01))
	_shape("Neck", Paper.cylinder(0.05, 0.08, 6), SKIN, Vector3(0.0, 0.97, 0.0), Vector3.ZERO, 0.0)


func _head() -> void:
	# Longer than David's round shepherd face.
	_shape("Face", Paper.sphere(0.165), SKIN, Vector3(0.0, 1.15, 0.0), Vector3.ZERO, 0.02, Vector3(0.95, 1.12, 0.95))
	# Straight hair to the shoulders. Not David's short wavy cap.
	_shape("HairCap", Paper.sphere(0.178), HAIR, Vector3(0.0, 1.23, 0.025), Vector3.ZERO, 0.02, Vector3(1.0, 0.72, 1.0))
	_shape("HairSide", Paper.capsule(0.045, 0.3), HAIR, Vector3(-0.148, 1.08, 0.02))
	_shape("HairSide", Paper.capsule(0.045, 0.3), HAIR, Vector3(0.148, 1.08, 0.02))
	_shape("HairBack", Paper.capsule(0.13, 0.36), HAIR, Vector3(0.0, 1.09, 0.1), Vector3.ZERO, 0.02, Vector3(1.0, 1.0, 0.45))
	_shape("HairBand", _ring(0.168, 0.186), GOLD, Vector3(0.0, 1.265, 0.012), Vector3(0.1, 0.0, 0.0), 0.01)
	for side in [-1.0, 1.0]:
		_shape("Eye", Paper.sphere(0.032, 8), EYE_WHITE, Vector3(0.062 * side, 1.17, -0.142), Vector3.ZERO, 0.008, Vector3(1.0, 1.1, 0.5))
		_shape("Pupil", Paper.sphere(0.018, 6), PUPIL, Vector3(0.062 * side, 1.165, -0.156), Vector3.ZERO, 0.0, Vector3(1.0, 1.0, 0.5))
		_shape("Brow", Paper.box(Vector3(0.055, 0.013, 0.013)), HAIR, Vector3(0.062 * side, 1.22, -0.142), Vector3(0.0, 0.0, -0.22 * side), 0.0)
	_shape("Nose", Paper.sphere(0.022, 6), SKIN, Vector3(0.0, 1.12, -0.16), Vector3.ZERO, 0.0, Vector3(1.0, 1.4, 1.0))
	_shape("Mouth", Paper.box(Vector3(0.06, 0.012, 0.012)), LIPS, Vector3(0.0, 1.06, -0.148), Vector3.ZERO, 0.0)
	for side in [-1.0, 1.0]:
		_shape("Smile", Paper.sphere(0.009, 6), LIPS, Vector3(0.03 * side, 1.064, -0.146), Vector3.ZERO, 0.0)


## A part with its colour on the mesh itself and a thin ink rim.
func _shape(part_name: String, mesh: PrimitiveMesh, color: Color, at: Vector3, rot: Vector3 = Vector3.ZERO,
		line: float = 0.016, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	mesh.material = Paper.mat(color)
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = at
	part.rotation = rot
	part.scale = size
	add_child(part)
	if line > 0.0:
		Paper.outline(part, line)
	return part


func _ring(inner: float, outer: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 4
	m.ring_segments = 10
	return m
