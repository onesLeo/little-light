extends Node
## The King's Camp story. It starts when she walks up from the Faith Journey,
## after chapter 1 is already finished, so David's valley is left as it was.
## Find three gifts, loop a cord three times, then the verse and the charm. It ends
## the way chapter 1 does: the charm ceremony, the finale and the end-of-chapter card.

const JournalContent := preload("res://scripts/journal_content.gd")
const Profiles := preload("res://scripts/profiles.gd")
const Cord := preload("res://scripts/friendship_cord.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")
const WordChip := preload("res://scripts/word_chip.gd")
const GiftChecklist := preload("res://scripts/gift_checklist.gd")
const Hints := preload("res://scripts/wonder_item_hints.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
## The camp's lines, with their easier versions and clips (dialogue_lines.gd).
const LINES := preload("res://assets/dialogue/kings_camp.tres")
const DevicePrompts := preload("res://scripts/device_prompts.gd")

const Paper := preload("res://scripts/camp_paper.gd")
const SoundLibrary := preload("res://scripts/sound_library.gd")

enum Phase { IDLE, ARRIVE, MEET, FIND, GIVE, WORDS, CORD, VERSE, CHARM, DONE }

## Seconds with no gift found before the golden arrow shows the way (chapter 1 waits 18).
const HINT_DELAY := 14.0
const WORD_LABELS: PackedStringArray = ["Knit", "Loved", "Friend"]
const WORD_LINES: PackedStringArray = ["Knit.", "Loved.", "Friend."]

var phase: Phase = Phase.IDLE
var _found: int = 0
var _loops: int = 0
var _collected: Array[String] = []
var _checklist: GiftChecklist
## The golden arrow that points at the next gift when the child has found nothing for a while.
var _hints: Hints
var _cord: Control
var _camera: Node
var _player: Node3D
var _line: Label
var _prompt: Label
var _prompt_raw: String = ""
var _audio: Node
## Loops already given the chapter-1 tap, so a new loop chimes once.
var _heard_loops: int = 0
## The charm is floating onto the bracelet: Space waits until it has landed.
var _ceremony: bool = false
var _words: HBoxContainer
var _word_buttons: Array[Button] = []
var _word_said: Array[bool] = [false, false, false]
var _words_done: bool = false
var _world_loops: Array[MeshInstance3D] = []
var _lookout_said: bool = false
var _bleat_wait: float = 6.0
var _bleat: AudioStreamPlayer3D


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
	var input_setup := main.get_node_or_null("InputSetup")
	if input_setup and input_setup.has_signal("device_changed") and not input_setup.device_changed.is_connected(_on_device_changed):
		input_setup.device_changed.connect(_on_device_changed)
	_build_ui()
	if _hints:
		_hints.stop()
	_clear_given()
	_clear_world_cord()
	_lookout_said = false
	_words_done = false
	_word_said = [false, false, false] as Array[bool]
	_bleat_wait = 6.0
	# Coming from chapter 1's end card, its "Chapter Complete!" banner must not hang over the camp.
	var banner := main.find_child("CompleteBanner", true, false) as CanvasItem
	if banner:
		banner.visible = false
	_spawn_gifts()
	_say([&"arrive"], "Press Space to continue")


## Another story is starting: this one stops listening and puts its cards away. The next
## visit begins it again from the first line, as begin() does from IDLE.
func stand_down() -> void:
	phase = Phase.IDLE
	_ceremony = false
	if _hints:
		_hints.stop()
	for card in [_checklist, _words, _cord]:
		if is_instance_valid(card):
			card.visible = false


## The checklist, the word chips and the cord card live in the shared UI, outside the camp,
## so they go with it. They leave the UI at once, so a replay's new ones keep their names.
func _exit_tree() -> void:
	for node in [_checklist, _words, _cord]:
		if is_instance_valid(node):
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()


func _input(event: InputEvent) -> void:
	if phase == Phase.IDLE or phase == Phase.FIND or phase == Phase.CORD or phase == Phase.DONE:
		return
	if phase == Phase.WORDS and not _words_done:
		return
	if not _pressed(event):
		return
	_advance()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_grow_world_cord()
	_watch_lookout(delta)
	if phase != Phase.CORD or not is_instance_valid(_cord):
		return
	if _cord.loops > _heard_loops:
		_heard_loops = _cord.loops
		if _audio and _audio.has_method("play_tap"):
			_audio.play_tap()


func _on_cord_completed() -> void:
	_loops = 3
	phase = Phase.VERSE
	# The cord card sits on the dialogue bar. Take it away before the verse is shown.
	if is_instance_valid(_cord):
		_cord.visible = false
		_cord.queue_free()
	Profiles.unlock_verse(JournalContent.VERSE_SAMUEL_18_1)
	if _audio:
		_audio.play_success()
	_say_text(JournalContent.verse_card(JournalContent.VERSE_SAMUEL_18_1), "Press Space to continue")


func _advance() -> void:
	match phase:
		Phase.ARRIVE:
			phase = Phase.MEET
			_say([&"jonathan_hello"], "Press Space to continue")
		Phase.MEET:
			phase = Phase.FIND
			_say([&"find"], "Walk up to a gift")
			_collect_overlapping.call_deferred()
			_watch_gifts()
		Phase.GIVE:
			phase = Phase.WORDS
			_word_said = [false, false, false] as Array[bool]
			_words_done = false
			_restyle_words()
			# An existing Wonder Light recording, so this beat stays in her voice.
			_say([&"tied"], "Tap Knit, Loved, and Friend")
		Phase.WORDS:
			if not _words_done:
				return
			phase = Phase.CORD
			_loops = 0
			_heard_loops = 0
			_cord = Cord.new()
			get_parent().get_parent().get_node("UI").add_child(_cord)
			_cord.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			_cord.offset_left = -Cord.PANEL.x * 0.5
			_cord.offset_right = Cord.PANEL.x * 0.5
			_cord.completed.connect(_on_cord_completed)
			_build_world_cord()
			_say([&"cord"], "Hold Space / Enter or the button, then release to tie")
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
	_place_beside_david(str(area.name))
	_update_checklist()
	if _hints:
		_hints.found(str(area.name))
	if _audio and _audio.has_method("play_pickup"):
		_audio.play_pickup()
	var light := get_parent().get_parent().get_node_or_null("WonderLight")
	if light and light.has_method("celebrate"):
		light.celebrate()
	var flavor := {"Robe": &"robe", "Bow": &"bow", "Belt": &"belt"}
	if _found < 3:
		_say([flavor[String(area.name)]], "Find the rest")
		return
	phase = Phase.GIVE
	if _hints:
		_hints.stop()
	_say([&"jonathan_give"], "Press Space to continue")


func _spawn_gifts() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var camp: Node = get_parent()
	var here: Vector3 = camp._clearing
	# By the king's tent, out toward the lookout, and in the open on the right.
	_gift("Robe", _robe(), here + Vector3(-5.2, 0.0, 3.0))
	_gift("Bow", _bow(), here + Vector3(4.6, 0.0, -5.4))
	_gift("Belt", _belt(), here + Vector3(8.4, 0.0, 2.2))


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
	_say([&"charm", &"charm_arrives"], "…")
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
		_line.text = LINES.block([&"charm", &"charm_sealed"], GameSettings.easy_words)["text"]
	_set_prompt("Press Space to keep your charm")


## Chapter complete: back to the wide view, the cheer and confetti, the banner, and
## the end-of-chapter card (Play again, Colour my charm, Faith Journey).
func _finish() -> void:
	var main := get_parent().get_parent()
	Profiles.finish_chapter(Profiles.CHAPTER_CAMP)
	var cameras := main.get_node_or_null("CameraDirector")
	if cameras and cameras.has_method("cut_to_tabletop"):
		cameras.cut_to_tabletop()
	var player := main.get_node_or_null("Player")
	if player and "can_move" in player:
		player.can_move = true
	_say([&"tied"], "Well done, Wonder-Walker!")
	if main.has_method("play_finale"):
		main.play_finale("Chapter 2 Complete!")
	var menu := main.get_node_or_null("GameMenu")
	if menu and menu.has_method("show_end_panel"):
		menu.show_end_panel(JournalContent.CHARM_FRIENDSHIP)


## The found gift leaves the meadow and sits in a row beside David, so the giving is visible.
func _place_beside_david(gift_name: String) -> void:
	var david := get_parent().get_parent().get_node_or_null("Valley/DavidMentor") as Node3D
	if david == null:
		return
	var holder := get_parent().get_node_or_null("GivenGifts") as Node3D
	if holder == null:
		holder = Node3D.new()
		holder.name = "GivenGifts"
		get_parent().add_child(holder)
	var shown: Node3D
	var slot := 0
	if gift_name == "Robe":
		shown = _robe()
		slot = 0
	elif gift_name == "Bow":
		shown = _bow()
		slot = 1
	else:
		shown = _belt()
		slot = 2
	shown.name = "Given" + gift_name
	holder.add_child(shown)
	var right := david.global_transform.basis.x
	var forward := -david.global_transform.basis.z
	var pos := david.global_position + right * (0.72 + float(slot) * 0.46) + forward * 0.2
	var ground: Vector3 = get_parent()._ground(pos)
	shown.global_position = ground
	shown.scale = Vector3.ONE * 0.85


func _clear_given() -> void:
	var given := get_parent().get_node_or_null("GivenGifts")
	if given:
		for child in given.get_children():
			child.queue_free()


func press_word(index: int) -> void:
	if phase != Phase.WORDS or index < 0 or index >= WORD_LINES.size():
		return
	_word_said[index] = true
	_restyle_words()
	(_word_buttons[index] as WordChip).pop()
	var light := get_parent().get_parent().get_node_or_null("WonderLight")
	if light and light.has_method("celebrate"):
		light.celebrate()
	# Same narrator path as Wonder Light's other lines: the recorded clip, not system speech.
	if _audio and _audio.has_method("play_line"):
		_audio.play_line(WORD_LINES[index])
	for said in _word_said:
		if not said:
			return
	if _words_done:
		return
	_words_done = true
	_set_prompt("Press Space to loop the cord")
	if _audio and _audio.has_method("play_success"):
		_audio.play_success()


func _restyle_words() -> void:
	if _words:
		_words.visible = phase == Phase.WORDS
		_place_above_dialogue(_words, 118.0)
	var next := _word_said.find(false)
	for i in _word_buttons.size():
		var chip := _word_buttons[i] as WordChip
		chip.set_lit(i < _word_said.size() and _word_said[i])
		chip.set_beckon(i == next)


## Three cream-gold loops in the firelight. The panel at the bottom is only the control.
func _build_world_cord() -> void:
	_clear_world_cord()
	var camp := get_parent()
	var at: Vector3 = camp._at(camp.FIRE) + Vector3(0.0, 0.78, 1.2)
	for i in 3:
		var loop := MeshInstance3D.new()
		loop.name = "CordLoop%d" % i
		var ring := TorusMesh.new()
		ring.inner_radius = 0.1
		ring.outer_radius = 0.17
		ring.rings = 8
		ring.ring_segments = 14
		loop.mesh = ring
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.78, 0.48)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(0.85, 0.48, 0.14)
		mat.emission_energy_multiplier = 0.35
		loop.material_override = mat
		loop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		camp.add_child(loop)
		loop.global_position = at + Vector3(float(i - 1) * 0.42, 0.0, 0.0)
		loop.rotation.x = PI * 0.5
		loop.scale = Vector3.ONE * 0.08
		_world_loops.append(loop)


func _grow_world_cord() -> void:
	if phase != Phase.CORD or not is_instance_valid(_cord):
		return
	for i in _world_loops.size():
		var amount := 0.0
		if i < _cord.loops:
			amount = 1.0
		elif i == _cord.loops:
			amount = _cord.progress
		var loop := _world_loops[i]
		loop.scale = Vector3.ONE * lerpf(0.08, 1.0, amount)
		var mat := loop.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.86, 0.79, 0.64).lerp(Color(0.96, 0.74, 0.28), amount)


func _clear_world_cord() -> void:
	for loop in _world_loops:
		if is_instance_valid(loop):
			loop.queue_free()
	_world_loops.clear()


func _watch_lookout(delta: float) -> void:
	if _player == null or phase not in [Phase.FIND, Phase.DONE]:
		_set_lookout(0.0)
		return
	var camp := get_parent()
	var stone: Vector3 = camp._at(camp.LOOKOUT)
	var near := Vector2(_player.global_position.x, _player.global_position.z).distance_to(Vector2(stone.x, stone.z)) < 3.4
	_set_lookout(1.0 if near else 0.0)
	if not near:
		return
	_bleat_wait -= delta
	if _bleat_wait <= 0.0 and (_audio == null or not _audio.is_speaking()):
		_bleat_wait = randf_range(14.0, 22.0)
		_play_bleat(stone)
	if _lookout_said or phase != Phase.FIND:
		return
	_lookout_said = true
	_say([&"lookout"], "The waterfall is the way you came")


func _set_lookout(amount: float) -> void:
	var soundscape := get_parent().get_parent().get_node_or_null("Soundscape")
	if soundscape and soundscape.has_method("set_lookout"):
		soundscape.set_lookout(amount)


func _play_bleat(at: Vector3) -> void:
	var clip := SoundLibrary.bleat(0)
	if clip == null:
		return
	if _bleat == null:
		_bleat = AudioStreamPlayer3D.new()
		_bleat.name = "FarSheep"
		_bleat.unit_size = 4.0
		_bleat.max_distance = 28.0
		_bleat.volume_db = -10.0
		get_parent().add_child(_bleat)
	_bleat.global_position = at + Vector3(0.0, -6.0, -8.0)
	_bleat.stream = clip
	_bleat.play()


## Shows the camp's lines `ids` (assets/dialogue/kings_camp.tres) and reads them aloud, each
## in its own clip. A child with Easy words on gets the easier version of each.
func _say(ids: Array, prompt: String) -> void:
	var said: Dictionary = LINES.block(ids, GameSettings.easy_words)
	_present(said["text"], prompt)
	if _audio and _audio.has_method("speak_lines"):
		_audio.speak_lines(said["spoken"])


## Shows and reads text that is not one of the camp's own lines: the verse, which the journal
## shares, and whose clips are found by its words (vo_library.gd).
func _say_text(text: String, prompt: String) -> void:
	_present(text, prompt)
	if _audio and _audio.has_method("speak_dialogue"):
		_audio.speak_dialogue(text)


func _present(text: String, prompt: String) -> void:
	var close := phase == Phase.MEET or phase == Phase.GIVE or phase == Phase.WORDS
	if _player:
		_player.can_move = phase in [Phase.FIND, Phase.DONE]
	if _camera:
		if close:
			_camera.move_to_closeup(get_parent().get_node("Jonathan"))
			prompt += "  •  A / D or arrows: look around"
		else:
			_camera.cut_to_tabletop()
	if _checklist:
		_checklist.visible = phase in [Phase.FIND, Phase.GIVE]
	_restyle_words()
	var jon := get_parent().get_node_or_null("Jonathan")
	if jon:
		jon.speaking = text.begins_with("Jonathan:")
	var shell := get_parent().get_parent()
	if _line:
		_line.text = text
	_set_prompt(prompt)
	# The bar fits this line (not the last one of chapter 1), then the cards sit above it.
	if shell.has_method("fit_dialogue"):
		shell.fit_dialogue()
	if is_instance_valid(_cord):
		_place_above_dialogue(_cord, Cord.PANEL.y)
	if _words and _words.visible:
		_place_above_dialogue(_words, 118.0)


## Prompts are written for the keyboard and worded for the device used last (device_prompts.gd).
## The prompt is kept as written, so switching device mid-line rewords it.
func _set_prompt(raw: String) -> void:
	_prompt_raw = raw
	if _prompt:
		var input_setup := get_parent().get_parent().get_node_or_null("InputSetup")
		_prompt.text = DevicePrompts.reword(raw, input_setup, DevicePrompts.GOLD_BUTTON, "LOOP")


func _on_device_changed(_mode: String) -> void:
	if phase == Phase.IDLE:
		return
	_set_prompt(_prompt_raw)
	var shell := get_parent().get_parent()
	if shell.has_method("fit_dialogue"):
		shell.fit_dialogue()


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
	if phase == Phase.WORDS:
		return "NEXT" if _words_done else ""
	if phase in [Phase.ARRIVE, Phase.MEET, Phase.GIVE, Phase.VERSE, Phase.CHARM]:
		return "NEXT"
	return ""


func _build_ui() -> void:
	if is_instance_valid(_cord):
		_cord.queue_free()
	if is_instance_valid(_checklist):
		_checklist.queue_free()
	_checklist = GiftChecklist.new()
	_checklist.name = "CampGiftChecklist"
	_checklist.position = Vector2(24, 90)
	var ui := get_parent().get_parent().get_node("UI")
	ui.add_child(_checklist)
	_build_words(ui)
	_update_checklist()


func _build_words(ui: Node) -> void:
	if is_instance_valid(_words):
		_words.queue_free()
	_word_buttons.clear()
	_words = HBoxContainer.new()
	_words.name = "CampWords"
	_words.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_words.offset_left = -380.0
	_words.offset_right = 380.0
	_words.alignment = BoxContainer.ALIGNMENT_CENTER
	# Room between the words so each one's glow stays its own.
	_words.add_theme_constant_override("separation", 40)
	_words.visible = false
	ui.add_child(_words)
	for i in WORD_LABELS.size():
		var chip := WordChip.new(WORD_LABELS[i], Vector2(190, 86), 34)
		chip.pressed.connect(press_word.bind(i))
		_words.add_child(chip)
		_word_buttons.append(chip)


## Sits a card just above the story's dialogue bar (whatever height the bar is now), so the
## words and the cord never cover the line being read.
func _place_above_dialogue(card: Control, height: float) -> void:
	var bar := get_parent().get_parent().get_node_or_null("UI/Panel") as Control
	var top := -200.0
	if bar:
		top = bar.offset_bottom - maxf(bar.offset_bottom - bar.offset_top, bar.get_combined_minimum_size().y)
	card.offset_bottom = top - 22.0
	card.offset_top = card.offset_bottom - height


func _update_checklist() -> void:
	_checklist.set_found(_collected)


## The golden arrow from chapter 1's hunt, pointing at the nearest gift still in the camp.
func _watch_gifts() -> void:
	if _hints == null:
		_hints = Hints.new()
		_hints.name = "GiftHints"
		_hints.main = get_parent().get_parent()
		_hints.hint_delay = HINT_DELAY
		get_parent().add_child(_hints)
	var gifts: Array = []
	for child in get_children():
		if child is Area3D and child.visible:
			gifts.append(child)
	_hints.watch(gifts)
	for gift in _collected:
		_hints.found(gift)
