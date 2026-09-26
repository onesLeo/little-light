extends Node3D
## The great fish God appointed to carry Jonah (Jonah 1:17): a huge, rounded paper shape, closer
## to a gentle whale than a monster, with a small calm eye, broad fins and no teeth at all. It
## rises slowly beneath a warm point of light and eases back down, the way the camp owl glides in
## (camp_owl.gd): a few calm states, each an eased move, never a sudden appearance.
## Built from soft paper blobs like the ark's animals, so there is no model to load. Faces +x;
## its origin is the middle of its back, at the water line when surfaced.

const Paper := preload("res://scripts/camp_paper.gd")

enum State { WAITING, RISING, SURFACED, SINKING }

const SKIN := Color(0.32, 0.45, 0.58)
const BELLY := Color(0.7, 0.78, 0.8)
const FIN := Color(0.27, 0.39, 0.52)
const EYE := Color(0.1, 0.07, 0.05)
const WARM := Color(1.0, 0.82, 0.42)
## How far under the water it waits, and how long it is.
const DEPTH := 3.6
const LENGTH := 8.4

var state: State = State.WAITING
var _time: float = 0.0
var _body: Node3D
var _tail: Node3D
var _fins: Array[Node3D] = []
var _light: MeshInstance3D
var _surface_y: float = 0.0


func _ready() -> void:
	_surface_y = position.y
	_build()
	position.y = _surface_y - DEPTH
	visible = false


func _build() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	Paper.part(_body, "Back", Paper.sphere(1.0, 14), SKIN, Vector3.ZERO, Vector3.ZERO, Vector3(LENGTH * 0.5, 1.5, 1.9), 0.05)
	Paper.part(_body, "Belly", Paper.sphere(1.0, 12), BELLY, Vector3(0.3, -0.55, 0.0), Vector3.ZERO, Vector3(LENGTH * 0.44, 1.05, 1.6), 0.0)
	Paper.part(_body, "Brow", Paper.sphere(1.0, 12), SKIN.lightened(0.05), Vector3(LENGTH * 0.3, 0.25, 0.0), Vector3.ZERO, Vector3(1.6, 1.25, 1.65), 0.0)
	# A small calm eye on each side, with a catch of light: never wide or staring.
	for side in [1.0, -1.0]:
		var eye := Paper.part(_body, "Eye", Paper.sphere(0.13, 8), EYE, Vector3(LENGTH * 0.36, 0.18, side * 1.36), Vector3.ZERO, Vector3(1.0, 0.8, 0.6), 0.0)
		Paper.part(eye, "Catchlight", Paper.sphere(0.04, 6), Color(1.0, 0.98, 0.9), Vector3(0.04, 0.05, side * 0.08), Vector3.ZERO, Vector3.ONE, 0.0)
		var fin := Node3D.new()
		fin.name = "Fin"
		fin.position = Vector3(LENGTH * 0.12, -0.6, side * 1.6)
		_body.add_child(fin)
		Paper.part(fin, "Blade", Paper.sphere(1.0, 8), FIN, Vector3(-0.4, -0.2, side * 0.5), Vector3(0.0, 0.0, side * 0.4), Vector3(1.1, 0.12, 0.7), 0.03)
		_fins.append(fin)
	# Soft stripes along the throat, like folded paper, not teeth.
	for i in 4:
		Paper.part(_body, "Pleat%d" % i, Paper.box(Vector3(0.9, 0.03, 2.6)), BELLY.darkened(0.12), Vector3(LENGTH * 0.18 - i * 0.5, -1.02 + i * 0.03, 0.0),
				Vector3(0.0, 0.0, 0.1), Vector3.ONE, 0.0)
	_tail = Node3D.new()
	_tail.name = "Tail"
	_tail.position = Vector3(-LENGTH * 0.42, 0.1, 0.0)
	_body.add_child(_tail)
	for i in 3:
		var t := float(i) / 3.0
		Paper.part(_tail, "TailPart%d" % i, Paper.sphere(1.0, 10), SKIN.darkened(0.04 * i), Vector3(-0.9 * i, 0.1 * i, 0.0), Vector3.ZERO,
				Vector3(1.1, lerpf(1.1, 0.4, t), lerpf(1.3, 0.5, t)), 0.04)
	# The tail's broad flukes, flat and level like a whale's.
	for side in [1.0, -1.0]:
		Paper.part(_tail, "Fluke", Paper.sphere(1.0, 8), FIN, Vector3(-3.0, 0.35, side * 0.8), Vector3(0.0, side * 0.5, 0.0), Vector3(0.9, 0.1, 1.1), 0.03)
	_light = Paper.halo(2.6, WARM)
	_light.name = "WarmLight"
	_light.position = Vector3(0.0, DEPTH * 0.6, 0.0)
	add_child(_light)


## Rises slowly to the surface beneath its warm light, over `seconds`, easing in and out.
func rise(seconds: float = 4.0) -> Tween:
	state = State.RISING
	visible = true
	var tw := create_tween()
	tw.tween_property(self, "position:y", _surface_y, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void: state = State.SURFACED)
	return tw


## Eases back under the water over `seconds`, and is gone.
func sink(seconds: float = 3.0) -> Tween:
	state = State.SINKING
	var tw := create_tween()
	tw.tween_property(self, "position:y", _surface_y - DEPTH, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		state = State.WAITING
		visible = false)
	return tw


## Already surfaced, at once (carrying on from a saved place, or the shore).
func show_surfaced() -> void:
	visible = true
	position.y = _surface_y
	state = State.SURFACED


func surfaced() -> bool:
	return state == State.SURFACED


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	# A slow sweep of the tail and a lazy beat of the fins; the body breathes on the water.
	_tail.rotation.y = sin(_time * 0.8) * 0.12
	for i in _fins.size():
		_fins[i].rotation.x = sin(_time * 0.9 + float(i) * PI) * 0.12
	_body.position.y = sin(_time * 0.6) * 0.06
	_body.rotation.z = sin(_time * 0.5) * 0.02
	# The warm light glows over it, brightest while it rises.
	var k := 1.0 if state == State.RISING else 0.7
	_light.scale = Vector3.ONE * k * (1.0 + sin(_time * 1.6) * 0.06)
