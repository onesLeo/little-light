extends Node3D
## The camp's owl. Small, paper, wings that open. When the child first reaches
## the clearing it is already gliding in from the side: a few calm wingbeats,
## then it lands on a high branch of the cypress and folds its wings. Perched,
## it blinks, turns its head, settles, and says a soft "hoo-hoo" now and then,
## never while somebody is speaking. After a long while it hops to a second
## branch on the same tree. Built facing -Z.

const Paper := preload("res://scripts/camp_paper.gd")
const SoundLibrary := preload("res://scripts/sound_library.gd")
const SoundBus := preload("res://scripts/sound_bus.gd")

const FEATHER := Color(0.55, 0.43, 0.32)
const FEATHER_DARK := Color(0.42, 0.32, 0.24)
const FACE := Color(0.88, 0.8, 0.66)
const BELLY := Color(0.8, 0.7, 0.55)
const EYE := Color(0.98, 0.84, 0.36)
const PUPIL := Color(0.08, 0.05, 0.03)
const BEAK := Color(0.72, 0.52, 0.3)

enum State { WAITING, FLYING, PERCHED }

## Branch tips to sit on, in world space, and which way the owl faces there.
var perches: Array[Vector3] = []
var facing: float = PI
## Somebody speaking (AudioDirector); the owl keeps quiet while they do.
var audio: Node

var state: State = State.WAITING
var _perch: int = 0
var _from: Vector3
var _via: Vector3
var _to: Vector3
var _t: float = 0.0
var _flight_time: float = 6.0
var _wing_l: Node3D
var _wing_r: Node3D
var _head: Node3D
var _lids: Array[Node3D] = []
var _belly: Node3D
var _blink: float = 3.0
var _turn: float = 4.0
var _head_goal: float = 0.0
var _hoot: float = 6.0
var _stay: float = 70.0
var _hoot_anim: float = 0.0
var _hoot_player: AudioStreamPlayer3D
var _flutter_player: AudioStreamPlayer3D


func _ready() -> void:
	_build()
	scale = Vector3.ONE * 1.35
	visible = false
	_hoot_player = _sound(SoundLibrary.load_stream(SoundLibrary.OWL), -6.0)
	_flutter_player = _sound(SoundLibrary.load_stream(SoundLibrary.FLUTTER), -10.0)
	_flutter_player.pitch_scale = 0.7


## Glide in from off to the side and land on the first branch.
func arrive(from: Vector3) -> void:
	if perches.is_empty() or state != State.WAITING:
		return
	visible = true
	_perch = 0
	_fly(from, perches[0], 6.5)


func is_perched() -> bool:
	return state == State.PERCHED


func _fly(from: Vector3, to: Vector3, seconds: float) -> void:
	state = State.FLYING
	_from = from
	_to = to
	_via = (from + to) * 0.5 + Vector3(0.0, 1.2, 0.0)
	_t = 0.0
	_flight_time = seconds
	global_position = from


func _process(delta: float) -> void:
	match state:
		State.FLYING:
			_update_flight(delta)
		State.PERCHED:
			_update_perched(delta)


func _update_flight(delta: float) -> void:
	_t = minf(_t + delta / _flight_time, 1.0)
	var e := _t * _t * (3.0 - 2.0 * _t)
	var p := _from.lerp(_via, e).lerp(_via.lerp(_to, e), e)
	var ahead := _from.lerp(_via, minf(e + 0.02, 1.0)).lerp(_via.lerp(_to, minf(e + 0.02, 1.0)), minf(e + 0.02, 1.0))
	global_position = p
	var dir := ahead - p
	if dir.length() > 0.001 and _t < 0.92:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 3.0))
	else:
		rotation.y = lerp_angle(rotation.y, facing, minf(1.0, delta * 4.0))
	# Three calm wingbeats, then a long glide, then a couple more to land.
	var beat := 0.0
	if _t < 0.3 or _t > 0.78:
		beat = sin(_t * _flight_time * TAU * 1.1)
	var open := 1.0 if _t < 0.95 else (1.0 - _t) / 0.05
	_wing_l.rotation.z = -(0.25 + 1.05 * open) + beat * 0.45 * open
	_wing_r.rotation.z = (0.25 + 1.05 * open) - beat * 0.45 * open
	if _t >= 1.0:
		state = State.PERCHED
		_wing_l.rotation.z = 0.0
		_wing_r.rotation.z = 0.0
		rotation.y = facing
		_stay = randf_range(60.0, 90.0)
		_hoot = randf_range(3.0, 6.0)
		if _flutter_player.stream and not _speaking():
			_flutter_player.play()


func _update_perched(delta: float) -> void:
	# Blink.
	_blink -= delta
	var lid := 0.0
	if _blink < 0.0:
		lid = clampf(1.0 - absf(_blink + 0.09) / 0.09, 0.0, 1.0)
		if _blink < -0.18:
			_blink = randf_range(2.5, 6.0)
	for l in _lids:
		l.scale.y = maxf(lid, 0.01)
	# A slow turn of the head, now and then.
	_turn -= delta
	if _turn < 0.0:
		_turn = randf_range(3.5, 8.0)
		_head_goal = randf_range(-1.1, 1.1) if randf() < 0.7 else 0.0
	_head.rotation.y = lerp_angle(_head.rotation.y, _head_goal, minf(1.0, delta * 2.2))
	# "Hoo-hoo": a little bob of the head and a puff of the chest while it sounds.
	_hoot -= delta
	if _hoot < 0.0:
		if _speaking():
			_hoot = 2.0
		else:
			_hoot = randf_range(15.0, 25.0)
			_hoot_anim = 1.3
			if _hoot_player.stream:
				_hoot_player.play()
	if _hoot_anim > 0.0:
		_hoot_anim -= delta
		var puff := sin(clampf(1.3 - _hoot_anim, 0.0, 1.3) / 1.3 * TAU * 2.0)
		_belly.scale = Vector3.ONE * (1.0 + maxf(puff, 0.0) * 0.12)
		_head.rotation.x = maxf(puff, 0.0) * 0.18
	else:
		_belly.scale = _belly.scale.lerp(Vector3.ONE, minf(1.0, delta * 5.0))
		_head.rotation.x = lerpf(_head.rotation.x, 0.0, minf(1.0, delta * 5.0))
	# After a long while, a short glide to the other branch.
	_stay -= delta
	if _stay < 0.0 and perches.size() > 1 and _hoot_anim <= 0.0:
		var from := global_position
		_perch = (_perch + 1) % perches.size()
		_fly(from, perches[_perch], 3.2)


func _speaking() -> bool:
	return audio != null and audio.has_method("is_speaking") and audio.is_speaking()


func _sound(stream: AudioStream, db: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.bus = SoundBus.AMBIENCE
	p.volume_db = db
	p.unit_size = 6.0
	p.max_distance = 40.0
	add_child(p)
	return p


func _build() -> void:
	_belly = Node3D.new()
	_belly.position = Vector3(0.0, 0.2, 0.0)
	add_child(_belly)
	Paper.part(_belly, "Body", Paper.sphere(0.15), FEATHER, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.25, 0.95), 0.02)
	Paper.part(_belly, "Chest", Paper.sphere(0.12), BELLY, Vector3(0.0, -0.02, -0.06), Vector3.ZERO, Vector3(0.95, 1.2, 0.7), 0.0)
	for side in [-1.0, 1.0]:
		Paper.part(self, "Foot", Paper.sphere(0.03, 6), BEAK, Vector3(0.05 * side, 0.02, -0.04), Vector3.ZERO, Vector3(1.0, 0.6, 1.4), 0.0)
	Paper.part(self, "Tail", Paper.box(Vector3(0.12, 0.12, 0.03)), FEATHER_DARK, Vector3(0.0, 0.05, 0.1), Vector3(-0.5, 0.0, 0.0), Vector3.ONE, 0.015)

	_wing_l = _wing(-1.0)
	_wing_r = _wing(1.0)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.0, 0.42, 0.0)
	add_child(_head)
	Paper.part(_head, "Head", Paper.sphere(0.13), FEATHER, Vector3.ZERO, Vector3.ZERO, Vector3(1.1, 0.95, 1.0), 0.02)
	Paper.part(_head, "FaceDisc", Paper.sphere(0.11), FACE, Vector3(0.0, -0.01, -0.07), Vector3.ZERO, Vector3(1.05, 0.9, 0.5), 0.0)
	for side in [-1.0, 1.0]:
		Paper.part(_head, "Tuft", Paper.cylinder(0.035, 0.1, 4, 0.0), FEATHER_DARK, Vector3(0.08 * side, 0.12, -0.01), Vector3(0.0, 0.0, -0.35 * side), Vector3.ONE, 0.012)
		var eye := Paper.part(_head, "Eye", Paper.sphere(0.042), EYE, Vector3(0.048 * side, 0.01, -0.115), Vector3.ZERO, Vector3(1.0, 1.0, 0.5), 0.012)
		eye.material_override = Paper.glow_mat(EYE)
		Paper.part(_head, "Pupil", Paper.sphere(0.022, 6), PUPIL, Vector3(0.048 * side, 0.01, -0.135), Vector3.ZERO, Vector3(1.0, 1.0, 0.5), 0.0)
		var lid := Node3D.new()
		lid.position = Vector3(0.048 * side, 0.05, -0.12)
		_head.add_child(lid)
		Paper.part(lid, "Lid", Paper.sphere(0.046), FEATHER, Vector3(0.0, -0.04, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.55), 0.0)
		lid.scale.y = 0.01
		_lids.append(lid)
	Paper.part(_head, "Beak", Paper.cylinder(0.022, 0.06, 4, 0.0), BEAK, Vector3(0.0, -0.04, -0.13), Vector3(PI, 0.0, 0.0), Vector3.ONE, 0.0)


func _wing(side: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "Wing"
	pivot.position = Vector3(0.13 * side, 0.3, 0.02)
	add_child(pivot)
	Paper.part(pivot, "Feathers", Paper.sphere(0.13), FEATHER_DARK, Vector3(0.03 * side, -0.1, 0.0), Vector3.ZERO, Vector3(0.28, 1.25, 0.95), 0.018)
	return pivot
