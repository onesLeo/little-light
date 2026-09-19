extends Node
## Beat walker for David & Goliath P0.2 vertical slice.
## Arrive → Explore (3 Wonder Items) → Meet David (Band A) → Steady Hands
## → Off-screen resolution → Reflect → Joshua 1:9 + "Don't. Be. Afraid." → Courage charm award.
## No violence shown. Wonder-Walker is a guest, not David.

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
	VERSE_REWARD,
	CHARM_AWARD,  # Courage charm → Virtue Bracelet ceremony
	DONE,
}

@onready var dialogue_label: Label = %DialogueLabel
@onready var prompt_label: Label = %PromptLabel
@onready var player: CharacterBody3D = %Player
@onready var steady_hands: Node = %SteadyHands
@onready var camera_director: Node = %CameraDirector
@onready var wonder_light: Node3D = %WonderLight
@onready var audio_director: Node = get_node_or_null("%AudioDirector")
@onready var confetti: Node = get_node_or_null("%ConfettiBurst")
@onready var complete_banner: Label = get_node_or_null("%CompleteBanner") as Label
@onready var david_mentor: Node3D = get_node_or_null("../DavidMentor") as Node3D
@onready var charm_award: Node3D = get_node_or_null("%CharmAward") as Node3D

var beat: Beat = Beat.ARRIVE
var wonder_items_found: int = 0
const WONDER_ITEMS_NEEDED: int = 3

const ITEM_FLAVOR := {
	"WonderItem_Stone": "A stone, just right for a sling.",
	"WonderItem_Staff": "Worn smooth from long days watching sheep.",
	"WonderItem_Lamb": "Baa! This little one wandered off again.",
}

var _advance_ready: bool = false
var _near_item: Area3D = null
var _items_collected: Dictionary = {}

func _ready() -> void:
	dialogue_label.text = ""
	prompt_label.text = ""
	if steady_hands and steady_hands.has_signal("minigame_completed"):
		steady_hands.minigame_completed.connect(_on_minigame_completed)
	var items_root := get_node_or_null("../WonderItems")
	if items_root:
		for child in items_root.get_children():
			if child is Area3D:
				child.body_entered.connect(_on_wonder_item_entered.bind(child))
				child.body_exited.connect(_on_wonder_item_exited.bind(child))
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
	# Prefer _input over _unhandled_input so dialogue UI cannot swallow Space.
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
			_show(
				"Wonder Light: \"Ooh, look at that! A little valley, all made of paper and light.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.EXPLORE:
			_set_player_move(true)
			_cut_tabletop()
			_point_light(null)
			_show(
				"Wonder Light: \"Three Wonder Items are hidden on the hillside. Find them!\"",
				"Walk near an item and press E  (%d / %d)" % [wonder_items_found, WONDER_ITEMS_NEEDED]
			)
			_advance_ready = false

		Beat.MEET_DAVID_A:
			_set_player_move(false)
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show(
				"David: \"Oh! Hello there. Are you lost too?\"\nDavid: \"Everyone's scared of the big giant. But someone has to be brave.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.MEET_DAVID_B:
			# Band A: Wonder Light speaks for the child — no reply choices.
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show(
				"Wonder Light: \"David is scared too. But he's still going to try.\"\nDavid: \"Thanks. Will you stay close while I get ready?\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.STEADY_INTRO:
			_set_player_move(false)
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show(
				"Wonder Light: \"Let's help David get calm and steady. Breathe in... and out.\"\nDavid: \"In... and out. Just like counting sheep.\"",
				"Press Space to begin Steady Hands"
			)
			_advance_ready = true

		Beat.STEADY_PLAY:
			_cut_closeup(david_mentor)
			_show(
				"Wonder Light: \"Breathe with David...\"",
				"Press Space once  (Steady Hands — always succeeds)"
			)
			_advance_ready = false
			if steady_hands and steady_hands.has_method("start_minigame"):
				steady_hands.start_minigame()

		Beat.STEADY_DONE:
			_cut_closeup(david_mentor)
			_celebrate_light()
			_show(
				"David: \"I feel steady now. Thank you for staying with me.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.RESOLUTION:
			# Off-screen resolution — no fight shown. Script doc calls for the
			# camera staying on David's determined face here.
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show(
				"Wonder Light: \"David walked out to the valley. And when it was over, the whole camp was cheering his name.\"\n(The giant stays a distant silhouette on the far ridge — no fight is shown.)",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.REFLECT:
			_cut_tabletop()
			_point_light(null)
			_show(
				"Wonder Light: \"Being brave doesn't mean you're not scared. It means you go anyway.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.VERSE_REWARD:
			_cut_tabletop()
			_celebrate_light()
			_show(
				"Joshua 1:9 (WEB):\n\"Haven't I commanded you? Be strong and of good courage; don't be afraid, neither be dismayed: for Yahweh your God is with you wherever you go.\"\n\nWonder Light: \"This verse has three special words. Can you say them with me?\nDon't. Be. Afraid.\"",
				"Press Space for your Courage charm"
			)
			_advance_ready = true

		Beat.CHARM_AWARD:
			_set_player_move(false)
			_advance_ready = false
			_celebrate_light()
			_show(
				"Wonder Light: \"A Courage charm — for staying with David when he was scared.\"\n(Virtue Bracelet receives the charm.)",
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
					"Wonder Light: \"A Courage charm — for staying with David when he was scared.\"",
					"Press Space to keep your charm"
				)
				_advance_ready = true

		Beat.DONE:
			_set_player_move(true)
			_cut_tabletop()
			_point_light(null)
			_show(
				"Chapter complete — courage over fear.\n(Wonder-Walker was a guest. David remains David.)",
				"Thanks for playing this P0.2 slice"
			)
			_advance_ready = false
			_play_finale()

func _on_advance() -> void:
	match beat:
		Beat.ARRIVE:
			_enter_beat(Beat.EXPLORE)
		Beat.MEET_DAVID_A:
			_enter_beat(Beat.MEET_DAVID_B)
		Beat.MEET_DAVID_B:
			_enter_beat(Beat.STEADY_INTRO)
		Beat.STEADY_INTRO:
			_enter_beat(Beat.STEADY_PLAY)
		Beat.STEADY_DONE:
			_enter_beat(Beat.RESOLUTION)
		Beat.RESOLUTION:
			_enter_beat(Beat.REFLECT)
		Beat.REFLECT:
			_enter_beat(Beat.VERSE_REWARD)
		Beat.VERSE_REWARD:
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
		prompt_label.text = "Press E to collect  (%d / %d)" % [wonder_items_found, WONDER_ITEMS_NEEDED]

func _on_wonder_item_exited(body: Node3D, area: Area3D) -> void:
	if body != player:
		return
	if _near_item == area:
		_near_item = null
	if beat == Beat.EXPLORE:
		prompt_label.text = "Walk near an item and press E  (%d / %d)" % [wonder_items_found, WONDER_ITEMS_NEEDED]

func _try_collect_near_item() -> void:
	if beat != Beat.EXPLORE:
		return
	if _near_item == null:
		return
	if _items_collected.has(_near_item.name):
		return
	_items_collected[_near_item.name] = true
	wonder_items_found += 1
	if audio_director and audio_director.has_method("play_pickup"):
		audio_director.play_pickup()
	var flavor: String = ITEM_FLAVOR.get(_near_item.name, "A Wonder Item!")
	dialogue_label.text = flavor
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
	prompt_label.text = "Collected!  (%d / %d)" % [wonder_items_found, WONDER_ITEMS_NEEDED]
	_celebrate_light()
	if wonder_items_found >= WONDER_ITEMS_NEEDED:
		# Brief pause then meet David.
		await get_tree().create_timer(0.8).timeout
		_enter_beat(Beat.MEET_DAVID_A)

func _show(dialogue: String, prompt: String) -> void:
	dialogue_label.text = dialogue
	if camera_director and camera_director.has_method("is_orbiting") and camera_director.is_orbiting():
		prompt += "   [A / D: look around]"
	prompt_label.text = prompt

func _set_player_move(enabled: bool) -> void:
	if player and "can_move" in player:
		player.can_move = enabled

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

## The chapter-complete moment: applause, a big confetti pop over the
## Wonder-Walker, the light celebrating, and a banner that pops in.
func _play_finale() -> void:
	if audio_director and audio_director.has_method("play_cheer"):
		audio_director.play_cheer()
	if confetti and confetti.has_method("burst") and player:
		confetti.burst(player.global_position + Vector3(0.0, 2.8, 0.0), 160, 1.6, 6.5, 1.5)
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
