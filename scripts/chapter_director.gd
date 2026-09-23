extends Node
## Beat walker for David & Goliath P0.2 vertical slice.
## Arrive → Explore (3 Wonder Items) → Meet David (Band A) → Joshua 1:9
## → Steady Hands (breathe the promise) → Off-screen resolution → Reflect
## → Courage charm award.
## Spine: hear the word → she taps the three words → breathe it → watch David walk → keep it.
## Courage comes from God being with David, not from feeling calm.
## No violence shown. Wonder-Walker is a guest, not David.
## The story waits at the start until the "Who is playing?" screen has a child (profile_screen.gd);
## the verse, the charm and the finished chapter go into that child's Faith Journal.

const Profiles := preload("res://scripts/profiles.gd")
const JournalContent := preload("res://scripts/journal_content.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const EasyWords := preload("res://scripts/easy_words.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")

enum Beat {
	ARRIVE,
	MEET_DAVID_A,   # first David lines
	MEET_DAVID_B,   # Band A auto reply + David's thanks
	EXPLORE,
	STEADY_INTRO,   # VO then enable minigame
	STEADY_PLAY,    # waiting on minigame_completed
	STEADY_DONE,    # David's thank-you after minigame
	RESOLUTION,
	REFLECT,
	VERSE_REWARD,   # Joshua 1:9 — played before the breath (see _on_advance)
	CHARM_AWARD,  # Courage charm → Virtue Bracelet ceremony
	DONE,
	CAMP,           # on hold: The King's Camp (chapter_two.gd) has the screen
}

@onready var dialogue_label: Label = %DialogueLabel
@onready var prompt_label: Label = %PromptLabel
@onready var dialogue_panel: PanelContainer = get_node_or_null("../UI/Panel") as PanelContainer
@onready var player: CharacterBody3D = %Player
@onready var steady_hands: Node = %SteadyHands
@onready var camera_director: Node = %CameraDirector
@onready var wonder_light: Node3D = %WonderLight
@onready var audio_director: Node = get_node_or_null("%AudioDirector")
@onready var confetti: Node = get_node_or_null("%ConfettiBurst")
@onready var complete_banner: Label = get_node_or_null("%CompleteBanner") as Label
@onready var david_mentor: Node3D = get_node_or_null("../DavidMentor") as Node3D
@onready var charm_award: Node3D = get_node_or_null("%CharmAward") as Node3D

signal explore_started
signal wonder_item_collected(item_name: String)
signal chapter_finished
signal stood_down

var beat: Beat = Beat.ARRIVE
var wonder_items_found: int = 0
const WONDER_ITEMS_NEEDED: int = 3

const ITEM_FLAVOR := {
	"WonderItem_Stone": "A small stone. God can use even a small thing.",
	"WonderItem_Staff": "A shepherd's staff. David stays with his sheep.",
	"WonderItem_Lamb": "A lamb David is keeping safe. That is his job.",
}
const ITEM_LABELS := {
	"WonderItem_Stone": "stone",
	"WonderItem_Staff": "staff",
	"WonderItem_Lamb": "little lamb",
}

var _advance_ready: bool = false
var _prompt_raw: String = ""
var _last_nudge_ms: int = -100000
var _near_item: Area3D = null
var _items_collected: Dictionary = {}

## Her turn after Joshua 1:9. She taps each word and hears that word. Nothing is
## marked wrong, and the breath does not start until all three have been tapped.
const WORD_LABELS: PackedStringArray = ["Don't", "Be", "Afraid"]
const WORD_LINES: PackedStringArray = ["Don't.", "Be.", "Afraid."]
var _word_phase: String = "" ## "", listen, tap, done
var _word_said: Array[bool] = [false, false, false]
var _word_row: HBoxContainer
var _word_buttons: Array[Button] = []
var _word_halos: Array[StyleBoxFlat] = []
var _word_pulse: Array[Tween] = []

func _ready() -> void:
	dialogue_label.text = ""
	_set_prompt("")
	var input_setup := get_node_or_null("../InputSetup")
	if input_setup and input_setup.has_signal("device_changed"):
		input_setup.device_changed.connect(_on_device_changed)
	if steady_hands and steady_hands.has_signal("minigame_completed"):
		steady_hands.minigame_completed.connect(_on_minigame_completed)
	var items_root := get_node_or_null("../WonderItems")
	if items_root:
		for child in items_root.get_children():
			if child is Area3D:
				child.body_entered.connect(_on_wonder_item_entered.bind(child))
				child.body_exited.connect(_on_wonder_item_exited.bind(child))
	if audio_director and audio_director.has_signal("speech_finished"):
		audio_director.speech_finished.connect(_on_speech_finished)
	_build_word_buttons()
	_start_story()


## Starts the story, or waits for the "Who is playing?" screen when nobody is playing yet.
func _start_story() -> void:
	var picker := get_node_or_null("../ProfileScreen")
	if Profiles.active_id.is_empty() and picker != null:
		picker.profile_chosen.connect(func(_id: String) -> void: _enter_beat(Beat.ARRIVE), CONNECT_ONE_SHOT)
	else:
		_enter_beat(Beat.ARRIVE)

func _is_continue_pressed(event: InputEvent) -> bool:
	# ui_accept (Space/Enter) plus raw key fallback — unhandled path can miss Space
	# when a Control has focus or InputMap keycode matching is flaky.
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		var pk: int = event.physical_keycode
		return k == KEY_SPACE or pk == KEY_SPACE or k == KEY_ENTER or pk == KEY_ENTER
	return false


func _input(event: InputEvent) -> void:
	# During her word turn, Space or NEXT must not skip the three words.
	if beat == Beat.VERSE_REWARD and _word_phase != "done" and _is_continue_pressed(event):
		_open_word_turn()
		get_viewport().set_input_as_handled()
		return
	# Prefer _input over _unhandled_input so dialogue UI cannot swallow Space.
	if _advance_ready and _is_continue_pressed(event):
		_advance_ready = false
		_on_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		_try_collect_near_item()
		get_viewport().set_input_as_handled()

func _enter_beat(next: Beat) -> void:
	if next != Beat.VERSE_REWARD:
		_close_word_turn()
	beat = next
	if audio_director and audio_director.has_method("play_vo"):
		audio_director.play_vo(Beat.keys()[next])
	match beat:
		Beat.ARRIVE:
			_set_player_move(false)
			_cut_tabletop()
			_point_light(null)
			_show(
				"Wonder Light: \"This is David's valley. He looks after sheep. God looks after him.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.EXPLORE:
			_set_player_move(true)
			_cut_tabletop()
			_point_light(null)
			_show(
				"Wonder Light: \"David needs his stone, his staff, and his little lamb. Find them for him!\"",
				_explore_prompt(false)
			)
			_advance_ready = false
			explore_started.emit()

		Beat.MEET_DAVID_A:
			_set_player_move(false)
			# Both turn to face each other — fire the Walker's turn without
			# awaiting it (nothing downstream depends on his facing, unlike
			# David's, which _place_closeup() reads), so they turn at the
			# same time instead of one after the other.
			_face_david(david_mentor)
			await _face_player(david_mentor)
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show(
				"(You bring David the stone, staff, and little lamb.)\nDavid: \"Oh! Hello there. Are you lost too?\"\nDavid: \"Everyone's scared of the big giant. But God gave me these sheep to keep safe.\"\nDavid: \"The Lord kept me safe from the lion and the bear. He will keep me safe now.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.MEET_DAVID_B:
			# Band A: Wonder Light speaks for the child — no reply choices.
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show(
				"Wonder Light: \"God gave David a job: keep the sheep safe. That's why he will go.\"\nDavid: \"Thanks. Will you stay close while I get ready?\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.VERSE_REWARD:
			# The word is given before the breath and the walk, so courage has a
			# source: God is with David. The child says the three words *with* him.
			Profiles.unlock_verse(JournalContent.VERSE_JOSHUA_1_9)
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_celebrate_light()
			_show(
				"Joshua 1:9 (WEB):\n\"Haven't I commanded you? Be strong and of good courage; don't be afraid, neither be dismayed: for Yahweh your God is with you wherever you go.\"\n\nWonder Light: \"This verse has three special words. Can you say them with me?\nDon't. Be. Afraid.\"\nWonder Light: \"Yahweh is God's name. It means He is with you.\"",
				"Listen"
			)
			_advance_ready = false
			_begin_word_listen()

		Beat.STEADY_INTRO:
			_set_player_move(false)
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show(
				"Wonder Light: \"Let's breathe God's promise with David. In: God is with you. Out: don't be afraid.\"\nDavid: \"In... and out. Just like counting sheep.\"",
				"Press Space to begin Steady Hands"
			)
			_advance_ready = true

		Beat.STEADY_PLAY:
			_cut_closeup(david_mentor)
			_show(
				"Wonder Light: \"Breathe with David...\"",
				"Hold Space to breathe in, let go to breathe out"
			)
			_advance_ready = false
			if steady_hands and steady_hands.has_method("start_minigame"):
				steady_hands.start_minigame()

		Beat.STEADY_DONE:
			_cut_closeup(david_mentor)
			_celebrate_light()
			_show(
				"David: \"I still feel small. But I'm not alone. Thank you for staying.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.RESOLUTION:
			# Off-screen resolution — no fight shown. Script doc calls for the
			# camera staying on David's determined face here.
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show(
				"Wonder Light: \"David took the small stone. God can use even a small thing.\"\nWonder Light: \"David walked out to the valley. When it was over, the camp cheered his name.\"\nWonder Light: \"David trusted God, faced Goliath with his sling, and defeated him. The people were safe.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.REFLECT:
			_cut_tabletop()
			_point_light(null)
			_show(
				"Wonder Light: \"Being brave doesn't mean you're not scared. It means you go with God anyway.\"\nWonder Light: \"God had a job for David. He has one for you too. Stay close, and remember the words.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.CHARM_AWARD:
			Profiles.unlock_charm(JournalContent.CHARM_COURAGE)
			_set_player_move(false)
			_advance_ready = false
			_celebrate_light()
			_show(
				"Wonder Light: \"A Courage charm — for staying with David, and breathing God's promise with him.\"\n(Virtue Bracelet receives the charm.)",
				"…"
			)
			if charm_award and camera_director and camera_director.has_method("cut_to_charm"):
				camera_director.cut_to_charm(charm_award)
			elif charm_award:
				_cut_closeup(charm_award)
			if charm_award and charm_award.has_method("play_ceremony"):
				if not charm_award.ceremony_finished.is_connected(_on_charm_ceremony_finished):
					charm_award.ceremony_finished.connect(_on_charm_ceremony_finished, CONNECT_ONE_SHOT)
				charm_award.play_ceremony()
			else:
				# Fallback if node missing — still allow advance.
				_show(
					"Wonder Light: \"A Courage charm — for staying with David, and breathing God's promise with him.\"",
					"Press Space to keep your charm"
				)
				_advance_ready = true

		Beat.DONE:
			Profiles.finish_chapter()
			_set_player_move(true)
			_cut_tabletop()
			_point_light(null)
			_show(
				"Wonder Light: \"God was with David. God is with you.\"",
				"Well done, Wonder-Walker!"
			)
			_advance_ready = false
			_play_finale()
			chapter_finished.emit()

func _on_advance() -> void:
	match beat:
		Beat.ARRIVE:
			_enter_beat(Beat.EXPLORE)
		Beat.MEET_DAVID_A:
			_enter_beat(Beat.MEET_DAVID_B)
		Beat.MEET_DAVID_B:
			_enter_beat(Beat.VERSE_REWARD)
		Beat.VERSE_REWARD:
			if not _words_complete():
				_open_word_turn()
				return
			_close_word_turn()
			_enter_beat(Beat.STEADY_INTRO)
		Beat.STEADY_INTRO:
			_enter_beat(Beat.STEADY_PLAY)
		Beat.STEADY_DONE:
			_enter_beat(Beat.RESOLUTION)
		Beat.RESOLUTION:
			_enter_beat(Beat.REFLECT)
		Beat.REFLECT:
			_enter_beat(Beat.CHARM_AWARD)
		Beat.CHARM_AWARD:
			_enter_beat(Beat.DONE)
		_:
			pass

func _on_minigame_completed() -> void:
	_enter_beat(Beat.STEADY_DONE)

func _on_wonder_item_entered(body: Node3D, area: Area3D) -> void:
	if body != player:
		return
	if _items_collected.has(area.name):
		return
	_near_item = area
	if beat == Beat.EXPLORE:
		_set_prompt(_explore_prompt(true))

func _on_wonder_item_exited(body: Node3D, area: Area3D) -> void:
	if body != player:
		return
	if _near_item == area:
		_near_item = null
	if beat == Beat.EXPLORE:
		_set_prompt(_explore_prompt(false))

func _try_collect_near_item() -> void:
	if beat != Beat.EXPLORE:
		return
	if _near_item == null:
		return
	if _items_collected.has(_near_item.name):
		return
	_items_collected[_near_item.name] = true
	wonder_items_found += 1
	wonder_item_collected.emit(String(_near_item.name))
	if audio_director and audio_director.has_method("play_pickup"):
		audio_director.play_pickup()
	var flavor: String = ITEM_FLAVOR.get(_near_item.name, "A Wonder Item!")
	_say(flavor)
	# Hide placeholder marker + matching mesh inside wonder_items.glb
	var mesh := _near_item.get_node_or_null("Marker")
	if mesh:
		mesh.visible = false
	var visuals := get_node_or_null("../WonderItems/WonderItemsVisual")
	if visuals:
		var visual_mesh := visuals.find_child(_near_item.name, true, false)
		if visual_mesh:
			visual_mesh.visible = false
		var outline := visuals.find_child(_near_item.name + "_Outline", true, false)
		if outline:
			outline.visible = false
	_near_item = null
	_set_prompt(_explore_prompt(false))
	_celebrate_light()
	if wonder_items_found >= WONDER_ITEMS_NEEDED:
		# Hold the wide shot for a moment and let Wonder Light lead the eye to
		# David. This makes the scavenger hunt visibly pay off before the cut.
		_set_player_move(false)
		_set_prompt("Everything is ready — let's bring it to David!")
		_point_light(david_mentor)
		await get_tree().create_timer(1.35).timeout
		_enter_beat(Beat.MEET_DAVID_A)


## The hunt is not an arbitrary counter: every prompt names what the child is
## finding for David, and collected things remain visibly checked off.
func _explore_prompt(near_item: bool) -> String:
	var parts: PackedStringArray = []
	for item_name in ["WonderItem_Stone", "WonderItem_Staff", "WonderItem_Lamb"]:
		var mark := "✓" if _items_collected.has(item_name) else "—"
		parts.append("%s %s" % [ITEM_LABELS[item_name].capitalize(), mark])
	var action := "Press E to collect" if near_item else "Find these for David"
	return "%s   %s   (%d / %d)" % [action, "  ".join(parts), wonder_items_found, WONDER_ITEMS_NEEDED]

func _show(dialogue: String, prompt: String) -> void:
	_say(dialogue)
	if camera_director and camera_director.has_method("is_orbiting") and camera_director.is_orbiting():
		prompt += "   [A / D: look around]"
	_set_prompt(prompt)
	call_deferred("_fit_dialogue_panel")


## Short lines no longer sit at the top of a mostly empty 200 px panel. Long
## story beats (especially Joshua 1:9) still grow enough to wrap comfortably.
func _fit_dialogue_panel() -> void:
	if dialogue_panel == null:
		return
	var dialogue_height := dialogue_label.get_combined_minimum_size().y
	var prompt_height := prompt_label.get_combined_minimum_size().y
	var wanted := dialogue_height + prompt_height + 44.0
	var viewport_height := get_viewport().get_visible_rect().size.y
	var max_height := maxf(116.0, minf(240.0, viewport_height * 0.38))
	var height := clampf(wanted, 116.0, max_height)
	dialogue_panel.offset_top = dialogue_panel.offset_bottom - height

## Shows a line of story text and reads it aloud (if the player has read-aloud on). With "Easy words" on for the
## child playing, lines that have an easier version (easy_words.gd) are swapped for it. Returns what was shown.
func _say(text: String) -> String:
	if GameSettings.easy_words:
		text = EasyWords.apply(text)
	dialogue_label.text = text
	if audio_director and audio_director.has_method("speak_dialogue"):
		audio_director.speak_dialogue(text)
	return text

## A short friendly line from Wonder Light while the player is free to roam
## (used when they wander toward the edge of the valley). It replaces the
## current dialogue for a few seconds, then puts it back, and is rate-limited.
func show_nudge(text: String) -> void:
	if beat != Beat.EXPLORE and beat != Beat.DONE:
		return
	var now := Time.get_ticks_msec()
	if now - _last_nudge_ms < 12000:
		return
	_last_nudge_ms = now
	var prev_dialogue := dialogue_label.text
	var prev_prompt := _prompt_raw
	var prev_beat := beat
	var shown := _say(text)
	await get_tree().create_timer(3.5).timeout
	if beat == prev_beat and dialogue_label.text == shown:
		dialogue_label.text = prev_dialogue
		_set_prompt(prev_prompt)
		call_deferred("_fit_dialogue_panel")

## Prompts are authored with keyboard wording ("Press Space", "press E") and
## rewritten for whichever device the player last used.
func _set_prompt(raw: String) -> void:
	_prompt_raw = raw
	prompt_label.text = _localize_prompt(raw)
	call_deferred("_fit_dialogue_panel")

func _on_device_changed(_mode: String) -> void:
	prompt_label.text = _localize_prompt(_prompt_raw)
	call_deferred("_fit_dialogue_panel")

func _localize_prompt(raw: String) -> String:
	var input_setup := get_node_or_null("../InputSetup")
	var mode: String = input_setup.mode if input_setup else "keyboard"
	match mode:
		"touch":
			return raw.replace("Hold Space", "Hold BREATHE") \
				.replace("Press Space", "Tap NEXT").replace("Press E", "Tap GRAB") \
				.replace("press E", "tap GRAB").replace("[A / D: look around]", "[stick: look around]")
		"gamepad":
			return raw.replace("Hold Space", "Hold A") \
				.replace("Press Space", "Press A").replace("Press E", "Press A") \
				.replace("press E", "press A").replace("[A / D: look around]", "[stick: look around]")
	return raw

## What the on-screen action button should say right now ("" = nothing to do).
func get_action_hint() -> String:
	if beat == Beat.EXPLORE:
		return "GRAB" if _near_item != null else ""
	if steady_hands and "active" in steady_hands and steady_hands.active:
		return "BREATHE"
	if _advance_ready:
		return "NEXT"
	return ""

func _set_player_move(enabled: bool) -> void:
	if player and "can_move" in player:
		player.can_move = enabled

## The King's Camp has taken over, maybe halfway through a replay of this
## chapter: stop listening for Space, put away the hunt arrows and Steady Hands,
## so none of the valley's lines can land on top of the camp.
func stand_down() -> void:
	if beat == Beat.CAMP:
		return
	_close_word_turn()
	beat = Beat.CAMP
	_advance_ready = false
	_near_item = null
	if steady_hands and steady_hands.has_method("cancel"):
		steady_hands.cancel()
	_set_player_move(true)
	_cut_tabletop()
	_point_light(null)
	stood_down.emit()

## -- CameraDirector / WonderLight helpers -----------------------------
## Guarded with has_method() rather than a static type so this still works
## if either companion node is left out of a future scene variant.

func _cut_tabletop() -> void:
	if camera_director and camera_director.has_method("cut_to_tabletop"):
		camera_director.cut_to_tabletop()

func _cut_closeup(look_target: Node3D) -> void:
	if camera_director and camera_director.has_method("cut_to_closeup"):
		camera_director.cut_to_closeup(look_target)

func _point_light(target: Node3D) -> void:
	if wonder_light and wonder_light.has_method("point_at"):
		wonder_light.point_at(target)

## Turns `mover` to face `target_pos` on the spot, closest-direction first.
## Yaw only — no head/body tilt, so it stays upright.
func _turn_to_face(mover: Node3D, target_pos: Vector3, duration: float = 0.6) -> void:
	if not mover:
		return
	var to_target := target_pos - mover.global_position
	to_target.y = 0.0
	if to_target.length() < 0.01:
		return
	var start_rot := mover.rotation
	mover.look_at(mover.global_position + to_target, Vector3.UP)
	var target_yaw := mover.rotation.y
	mover.rotation = start_rot
	var delta := wrapf(target_yaw - start_rot.y, -PI, PI)
	if absf(delta) < 0.01:
		return
	var tw := create_tween()
	tw.tween_property(mover, "rotation:y", start_rot.y + delta, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished

## Turns David to face the player, so he greets the Wonder-Walker face to
## face instead of the close-up camera composing around whatever direction
## he was originally authored facing. Awaiting this before cutting to the
## close-up matters: `_place_closeup()` reads the target's *current* facing
## to compose the shot, so cutting mid-turn (or before it starts) frames
## the wrong spot. The turn plays out on the wide tabletop shot first, then
## the close-up cuts in already correctly framed.
func _face_player(target: Node3D) -> void:
	if not player:
		return
	await _turn_to_face(target, player.global_position)

## Turns the Wonder-Walker to face David — the other half of "face to
## face". Rotates `Player/Model` specifically, not the `Player`
## CharacterBody3D root: that's the same node wonder_walker.gd yaws while
## moving, and it only does so while `can_move` is true (see its early
## return in `_physics_process`), so this never fights player input as
## long as movement is disabled first — true throughout Meet David (see
## `_set_player_move(false)` in Beat.MEET_DAVID_A).
func _face_david(target: Node3D) -> void:
	if not player:
		return
	var model := player.get_node_or_null("Model") as Node3D
	if not model or not target:
		return
	await _turn_to_face(model, target.global_position)

## The chapter-complete moment: applause, a big confetti pop over the
## Wonder-Walker, the light celebrating, and a banner that pops in.
func _play_finale() -> void:
	if audio_director and audio_director.has_method("play_cheer"):
		audio_director.play_cheer()
	if confetti and confetti.has_method("burst") and player:
		confetti.burst(player.global_position + Vector3(0.0, 2.8, 0.0), 220, 1.4, 6.5, 0.95)
	_celebrate_light()
	if complete_banner:
		complete_banner.visible = true
		complete_banner.modulate.a = 0.0
		complete_banner.pivot_offset = complete_banner.size * 0.5
		complete_banner.scale = Vector2(0.4, 0.4)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(complete_banner, "modulate:a", 1.0, 0.25)
		tw.tween_property(complete_banner, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _celebrate_light() -> void:
	if wonder_light and wonder_light.has_method("celebrate"):
		wonder_light.celebrate()


func _on_charm_ceremony_finished() -> void:
	_show(
		"Wonder Light: \"Keep this close. Courage is yours to carry.\"\n(Courage charm sealed on the Virtue Bracelet.)",
		"Press Space to keep your charm"
	)
	_advance_ready = true


func _build_word_buttons() -> void:
	var ui := get_node_or_null("../UI")
	if ui == null:
		return
	_word_row = HBoxContainer.new()
	_word_row.name = "WordTurn"
	_word_row.visible = false
	_word_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_word_row.add_theme_constant_override("separation", 16)
	_word_row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_word_row.anchor_left = 0.06
	_word_row.anchor_right = 0.72
	_word_row.anchor_top = 0.56
	_word_row.anchor_bottom = 0.56
	_word_row.offset_top = -48.0
	_word_row.offset_bottom = 48.0
	_word_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_word_row)
	for i in WORD_LABELS.size():
		var b := PaperUI.button(WORD_LABELS[i], Vector2(200, 96), 36)
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(press_word.bind(i))
		var halo := StyleBoxFlat.new()
		halo.bg_color = Color(1.0, 0.86, 0.35, 0.0)
		halo.set_corner_radius_all(32)
		var glow := Panel.new()
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.show_behind_parent = true
		glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow.offset_left = -22.0
		glow.offset_top = -22.0
		glow.offset_right = 22.0
		glow.offset_bottom = 22.0
		glow.add_theme_stylebox_override("panel", halo)
		b.add_child(glow)
		_word_row.add_child(b)
		_word_buttons.append(b)
		_word_halos.append(halo)
		_word_pulse.append(null)


func _begin_word_listen() -> void:
	_word_phase = "listen"
	_word_said = [false, false, false]
	_restyle_words()
	if _word_row:
		_word_row.visible = false
	if audio_director and audio_director.has_method("is_speaking") and audio_director.is_speaking():
		return
	_open_word_turn()


func _on_speech_finished() -> void:
	if beat == Beat.VERSE_REWARD and _word_phase == "listen":
		_open_word_turn()


func _open_word_turn() -> void:
	if beat != Beat.VERSE_REWARD or _word_phase == "done":
		return
	_word_phase = "tap"
	if _word_row:
		_word_row.visible = true
	_advance_ready = false
	_set_prompt("Tap each word")
	_restyle_words()


func _close_word_turn() -> void:
	_word_phase = ""
	if _word_row:
		_word_row.visible = false


func _words_complete() -> bool:
	for said in _word_said:
		if not said:
			return false
	return true


## Tap one of the three words. Plays that word, and can be tapped again to hear
## it once more. Any order counts. The breath stays locked until each one has
## been tapped at least once.
func press_word(index: int) -> void:
	if beat != Beat.VERSE_REWARD:
		return
	if index < 0 or index >= WORD_LINES.size():
		return
	if _word_phase == "listen" or _word_phase == "":
		_open_word_turn()
	if audio_director and audio_director.has_method("play_line"):
		audio_director.play_line(WORD_LINES[index])
	_word_said[index] = true
	_restyle_words()
	_pulse_word(index)
	if _words_complete() and _word_phase != "done":
		_word_phase = "done"
		_advance_ready = true
		_set_prompt("Press Space to breathe with David")
		if audio_director and audio_director.has_method("play_success"):
			audio_director.play_success()


func _restyle_words() -> void:
	for i in _word_buttons.size():
		var said := i < _word_said.size() and _word_said[i]
		_paint_word(i, said)


## A tapped word stays bright, with a warm halo, so she can see which ones she has said.
func _paint_word(index: int, lit: bool) -> void:
	var b := _word_buttons[index]
	var fill := Color(1.0, 0.97, 0.72) if lit else PaperUI.GOLD
	var halo_alpha := 0.55 if lit else 0.0
	if index < _word_halos.size():
		_word_halos[index].bg_color = Color(1.0, 0.84, 0.28, halo_alpha)
	for state in ["normal", "hover", "focus", "pressed"]:
		var sb := b.get_theme_stylebox(state) as StyleBoxFlat
		if sb == null:
			continue
		sb.bg_color = fill
		sb.shadow_color = Color(1.0, 0.78, 0.2, 0.9 if lit else 0.0)
		sb.shadow_size = 22 if lit else 0


func _pulse_word(index: int) -> void:
	if index < 0 or index >= _word_buttons.size():
		return
	var b := _word_buttons[index]
	if index < _word_pulse.size() and _word_pulse[index] and _word_pulse[index].is_valid():
		_word_pulse[index].kill()
	b.pivot_offset = b.size * 0.5 if b.size.x > 1.0 else Vector2(100, 48)
	b.scale = Vector2(0.94, 0.94)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(b, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if index < _word_halos.size():
		var halo := _word_halos[index]
		halo.bg_color.a = 0.2
		tw.tween_property(halo, "bg_color:a", 0.9, 0.1)
	tw.chain().set_parallel(true)
	tw.tween_property(b, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if index < _word_halos.size():
		tw.tween_property(_word_halos[index], "bg_color:a", 0.55, 0.35)
	if index < _word_pulse.size():
		_word_pulse[index] = tw
	if wonder_light and wonder_light.has_method("celebrate"):
		wonder_light.celebrate()

