extends Node
## The King's Camp story. It starts when she walks up from the Faith Journey,
## after chapter 1 is already finished, so David's valley is left as it was.
## Find three gifts, loop a cord three times, then the verse and the charm.

const JournalContent := preload("res://scripts/journal_content.gd")
const Profiles := preload("res://scripts/profiles.gd")

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
	_gift("Robe", _box(Vector3(0.55, 0.12, 0.4), Color(0.25, 0.38, 0.62)), here + Vector3(-3.0, 0.0, 1.0))
	_gift("Bow", _bow(), here + Vector3(2.6, 0.0, 1.6))
	_gift("Belt", _belt(), here + Vector3(0.4, 0.0, -2.0))


func _gift(gift_name: String, mesh: Mesh, at: Vector3) -> void:
	var area := Area3D.new()
	area.name = gift_name
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.15
	shape.shape = sphere
	area.add_child(shape)
	var shown := MeshInstance3D.new()
	shown.mesh = mesh
	area.add_child(shown)
	add_child(area)
	var ground: Vector3 = get_parent()._ground(at)
	area.global_position = ground + Vector3(0.0, 0.45, 0.0)
	area.body_entered.connect(_on_gift.bind(area))


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
	if event.is_action_pressed("ui_accept"):
		return true
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE


func _box(size: Vector3, color: Color) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _mat(color)
	return mesh


func _bow() -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.28
	mesh.outer_radius = 0.34
	mesh.rings = 4
	mesh.ring_segments = 8
	mesh.material = _mat(Color(0.45, 0.28, 0.14))
	return mesh


func _belt() -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.16
	mesh.outer_radius = 0.22
	mesh.rings = 4
	mesh.ring_segments = 8
	mesh.material = _mat(Color(0.4, 0.24, 0.12))
	return mesh


func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return mat
