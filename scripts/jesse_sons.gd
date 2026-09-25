extends Node3D
## Jesse's seven older sons (1 Samuel 16:10), standing in a loose line along the courtyard's side.
## One light paper body shared seven times, the camp guards' way (camp_guard.gd), with a
## different tunic, hair and height each, so they read as brothers without seven face rigs.
## They have no lines of their own.
##
## While they wait they are never frozen: each glances about and shifts his weight on his own
## timing. On cue (pass_before) each steps forward twice into the light in front of Samuel,
## holds a moment, and steps back as the next one comes, a little off a fixed beat, about nine
## seconds for all seven. They are shown with dignity: nobody is mocked, and nobody is sent away.
## Built facing -Z, like the other paper people.

const Paper := preload("res://scripts/camp_paper.gd")

signal procession_finished

const TUNICS := [Color(0.58, 0.32, 0.22), Color(0.5, 0.44, 0.25), Color(0.36, 0.46, 0.35),
		Color(0.68, 0.51, 0.28), Color(0.48, 0.35, 0.45), Color(0.63, 0.39, 0.25), Color(0.42, 0.48, 0.54)]
const SASHES := [Color(0.84, 0.72, 0.5), Color(0.3, 0.22, 0.14), Color(0.8, 0.64, 0.4),
		Color(0.3, 0.3, 0.22), Color(0.82, 0.74, 0.58), Color(0.26, 0.2, 0.12), Color(0.8, 0.7, 0.5)]
const SKINS := [Color(0.78, 0.53, 0.34), Color(0.68, 0.43, 0.27), Color(0.84, 0.61, 0.42)]
const HAIR := [Color(0.2, 0.12, 0.07), Color(0.28, 0.17, 0.09), Color(0.14, 0.09, 0.05)]
## The eldest is the tallest, down to the seventh; none as small as David.
const HEIGHTS := [1.1, 1.08, 1.06, 1.05, 1.03, 1.02, 1.0]
const INK_DOT := Color(0.12, 0.07, 0.04)
## Seconds between one brother setting off and the next (each varies a little), and the parts
## of one brother's turn: out, hold, back.
const STEP_GAP := 1.15
const OUT_TIME := 0.85
const HOLD_TIME := 0.6
const BACK_TIME := 0.85
## How far forward each one steps.
const STEP_OUT := 1.1

var _brothers: Array[Node3D] = []
var _passing: bool = false


## Builds the seven in a line from `start`, each `gap` apart along `along`, all facing `facing`
## (a world point: Samuel's place).
func line_up(start: Vector3, along: Vector3, gap: float, facing: Vector3) -> void:
	for i in 7:
		var brother := Brother.new(i)
		brother.name = "Brother%d" % (i + 1)
		add_child(brother)
		brother.global_position = start + along * gap * float(i)
		brother.face(facing)
		brother.home = brother.global_position
		_brothers.append(brother)


func brothers() -> Array[Node3D]:
	return _brothers


func is_passing() -> bool:
	return _passing


## Each brother in turn steps forward towards `toward`, holds, and returns; procession_finished
## is emitted when the last one is back in line.
func pass_before(toward: Vector3) -> void:
	if _passing:
		return
	_passing = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var start := 0.0
	var last_back := 0.0
	for brother in _brothers:
		var b := brother as Brother
		var forward := (Vector3(toward.x, b.home.y, toward.z) - b.home).normalized() * STEP_OUT
		var tw := create_tween()
		tw.tween_interval(start)
		tw.tween_callback(b.set_walking.bind(true))
		tw.tween_property(b, "global_position", b.home + forward, OUT_TIME).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(b.set_walking.bind(false))
		tw.tween_interval(HOLD_TIME)
		tw.tween_callback(b.set_walking.bind(true))
		tw.tween_property(b, "global_position", b.home, BACK_TIME).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(b.set_walking.bind(false))
		last_back = maxf(last_back, start + OUT_TIME + HOLD_TIME + BACK_TIME)
		start += STEP_GAP + rng.randf_range(-0.12, 0.12)
	var done := create_tween()
	done.tween_interval(last_back + 0.1)
	done.tween_callback(_on_passed)


func _on_passed() -> void:
	_passing = false
	procession_finished.emit()


## One brother: a paper body with a swinging walk, idle glances and weight shifts.
class Brother extends Node3D:
	var home := Vector3.ZERO
	var _index: int = 0
	var _leg_l: Node3D
	var _leg_r: Node3D
	var _arm_l: Node3D
	var _arm_r: Node3D
	var _body: Node3D
	var _head: Node3D
	var _walking: bool = false
	var _phase: float = 0.0
	var _time: float = 0.0
	var _glance_wait: float = 0.0
	var _glance_from: float = 0.0
	var _glance_to: float = 0.0
	var _glance_t: float = 1.0

	func _init(index: int) -> void:
		_index = index

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 61 + _index
		_time = rng.randf() * TAU
		_glance_wait = rng.randf_range(1.0, 5.0)
		_build()
		scale = Vector3.ONE * HEIGHTS[_index]

	## Turns to look at a world point (the model faces -Z).
	func face(point: Vector3) -> void:
		var to := point - global_position
		rotation.y = atan2(-to.x, -to.z)

	func set_walking(on: bool) -> void:
		_walking = on

	func _process(delta: float) -> void:
		_time += delta
		if _walking:
			_phase += delta * 9.0
			var swing := sin(_phase) * 0.4
			_leg_l.rotation.x = swing
			_leg_r.rotation.x = -swing
			_arm_l.rotation.x = -swing * 0.6
			_arm_r.rotation.x = swing * 0.6
			_body.position.y = absf(cos(_phase)) * 0.03
			_head.rotation.y = lerpf(_head.rotation.y, 0.0, minf(1.0, delta * 4.0))
			return
		# Standing: legs settle, weight shifts slowly from foot to foot, and now and then a glance.
		for limb in [_leg_l, _leg_r, _arm_l, _arm_r]:
			limb.rotation.x = lerpf(limb.rotation.x, 0.0, minf(1.0, delta * 6.0))
		_body.position.y = lerpf(_body.position.y, 0.0, minf(1.0, delta * 6.0))
		_body.rotation.z = sin(_time * 0.5) * 0.025
		_glance_wait -= delta
		if _glance_wait <= 0.0 and _glance_t >= 1.0:
			_glance_from = _head.rotation.y
			_glance_to = randf_range(-0.7, 0.7)
			_glance_t = 0.0
			_glance_wait = randf_range(3.0, 7.0)
		if _glance_t < 1.0:
			_glance_t = minf(_glance_t + delta / 1.4, 1.0)
			_head.rotation.y = lerpf(_glance_from, _glance_to, smoothstep(0.0, 1.0, _glance_t))

	func _build() -> void:
		var tunic: Color = TUNICS[_index % TUNICS.size()]
		var sash: Color = SASHES[_index % SASHES.size()]
		var skin: Color = SKINS[_index % SKINS.size()]
		var hair: Color = HAIR[_index % HAIR.size()]
		_leg_l = _pivot(self, Vector3(-0.1, 0.62, 0.0))
		_leg_r = _pivot(self, Vector3(0.1, 0.62, 0.0))
		for leg in [_leg_l, _leg_r]:
			Paper.part(leg, "Leg", Paper.capsule(0.075, 0.62), skin, Vector3(0.0, -0.3, 0.0))
			Paper.part(leg, "Sandal", Paper.box(Vector3(0.12, 0.05, 0.22)), Color(0.3, 0.18, 0.1), Vector3(0.0, -0.6, -0.03))
		_body = Node3D.new()
		_body.name = "Body"
		add_child(_body)
		Paper.part(_body, "Tunic", Paper.cylinder(0.27, 0.74, 8, 0.19), tunic, Vector3(0.0, 0.92, 0.0))
		Paper.part(_body, "Sash", Paper.cylinder(0.225, 0.07, 8), sash, Vector3(0.0, 1.0, 0.0), Vector3.ZERO, Vector3.ONE, 0.015)
		Paper.part(_body, "Shoulders", Paper.sphere(0.22), tunic, Vector3(0.0, 1.3, 0.0), Vector3.ZERO, Vector3(1.05, 0.45, 0.8))
		_arm_l = _pivot(_body, Vector3(-0.25, 1.3, 0.0))
		_arm_r = _pivot(_body, Vector3(0.25, 1.3, 0.0))
		for arm in [_arm_l, _arm_r]:
			Paper.part(arm, "Sleeve", Paper.capsule(0.07, 0.5), tunic, Vector3(0.0, -0.22, 0.0))
			Paper.part(arm, "Hand", Paper.sphere(0.065), skin, Vector3(0.0, -0.5, 0.0))
		_head = _pivot(_body, Vector3(0.0, 1.42, 0.0))
		Paper.part(_head, "Face", Paper.sphere(0.155), skin, Vector3(0.0, 0.15, 0.0), Vector3.ZERO, Vector3(1.0, 1.1, 1.0))
		Paper.part(_head, "Hair", Paper.sphere(0.165), hair, Vector3(0.0, 0.22, 0.03), Vector3.ZERO, Vector3(1.0, 0.72, 1.0))
		for side in [-1.0, 1.0]:
			Paper.part(_head, "Eye", Paper.sphere(0.02, 6), INK_DOT, Vector3(0.05 * side, 0.17, -0.14), Vector3.ZERO, Vector3.ONE, 0.0)
		Paper.part(_head, "Nose", Paper.sphere(0.025, 6), skin, Vector3(0.0, 0.13, -0.155), Vector3.ZERO, Vector3.ONE, 0.0)
		# The three eldest have short beards: grown men, not boys.
		if _index < 3:
			Paper.part(_head, "Beard", Paper.sphere(0.1), hair, Vector3(0.0, 0.06, -0.08), Vector3.ZERO, Vector3(1.0, 0.7, 0.8), 0.0)

	func _pivot(parent: Node3D, at: Vector3) -> Node3D:
		var p := Node3D.new()
		p.position = at
		parent.add_child(p)
		return p
