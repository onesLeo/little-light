extends Node3D
## One of the four camp guards: plain sand and brown cloth, a head cloth, a short
## cape and a staff held down. No armour and no sword. They walk a slow loop
## among the tents, stop now and then to look around, and never come toward the
## child. Built facing -Z, like Jonathan.

const Paper := preload("res://scripts/camp_paper.gd")

const CLOTH := [Color(0.74, 0.62, 0.44), Color(0.68, 0.56, 0.4), Color(0.78, 0.67, 0.49)]
const CAPE := [Color(0.46, 0.31, 0.19), Color(0.52, 0.36, 0.22), Color(0.4, 0.28, 0.18)]
const SKIN := [Color(0.79, 0.52, 0.32), Color(0.66, 0.43, 0.27), Color(0.84, 0.6, 0.4)]
const WOOD := Color(0.42, 0.28, 0.15)
const INK_DOT := Color(0.12, 0.07, 0.04)

## The loop, in world x/z. Set before the guard enters the tree.
var route: PackedVector2Array = PackedVector2Array()
var speed: float = 0.8
var look: int = 0
## Returns the ground height under a world point (the camp's own ground lookup).
var ground: Callable

var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _body: Node3D
var _head: Node3D
var _target: int = 1
var _pause: float = 0.0
var _phase: float = 0.0
var _look_from: float = 0.0
var _look_to: float = 0.0


func _ready() -> void:
	_build()
	if route.size() > 0:
		global_position = _on_ground(route[0])
	_phase = randf() * TAU


func _process(delta: float) -> void:
	if route.size() < 2:
		return
	if _pause > 0.0:
		_pause -= delta
		# Glances one way and back while standing.
		var t := clampf(1.0 - _pause / 2.4, 0.0, 1.0)
		_head.rotation.y = lerpf(_look_from, _look_to, sin(t * PI))
		_settle_legs(delta)
		return
	var goal := route[_target]
	var here := Vector2(global_position.x, global_position.z)
	var to_goal := goal - here
	var dist := to_goal.length()
	if dist < 0.08:
		_target = (_target + 1) % route.size()
		if randf() < 0.45:
			_pause = randf_range(1.6, 3.2)
			_look_from = 0.0
			_look_to = randf_range(0.6, 1.0) * (1.0 if randf() < 0.5 else -1.0)
		return
	var step := minf(speed * delta, dist)
	here += to_goal / dist * step
	global_position = _on_ground(here)
	# Turn smoothly toward where he is walking (the model faces -Z).
	var want := atan2(-to_goal.x, -to_goal.y)
	rotation.y = lerp_angle(rotation.y, want, minf(1.0, delta * 4.0))
	_head.rotation.y = lerpf(_head.rotation.y, 0.0, minf(1.0, delta * 3.0))
	_phase += delta * speed * 5.2
	var swing := sin(_phase) * 0.42
	_leg_l.rotation.x = swing
	_leg_r.rotation.x = -swing
	_arm_l.rotation.x = -swing * 0.6
	_body.position.y = absf(cos(_phase)) * 0.03


func _settle_legs(delta: float) -> void:
	_leg_l.rotation.x = lerpf(_leg_l.rotation.x, 0.0, minf(1.0, delta * 6.0))
	_leg_r.rotation.x = lerpf(_leg_r.rotation.x, 0.0, minf(1.0, delta * 6.0))
	_arm_l.rotation.x = lerpf(_arm_l.rotation.x, 0.0, minf(1.0, delta * 6.0))
	_body.position.y = lerpf(_body.position.y, 0.0, minf(1.0, delta * 6.0))


func _on_ground(p: Vector2) -> Vector3:
	var at := Vector3(p.x, 0.0, p.y)
	if ground.is_valid():
		return ground.call(at)
	return at


func _build() -> void:
	var cloth: Color = CLOTH[look % CLOTH.size()]
	var cape: Color = CAPE[look % CAPE.size()]
	var skin: Color = SKIN[look % SKIN.size()]

	_leg_l = _pivot(self, Vector3(-0.1, 0.62, 0.0))
	_leg_r = _pivot(self, Vector3(0.1, 0.62, 0.0))
	for leg in [_leg_l, _leg_r]:
		Paper.part(leg, "Leg", Paper.capsule(0.075, 0.62), skin, Vector3(0.0, -0.3, 0.0))
		Paper.part(leg, "Sandal", Paper.box(Vector3(0.12, 0.05, 0.22)), Color(0.3, 0.18, 0.1), Vector3(0.0, -0.6, -0.03))

	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	Paper.part(_body, "Tunic", Paper.cylinder(0.27, 0.72, 8, 0.19), cloth, Vector3(0.0, 0.92, 0.0))
	Paper.part(_body, "Belt", Paper.cylinder(0.225, 0.07, 8), cape.darkened(0.2), Vector3(0.0, 1.0, 0.0), Vector3.ZERO, Vector3.ONE, 0.015)
	Paper.part(_body, "Cape", Paper.box(Vector3(0.44, 0.62, 0.05)), cape, Vector3(0.0, 1.0, 0.2), Vector3(-0.12, 0.0, 0.0))
	Paper.part(_body, "Shoulders", Paper.sphere(0.22), cloth, Vector3(0.0, 1.3, 0.0), Vector3.ZERO, Vector3(1.05, 0.45, 0.8))

	# Left arm swings; the right hand holds the staff down at his side.
	_arm_l = _pivot(_body, Vector3(-0.25, 1.3, 0.0))
	Paper.part(_arm_l, "Sleeve", Paper.capsule(0.07, 0.5), cloth, Vector3(0.0, -0.22, 0.0))
	Paper.part(_arm_l, "Hand", Paper.sphere(0.065), skin, Vector3(0.0, -0.5, 0.0))
	Paper.part(_body, "SleeveR", Paper.capsule(0.07, 0.5), cloth, Vector3(0.27, 1.07, -0.04), Vector3(0.25, 0.0, 0.1))
	Paper.part(_body, "HandR", Paper.sphere(0.065), skin, Vector3(0.3, 0.84, -0.12))
	Paper.part(_body, "Staff", Paper.cylinder(0.03, 1.9, 6), WOOD, Vector3(0.31, 0.95, -0.14), Vector3(0.06, 0.0, 0.0))

	_head = _pivot(_body, Vector3(0.0, 1.42, 0.0))
	Paper.part(_head, "Face", Paper.sphere(0.155), skin, Vector3(0.0, 0.15, 0.0), Vector3.ZERO, Vector3(1.0, 1.1, 1.0))
	# Head cloth: a cap and a drape down the back of the neck.
	Paper.part(_head, "HeadCloth", Paper.sphere(0.17), cloth.lightened(0.05), Vector3(0.0, 0.22, 0.03), Vector3.ZERO, Vector3(1.0, 0.72, 1.0))
	Paper.part(_head, "Drape", Paper.box(Vector3(0.3, 0.3, 0.05)), cloth.lightened(0.05), Vector3(0.0, 0.08, 0.14), Vector3(0.18, 0.0, 0.0))
	Paper.part(_head, "Band", Paper.cylinder(0.172, 0.04, 8), cape, Vector3(0.0, 0.2, 0.02), Vector3.ZERO, Vector3.ONE, 0.012)
	for side in [-1.0, 1.0]:
		Paper.part(_head, "Eye", Paper.sphere(0.02, 6), INK_DOT, Vector3(0.05 * side, 0.17, -0.14), Vector3.ZERO, Vector3.ONE, 0.0)
	Paper.part(_head, "Beard", Paper.sphere(0.1), Color(0.16, 0.09, 0.05), Vector3(0.0, 0.06, -0.08), Vector3.ZERO, Vector3(1.0, 0.7, 0.8), 0.0)
	Paper.part(_head, "Nose", Paper.sphere(0.025, 6), skin, Vector3(0.0, 0.13, -0.155), Vector3.ZERO, Vector3.ONE, 0.0)


func _pivot(parent: Node3D, at: Vector3) -> Node3D:
	var p := Node3D.new()
	p.position = at
	parent.add_child(p)
	return p
