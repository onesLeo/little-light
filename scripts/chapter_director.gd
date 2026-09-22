extends Node
## Beat walker for David & Goliath P0.2 vertical slice.
## Arrive → Explore (3 Wonder Items) → Meet David (Band A) → Joshua 1:9
## → Steady Hands (breathe the promise) → Off-screen resolution → Reflect
## → Courage charm award.
## Spine: hear the word → practise it → watch David walk on it → keep it.
## Courage comes from God being with David, not from feeling calm.
## No violence shown. Wonder-Walker is a guest, not David.
## The story waits at the start until the "Who is playing?" screen has a child (profile_screen.gd);
## the verse, the charm and the finished chapter go into that child's Faith Journal.

const Profiles := preload("res://scripts/profiles.gd")
const JournalContent := preload("res://scripts/journal_content.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const EasyWords := preload("res://scripts/easy_words.gd")

enum Beat {
	ARRIVE,
	MEET_DAVID_A,
	MEET_DAVID_B,
	EXPLORE,
	STEADY_INTRO,
	STEADY_PLAY,
	STEADY_DONE,
	RESOLUTION,
	REFLECT,
	VERSE_REWARD,
	CHARM_AWARD,
	DONE,
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

var beat: Beat = Beat.ARRIVE
var wonder_items_found: int = 0
const WONDER_ITEMS_NEEDED: int = 3

const ITEM_FLAVOR := {
	"WonderItem_Stone": "A stone, just right for a sling.",
	"WonderItem_Staff": "Worn smooth from long days watching sheep.",
	"WonderItem_Lamb": "Baa! This little one wandered off again.",
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
	_start_story()

func _start_story() -> void:
	var picker := get_node_or_null("../ProfileScreen")
	if Profiles.active_id.is_empty() and picker != null:
		picker.profile_chosen.connect(func(_id: String) -> void: _enter_beat(Beat.ARRIVE), CONNECT_ONE_SHOT)
	else:
		_enter_beat(Beat.ARRIVE)

func _is_continue_pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		var pk: int = event.physical_keycode
		return k == KEY_SPACE or pk == KEY_SPACE or k == KEY_ENTER or pk == KEY_ENTER
	return false

func _input(event: InputEvent) -> void:
	if _advance_ready and _is_continue_pressed(event):
		_advance_ready = false
		_on_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		_try_collect_near_item()
		get_viewport().set_input_as_handled()

func _enter_beat(next: Beat) -> void:
	beat = next
	if audio_director and audio_director.has_method("play_vo"):
		audio_director.play_vo(Beat.keys()[next])
	match beat:
		Beat.ARRIVE:
			_set_player_move(false)
			_cut_tabletop()
			_point_light(null)
			_show("Wonder Light: \"Ooh, look at that! A little valley, all made of paper and light.\"", "Press Space to continue")
			_advance_ready = true
		Beat.EXPLORE:
			_set_player_move(true)
			_cut_tabletop()
			_point_light(null)
			_show("Wonder Light: \"Three Wonder Items are hidden on the hillside. Find them!\"", _explore_prompt(false))
			_advance_ready = false
			explore_started.emit()
		Beat.MEET_DAVID_A:
			_set_player_move(false)
			_face_david(david_mentor)
			await _face_player(david_mentor)
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show("(You bring David the stone, staff, and little lamb.)\nDavid: \"Oh! Hello there. Are you lost too?\"\nDavid: \"Everyone's scared of the big giant. But someone has to be brave.\"", "Press Space to continue")
			_advance_ready = true
		Beat.MEET_DAVID_B:
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show("Wonder Light: \"David is scared too. But he's still going to try.\"\nDavid: \"Thanks. Will you stay close while I get ready?\"", "Press Space to continue")
			_advance_ready = true
		Beat.VERSE_REWARD:
			Profiles.unlock_verse(JournalContent.VERSE_JOSHUA_1_9)
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_celebrate_light()
			_show("Joshua 1:9 (WEB):\n\"Haven't I commanded you? Be strong and of good courage; don't be afraid, neither be dismayed: for Yahweh your God is with you wherever you go.\"\n\nWonder Light: \"This verse has three special words. Can you say them with me?\nDon't. Be. Afraid.\"", "Press Space to breathe with David")
			_advance_ready = true
		Beat.STEADY_INTRO:
			_set_player_move(false)
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show("Wonder Light: \"Let's breathe God's promise with David. In: God is with you. Out: don't be afraid.\"\nDavid: \"In... and out. Just like counting sheep.\"", "Press Space to begin Steady Hands")
			_advance_ready = true
		Beat.STEADY_PLAY:
			_cut_closeup(david_mentor)
			_show("Wonder Light: \"Breathe with David...\"", "Hold Space to breathe in, let go to breathe out")
			_advance_ready = false
			if steady_hands and steady_hands.has_method("start_minigame"):
				steady_hands.start_minigame()
		Beat.STEADY_DONE:
			_cut_closeup(david_mentor)
			_celebrate_light()
			_show("David: \"I still feel small. But I don't feel alone. Thank you for staying — and for the words.\"", "Press Space to continue")
			_advance_ready = true
		Beat.RESOLUTION:
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show("Wonder Light: \"A stone, just right for a sling.\"\nWonder Light: \"David walked out to the valley. And when it was over, the whole camp was cheering his name.\"\nWonder Light: \"David trusted God, faced Goliath with his sling, and defeated him. The people were safe.\"", "Press Space to continue")
			_advance_ready = true
		Beat.REFLECT:
			_cut_tabletop()
			_point_light(null)
			_show("Wonder Light: \"Being brave doesn't mean you're not scared. It means you go with God anyway.\"", "Press Space to continue")
			_advance_ready = true
		Beat.CHARM_AWARD:
			Profiles.unlock_charm(JournalContent.CHARM_COURAGE)
			_set_player_move(false)
			_advance_ready = false
			_celebrate_light()
			_show("Wonder Light: \"A Courage charm — for staying with David, and breathing God's promise with him.\"\n(Virtue Bracelet receives the charm.)", "…")
			if charm_award and camera_director and camera_director.has_method("cut_to_charm"):
				camera_director.cut_to_charm(charm_award)
			elif charm_award:
				_cut_closeup(charm_award)
			if charm_award and charm_award.has_method("play_ceremony"):
				if not charm_award.ceremony_finished.is_connected(_on_charm_ceremony_finished):
					charm_award.ceremony_finished.connect(_on_charm_ceremony_finished, CONNECT_ONE_SHOT)
				charm_award.play_ceremony()
			else:
				_show("Wonder Light: \"A Courage charm — for staying with David, and breathing God's promise with him.\"", "Press Space to keep your charm")
				_advance_ready = true
		Beat.DONE:
			Profiles.finish_chapter()
			_set_player_move(true)
			_cut_tabletop()
			_point_light(null)
			_show("Chapter complete — courage over fear.", "Well done, Wonder-Walker!")
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
		_set_player_move(false)
		_set_prompt("Everything is ready — let's bring it to David!")
		_point_light(david_mentor)
		await get_tree().create_timer(1.35).timeout
		_enter_beat(Beat.MEET_DAVID_A)

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

func _say(text: String) -> String:
	if GameSettings.easy_words:
		text = EasyWords.apply(text)
	dialogue_label.text = text
	if audio_director and audio_director.has_method("speak_dialogue"):
		audio_director.speak_dialogue(text)
	return text

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
	if mode == "touch":
		return raw.replace("Hold Space", "Hold BREATHE").replace("Press Space", "Tap NEXT").replace("Press E", "Tap GRAB").replace("press E", "tap GRAB").replace("[A / D: look around]", "[stick: look around]")
	if mode == "gamepad":
		return raw.replace("Hold Space", "Hold A").replace("Press Space", "Press A").replace("Press E", "Press A").replace("press E", "press A").replace("[A / D: look around]", "[stick: look around]")
	return raw

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

func _cut_tabletop() -> void:
	if camera_director and camera_director.has_method("cut_to_tabletop"):
		camera_director.cut_to_tabletop()

func _cut_closeup(look_target: Node3D) -> void:
	if camera_director and camera_director.has_method("cut_to_closeup"):
		camera_director.cut_to_closeup(look_target)

func _point_light(target: Node3D) -> void:
	if wonder_light and wonder_light.has_method("point_at"):
		wonder_light.point_at(target)

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

func _face_player(target: Node3D) -> void:
	if not player:
		return
	await _turn_to_face(target, player.global_position)

func _face_david(target: Node3D) -> void:
	if not player:
		return
	var model := player.get_node_or_null("Model") as Node3D
	if not model or not target:
		return
	await _turn_to_face(model, target.global_position)

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
	_show("Wonder Light: \"Keep this close. Courage is yours to carry.\"\n(Courage charm sealed on the Virtue Bracelet.)", "Press Space to keep your charm")
	_advance_ready = true
