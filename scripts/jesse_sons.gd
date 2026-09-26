extends Node3D
## Jesse's seven older sons (1 Samuel 16:10), standing in a row in front of the house.
## They are the Blender paper people, like Samuel, Jesse and David (story_person.gd), from two
## models: the three eldest bearded ("brother"), the four younger clean-shaven
## ("brother_young"), each tinted his own tunic, sash and hair and a little taller or shorter,
## so they read as brothers. They blink and breathe but have no lines of their own.
##
## While they wait they are never frozen: each glances about and shifts his weight on his own
## timing. On cue (pass_before) each steps forward twice into the light in front of Samuel,
## holds a moment, and steps back as the next one comes, a little off a fixed beat, about nine
## seconds for all seven. They are shown with dignity: nobody is mocked, and nobody is sent away.
## Built facing -Z, like the other paper people.


signal procession_finished

const StoryPerson := preload("res://scripts/story_person.gd")

## Each brother's colours, multiplied onto the models' light cloth and hair (story_person.gd
## tint). Warm, earthy and all different, none as golden as David's tunic.
const TUNICS := [Color(0.62, 0.36, 0.26), Color(0.54, 0.48, 0.3), Color(0.4, 0.5, 0.4),
		Color(0.55, 0.3, 0.34), Color(0.52, 0.4, 0.5), Color(0.66, 0.42, 0.3), Color(0.46, 0.52, 0.58)]
const UNDER := [Color(0.76, 0.7, 0.58), Color(0.5, 0.4, 0.3), Color(0.72, 0.66, 0.52),
		Color(0.46, 0.44, 0.36), Color(0.78, 0.72, 0.6), Color(0.5, 0.38, 0.28), Color(0.74, 0.68, 0.56)]
const SASHES := [Color(0.86, 0.74, 0.52), Color(0.32, 0.24, 0.16), Color(0.82, 0.66, 0.42),
		Color(0.32, 0.32, 0.24), Color(0.84, 0.76, 0.6), Color(0.28, 0.22, 0.14), Color(0.82, 0.72, 0.52)]
const SKINS := [Color(1.0, 1.0, 1.0), Color(0.88, 0.84, 0.82), Color(0.96, 0.95, 0.93)]
const HAIR := [Color(0.26, 0.17, 0.11), Color(0.34, 0.22, 0.13), Color(0.2, 0.13, 0.08)]
## The eldest (Eliab, whose height Samuel noticed) is the tallest, down to the seventh; each is
## a share of his model's own height, and none is as small as David.
const HEIGHTS := [1.06, 1.03, 1.0, 1.04, 1.02, 1.0, 0.98]
## How many of the eldest have beards (the "brother" model).
const BEARDED := 3
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


## One brother: a Blender paper person (story_person.gd) that walks when he steps out, and
## while he waits glances about now and then.
class Brother extends Node3D:
	var home := Vector3.ZERO
	var _index: int = 0
	var _person: Node3D
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
		_person = Node3D.new()
		_person.name = "Person"
		_person.set_script(StoryPerson)
		_person.who = "brother" if _index < BEARDED else "brother_young"
		add_child(_person)
		_person.tint({"Tunic": TUNICS[_index % TUNICS.size()], "UnderTunic": UNDER[_index % UNDER.size()],
				"Sash": SASHES[_index % SASHES.size()], "Hair": HAIR[_index % HAIR.size()], "Skin": SKINS[_index % SKINS.size()]})
		scale = Vector3.ONE * HEIGHTS[_index]

	func person() -> Node3D:
		return _person

	## Turns to look at a world point (the model faces -Z).
	func face(point: Vector3) -> void:
		var to := point - global_position
		rotation.y = atan2(-to.x, -to.z)

	func set_walking(on: bool) -> void:
		_person.walk_amount = 1.0 if on else 0.0

	func _process(delta: float) -> void:
		_time += delta
		if _person.walk_amount > 0.0:
			_person.look_aside = lerpf(_person.look_aside, 0.0, minf(1.0, delta * 4.0))
			return
		# Standing: now and then a glance about (the person breathes and sways on its own).
		_glance_wait -= delta
		if _glance_wait <= 0.0 and _glance_t >= 1.0:
			_glance_from = _person.look_aside
			_glance_to = randf_range(-0.6, 0.6)
			_glance_t = 0.0
			_glance_wait = randf_range(3.0, 7.0)
		if _glance_t < 1.0:
			_glance_t = minf(_glance_t + delta / 1.4, 1.0)
			_person.look_aside = lerpf(_glance_from, _glance_to, smoothstep(0.0, 1.0, _glance_t))
