extends Node
## The King's Camp story. It starts when she walks up from the Faith Journey,
## after chapter 1 is already finished, so David's valley is left as it was.
## Find three gifts, loop a cord three times, then the verse and the charm. It ends
## the way chapter 1 does: the charm ceremony, the finale and the end-of-chapter card.

const JournalContent := preload("res://scripts/journal_content.gd")
const Profiles := preload("res://scripts/profiles.gd")
const Cord := preload("res://scripts/friendship_cord.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")

const Paper := preload("res://scripts/camp_paper.gd")

enum Phase { IDLE, ARRIVE, MEET, FIND, GIVE, CORD, VERSE, CHARM, DONE }

const CHARM_LINE := "Wonder Light: \"A Friendship charm, for Jonathan giving David what was his.\""

var phase: Phase = Phase.IDLE
var _found: int = 0
var _loops: int = 0
var _collected: Array[String] = []
var _checklist: PanelContainer
var _checks: Label
var _cord: Control
var _camera: Node
var _player: Node3D
var _line: Label
var _prompt: Label
var _audio: Node
## Loops already given the chapter-1 tap, so a new loop chimes once.
var _heard_loops: int = 0
## The charm is floating onto the bracelet: Space waits until it has landed.
var _ceremony: bool = false


func begin() -> void:
	if phase != Phase.IDLE and phase != Phase.DONE:
		return
	phase = Phase.ARRIVE
	_found = 0
	_loops = 0
	_collected.clear()
	var main := get_parent().get_parent()
	_line = main.find_child("DialogueLabel", true, false) as Label
	_prompt = main.find_child("PromptLabel", true, false) as Label
	_audio = main.get_node_or_null("AudioDirector")
	_camera = main.get_node_or_null("CameraDirector")
	_player = main.get_node_or_null("Player")
	_build_ui()
	# Coming from chapter 1's end card, its "Chapter Complete!" banner must not hang over the camp.
	var banner := main.find_child("CompleteBanner", true, false) as CanvasItem
	if banner:
		banner.visible = false
	_spawn_gifts()
	_say(
		"Wonder Light: \"This is the king's camp. The day is turning into night.\"",
		"Press Space to continue"
	)


func _input(event: InputEvent) -> void:
	if phase == Phase.IDLE or phase == Phase.FIND or phase == Phase.CORD or phase == Phase.DONE:
		return
	if not _pressed(event):
		return
	_advance()
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if phase != Phase.CORD or not is_instance_valid(_cord):
		return
	if _cord.loops > _heard_loops:
		_heard_loops = _cord.loops
		if _audio and _audio.has_method("play_tap"):
			_audio.play_tap()


func _on_cord_completed() -> void:
	_loops = 3
	phase = Phase.VERSE
	Profiles.unlock_verse(JournalContent.VERSE_SAMUEL_18_1)
	if _audio:
		_audio.play_success()
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
			_collect_overlapping.call_deferred()
		Phase.GIVE:
			phase = Phase.CORD
			_loops = 0
			_heard_loops = 0
			_cord = Cord.new()
			get_parent().get_parent().get_node("UI").add_child(_cord)
			_cord.set_anchors_preset(Control.PRESET_CENTER)
			_cord.position = _cord.get_viewport_rect().size * 0.5 - Vector2(300, 220)
			_cord.completed.connect(_on_cord_completed)
			_say(
				"Wonder Light: \"Hold still, and loop the cord. Three slow loops.\"",
				"Hold Space / Enter or the button, then release to tie"
			)
		Phase.VERSE:
			if is_instance_valid(_cord):
				_cord.queue_free()
			phase = Phase.CHARM
			Profiles.unlock_charm(JournalContent.CHARM_FRIENDSHIP)
			_award_charm()
		Phase.CHARM:
			if _ceremony:
				return
			phase = Phase.DONE
			_finish()
		_:
			pass


func _on_gift(body: Node, area: Area3D) -> void:
	if phase != Phase.FIND or body.name != "Player" or not area.visible:
		return
	area.visible = false
	area.set_deferred("monitoring", false)
	_collected.append(str(area.name))
	_found += 1
	_update_checklist()
	if _audio and _audio.has_method("play_pickup"):
		_audio.play_pickup()
	var light := get_parent().get_parent().get_node_or_null("WonderLight")
	if light and light.has_method("celebrate"):
		light.celebrate()
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
		remove_child(child)
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


func _collect_overlapping() -> void:
	for child in get_children():
		if child is Area3D:
			for body in child.get_overlapping_bodies():
				_on_gift(body, child)


## The same paper ceremony as chapter 1: the Friendship charm floats down onto the
## Virtue Bracelet in a close-up, with the fanfare and a little confetti.
func _award_charm() -> void:
	_say(CHARM_LINE + "\n(Virtue Bracelet receives the charm.)", "…")
	var main := get_parent().get_parent()
	var award := main.get_node_or_null("CharmAward") as Node3D
	var player := main.get_node_or_null("Player") as Node3D
	if award == null or player == null or not award.has_method("play_ceremony"):
		_on_charm_sealed()
		return
	_ceremony = true
	if "can_move" in player:
		player.can_move = false
	award.global_position = player.global_position + Vector3(0.35, 1.15, 0.9)
	var cameras := main.get_node_or_null("CameraDirector")
	if cameras and cameras.has_method("cut_to_charm"):
		cameras.cut_to_charm(award)
	award.ceremony_finished.connect(_on_charm_sealed, CONNECT_ONE_SHOT)
	award.play_ceremony(JournalContent.CHARM_FRIENDSHIP)


## Shown without being read aloud, so the recorded charm line is not cut short.
func _on_charm_sealed() -> void:
	_ceremony = false
	if _line:
		_line.text = CHARM_LINE + "\n(Friendship charm sealed on the Virtue Bracelet.)"
	if _prompt:
		_prompt.text = "Press Space to keep your charm"


## Chapter complete: back to the wide view, the cheer and confetti, the banner, and
## the end-of-chapter card (Play again, Colour my charm, Faith Journey).
func _finish() -> void:
	var main := get_parent().get_parent()
	Profiles.finish_chapter()
	var cameras := main.get_node_or_null("CameraDirector")
	if cameras and cameras.has_method("cut_to_tabletop"):
		cameras.cut_to_tabletop()
	var player := main.get_node_or_null("Player")
	if player and "can_move" in player:
		player.can_move = true
	_say("Wonder Light: \"Friends stay tied together.\"", "Well done, Wonder-Walker!")
	var director := main.get_node_or_null("ChapterDirector")
	if director and director.has_method("play_finale"):
		director.play_finale()
	var menu := main.get_node_or_null("GameMenu")
	if menu and menu.has_method("show_end_panel"):
		menu.show_end_panel(JournalContent.CHARM_FRIENDSHIP)


func _say(text: String, prompt: String) -> void:
	var close := phase == Phase.MEET or phase == Phase.GIVE
	if _player:
		_player.can_move = phase in [Phase.ARRIVE, Phase.FIND, Phase.DONE]
	if _camera:
		if close:
			_camera.move_to_closeup(get_parent().get_node("Jonathan"))
			prompt += "  •  A / D or arrows: look around"
		else:
			_camera.cut_to_tabletop()
	if _checklist:
		_checklist.visible = phase in [Phase.FIND, Phase.GIVE]
	var jon := get_parent().get_node_or_null("Jonathan")
	if jon:
		jon.speaking = text.begins_with("Jonathan:")
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


func get_action_hint() -> String:
	if phase == Phase.CORD:
		return "RELEASE" if is_instance_valid(_cord) and _cord.ready_to_release else "LOOP"
	if phase in [Phase.ARRIVE, Phase.MEET, Phase.GIVE, Phase.VERSE, Phase.CHARM]:
		return "NEXT"
	return ""


func _build_ui() -> void:
	if is_instance_valid(_cord):
		_cord.queue_free()
	if is_instance_valid(_checklist):
		_checklist.queue_free()
	_checklist = PanelContainer.new()
	_checklist.name = "CampGiftChecklist"
	_checklist.position = Vector2(24, 90)
	_checklist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_checklist.add_theme_stylebox_override("panel", PaperUI.panel_style(16, 18))
	_checks = PaperUI.label("", 23, HORIZONTAL_ALIGNMENT_LEFT)
	_checklist.add_child(_checks)
	get_parent().get_parent().get_node("UI").add_child(_checklist)
	_update_checklist()


func _update_checklist() -> void:
	_checks.text = "Gifts for David  %d / 3" % _found
	for gift in ["Robe", "Bow", "Belt"]:
		_checks.text += "\n%s  %s" % ["☑" if gift in _collected else "☐", gift]
