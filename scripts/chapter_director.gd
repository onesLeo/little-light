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
				"(You bring David the stone, staff, and little lamb.)\nDavid: \"Oh! Hello there. Are you lost too?\"\nDavid: \"Everyone's scared of the big giant. But someone has to be brave.\"",
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

		Beat.VERSE_REWARD:
			# The word is given before the breath and the walk, so courage has a
			# source: God is with David. The child says the three words *with* him.
			Profiles.unlock_verse(JournalContent.VERSE_JOSHUA_1_9)
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_celebrate_light()
			_show(
				"Joshua 1:9 (WEB):\n\"Haven't I commanded you? Be strong and of good courage; don't be afraid, neither be dismayed: for Yahweh your God is with you wherever you go.\"\n\nWonder Light: \"This verse has three special words. Can you say them with me?\nDon't. Be. Afraid.\"",
				"Press Space to breathe with David"
			)
			_advance_ready = true

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
				"David: \"I still feel small. But I don't feel alone. Thank you for staying — and for the words.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.RESOLUTION:
			# Off-screen resolution — no fight shown. Script doc calls for the
			# camera staying on David's determined face here.
			_cut_closeup(david_mentor)
			_point_light(david_mentor)
			_show(
				"Wonder Light: \"A stone, just right for a sling.\"\nWonder Light: \"David walked out to the valley. And when it was over, the whole camp was cheering his name.\"\nWonder Light: \"David trusted God, faced Goliath with his sling, and defeated him. The people were safe.\"",
				"Press Space to continue"
			)
			_advance_ready = true

		Beat.REFLECT:
			_cut_tabletop()
			_point_light(null)
			_show(
				"Wonder Light: \"Being brave doesn't mean you're not scared. It means you go with God anyway.\"",
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
				"Chapter complete — courage over fear.",
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
