extends Node
## The King's Camp story. It starts when she walks up from the Faith Journey,
## after chapter 1 is already finished, so David's valley is left as it was.
## Find three gifts, loop a cord three times, then the verse and the charm.

const JournalContent := preload("res://scripts/journal_content.gd")
const Profiles := preload("res://scripts/profiles.gd")
const Paper := preload("res://scripts/camp_paper.gd")

enum Phase { IDLE, ARRIVE, MEET, FIND, GIVE, CORD, VERSE, CHARM, DONE }

var phase: Phase = Phase.IDLE
var _found: int = 0
var _loops: int = 0
var _hold: float = 0.0
var _idle: float = 0.0
var _line: Label
var _prompt: Label
var _audio: Node


func begin() -> void:
	if phase != Phase.IDLE and phase != Phase.DONE:
		return
	phase = Phase.ARRIVE
	_found = 0
	_loops = 0
	var main := get_parent().get_parent()
	_line = main.find_child("DialogueLabel", true, false) as Label
	_prompt = main.find_child("PromptLabel", true, false) as Label
	_audio = main.get_node_or_null("AudioDirector")
	_spawn_gifts()
	_say(
		"Wonder Light: \"This is the king's camp. The day is turning blue.\"",
		"Press Space to continue"
	)


func _input(event: InputEvent) -> void:
	if phase == Phase.IDLE or phase == Phase.FIND or phase == Phase.CORD or phase == Phase.DONE:
		return
	if not _pressed(event):
		return
	_advance()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if phase != Phase.CORD:
		return
	var holding := Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)
	if holding:
		_hold += delta
		_idle = 0.0
	else:
		_hold = maxf(_hold - delta, 0.0)
		_idle += delta
	if _hold >= 1.6 or _idle >= 8.0:
		_loops += 1
		_hold = 0.0
		_idle = 0.0
		_mark_loop()
		if _loops >= 3:
			phase = Phase.VERSE
			Profiles.unlock_verse(JournalContent.VERSE_SAMUEL_18_1)
			_say(
				"1 Samuel 18:1 (WEB):\n\"The soul of Jonathan was knit with the soul of David, and Jonathan loved him as his own soul.\"",
				"Press Space to continue"
			)


func _advance() -> void:
	match phase:
		Phase.ARRIVE:
			phase = Phase.MEET
			_say(
				"Jonathan: \"I am Jonathan. David was brave today, because God was with him.\"",
				"Press Space to continue"
			)
		Phase.MEET:
			phase = Phase.FIND
			_say(
				"Wonder Light: \"Find Jonathan's robe, his bow, and his belt. They are gifts for David.\"",
				"Walk up to a gift"
			)
		Phase.GIVE:
			phase = Phase.CORD
			_loops = 0
			_say(
				"Wonder Light: \"Hold still, and loop the cord. Three slow loops.\"",
				"Hold Space, or just wait"
			)
		Phase.VERSE:
			phase = Phase.CHARM
			Profiles.unlock_charm(JournalContent.CHARM_FRIENDSHIP)
			_say(
				"Wonder Light: \"A Friendship charm, for Jonathan giving David what was his.\"",
				"Press Space to continue"
			)
		Phase.CHARM:
			phase = Phase.DONE
			_say(
				"Wonder Light: \"Friends stay tied together.\"",
				"The King's Camp"
			)
		_:
			pass


func _on_gift(body: Node, area: Area3D) -> void:
	if phase != Phase.FIND or body.name != "Player" or not area.visible:
		return
	area.visible = false
	area.monitoring = false
	_found += 1
	var flavor := {
		"Robe": "Wonder Light: \"A folded robe. Jonathan is giving it to David.\"",
		"Bow": "Wonder Light: \"A bow with no arrow. It is a gift, not a fight.\"",
		"Belt": "Wonder Light: \"A belt with one gold square. A friend shares what he has.\"",
	}
	if _found < 3:
		_say(flavor.get(area.name, ""), "Find the rest")
		return
	phase = Phase.GIVE
	_say(
		"Jonathan: \"These were mine. I give them to David, because he is my friend.\"",
		"Press Space to continue"
	)


func _spawn_gifts() -> void:
	for child in get_children():
		child.queue_free()
	var camp: Node = get_parent()
	var here: Vector3 = camp._clearing
	# Spread across the camp: by the king's tent, out at the lookout, and in the supply corner.
	_gift("Robe", _robe(), here + Vector3(-5.2, 0.0, 3.0))
	_gift("Bow", _bow(), here + Vector3(6.0, 0.0, -6.8))
	_gift("Belt", _belt(), here + Vector3(7.8, 0.0, 8.4))


func _gift(gift_name: String, shown: Node3D, at: Vector3) -> void:
	var area := Area3D.new()
	area.name = gift_name
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.15
	shape.shape = sphere
	area.add_child(shape)
	area.add_child(shown)
	add_child(area)
	var ground: Vector3 = get_parent()._ground(at)
	area.global_position = ground + Vector3(0.0, 0.45, 0.0)
	# The gift itself rests on the ground, turned a little toward the camera.
	shown.position = Vector3(0.0, -0.45, 0.0)
	shown.rotation.y = 0.35
	area.body_entered.connect(_on_gift.bind(area))


## Icons, not tiny copies of real clothes: a folded rectangle of deep blue with one gold edge.
func _robe() -> Node3D:
	var root := Node3D.new()
	Paper.part(root, "Fold", Paper.box(Vector3(0.62, 0.1, 0.46)), Color(0.25, 0.38, 0.62), Vector3(0.0, 0.05, 0.0))
	Paper.part(root, "Top", Paper.box(Vector3(0.56, 0.08, 0.4)), Color(0.28, 0.42, 0.68), Vector3(0.02, 0.14, -0.01))
	Paper.part(root, "Edge", Paper.box(Vector3(0.58, 0.085, 0.07)), Color(0.86, 0.68, 0.28), Vector3(0.02, 0.145, 0.17), Vector3.ZERO, Vector3.ONE, 0.0)
	return root


## One curved piece with a single string, propped on a stone. No arrow anywhere near it.
func _bow() -> Node3D:
	var root := Node3D.new()
	Paper.part(root, "Stone", Paper.sphere(0.2, 7), Color(0.58, 0.58, 0.62), Vector3(0.0, 0.08, 0.05), Vector3.ZERO, Vector3(1.4, 0.6, 1.0))
	var bow := Node3D.new()
	bow.position = Vector3(0.0, 0.2, 0.0)
	bow.rotation.x = -0.9
	root.add_child(bow)
	var wood := Color(0.52, 0.32, 0.16)
	var radius := 0.42
	var steps := 7
	for i in steps:
		var a0 := lerpf(-1.15, 1.15, float(i) / steps)
		var a1 := lerpf(-1.15, 1.15, float(i + 1) / steps)
		var p0 := Vector3(sin(a0) * radius, 0.0, -cos(a0) * radius + radius)
		var p1 := Vector3(sin(a1) * radius, 0.0, -cos(a1) * radius + radius)
		_stick(bow, p0, p1, 0.028, wood)
	var end_a := Vector3(sin(-1.15) * radius, 0.0, -cos(1.15) * radius + radius)
	var end_b := Vector3(sin(1.15) * radius, 0.0, -cos(1.15) * radius + radius)
	_stick(bow, end_a, end_b, 0.007, Color(0.92, 0.88, 0.78), 0.0)
	return root


## A short brown loop with one small gold square.
func _belt() -> Node3D:
	var root := Node3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.17
	ring.outer_radius = 0.24
	ring.rings = 4
	ring.ring_segments = 12
	Paper.part(root, "Loop", ring, Color(0.45, 0.27, 0.13), Vector3(0.0, 0.04, 0.0), Vector3.ZERO, Vector3(1.0, 0.6, 1.0))
	Paper.part(root, "Buckle", Paper.box(Vector3(0.11, 0.06, 0.11)), Color(0.86, 0.68, 0.28), Vector3(0.0, 0.06, 0.205), Vector3.ZERO, Vector3.ONE, 0.012)
	return root


func _stick(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color, line: float = 0.012) -> void:
	var d := to - from
	var mi := Paper.part(parent, "Stick", Paper.cylinder(radius, d.length(), 6), color, (from + to) * 0.5, Vector3.ZERO, Vector3.ONE, line)
	var up := d.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	mi.basis = Basis(side, up, side.cross(up)).orthonormalized()


func _mark_loop() -> void:
	if _prompt:
		_prompt.text = "Loop %d of 3" % _loops


func _say(text: String, prompt: String) -> void:
	if _line:
		_line.text = text
	if _prompt:
		_prompt.text = prompt
	if _audio and _audio.has_method("speak_dialogue"):
		_audio.speak_dialogue(text)


func _pressed(event: InputEvent) -> bool:
	# ui_accept (Space/Enter) plus raw key fallback — unhandled path can miss Space
	# when a Control has focus or InputMap keycode matching is flaky.
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		var pk: int = event.physical_keycode
		return k == KEY_SPACE or pk == KEY_SPACE or k == KEY_ENTER or pk == KEY_ENTER
	return false
