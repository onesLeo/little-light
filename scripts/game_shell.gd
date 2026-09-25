extends Node3D
## The game shell, on the Main root. It is the one place a story is started, stopped or
## switched, and it holds the services every story shares: the end-of-chapter finale,
## fitting the dialogue bar to its line, the gentle nudges at the edge of the play area,
## and what the touch button says. Stories reach it as their scene root and never call
## one another, so adding a story means adding it here, not to every other story.
##
## A story that lives in this scene as a node (see STORIES) offers:
##   visit()             start it, or carry on if it is already under way
##   stand_down()        stop it: its story stops listening, its cards and sounds go away
##   get_action_hint()   on its story node, for the touch button
## The valley is the scene itself (chapter_director.gd): choosing it once another story
## has started loads the scene again, which also starts every other story clean.
##
## Which story is running is Profiles.current_chapter; it survives a reload, which is how
## "Play again" works.

const Profiles := preload("res://scripts/profiles.gd")

## The stories that live in this scene as nodes: the node, and the node holding its story script.
const STORIES := {
	Profiles.CHAPTER_CAMP: {"node": "KingsCamp", "story": "KingsCamp/ChapterTwo"},
	Profiles.CHAPTER_ARK: {"node": "NoahsArk", "story": "NoahsArk/ChapterFour"},
}

## True while the map is the first stop and no story has started behind it: the valley
## is then already waiting in the scene, so it starts in place instead of reloading.
var _first_map: bool = false


## Starts what this scene was loaded for; the valley's director calls it once it is ready.
## Nobody playing yet: "Who is playing?" comes first, then the Faith Journey map. After a
## reload for "Play again", straight back into the story the child was on.
func start_story() -> void:
	var picker := get_node_or_null("ProfileScreen")
	if Profiles.active_id.is_empty() and picker != null:
		picker.profile_chosen.connect(func(_id: String) -> void: _open_map_first(), CONNECT_ONE_SHOT)
		return
	var id := Profiles.current_chapter
	if id == Profiles.CHAPTER_VALLEY:
		_begin_valley()
	elif STORIES.has(id) and _story_node(id) != null:
		switch_to.call_deferred(id)
	else:
		_open_map_first.call_deferred()


## Moves to story `id`. Every other story stands down first, so only one ever listens.
func switch_to(id: String) -> void:
	if id == Profiles.CHAPTER_VALLEY:
		if _first_map:
			_begin_valley()
		else:
			reload(Profiles.CHAPTER_VALLEY)
		return
	_first_map = false
	var story := _story_node(id)
	if story == null or not story.has_method("visit"):
		push_warning("GameShell: no story called %s in this scene" % id)
		return
	var director := get_node_or_null("ChapterDirector")
	if director and director.has_method("stand_down"):
		director.stand_down()
	for other in STORIES:
		var node := _story_node(other)
		if other != id and node and node.has_method("stand_down"):
			node.stand_down()
	Profiles.current_chapter = id
	var menu := get_node_or_null("GameMenu")
	if menu and menu.has_method("hide_end_panel"):
		menu.hide_end_panel()
	story.visit()


## Loads the scene again and goes straight into story `id` ("" with nobody playing: then
## "Who is playing?" and the map come first). "Play again" and the valley's map stop use it.
func reload(id: String) -> void:
	Profiles.current_chapter = "" if Profiles.active_id.is_empty() else id
	get_tree().paused = false
	var audio := get_node_or_null("AudioDirector")
	if audio and audio.has_method("stop_speech"):
		audio.stop_speech()
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
	get_tree().reload_current_scene()


func _begin_valley() -> void:
	_first_map = false
	var director := get_node_or_null("ChapterDirector")
	if director and director.has_method("begin_valley"):
		director.begin_valley()


## The Faith Journey map as the first stop, before any story. Without it (a trimmed scene),
## the valley starts as before.
func _open_map_first() -> void:
	var journey := get_node_or_null("FaithJourney")
	if journey and journey.has_method("open_to_choose"):
		_first_map = true
		journey.open_to_choose()
	else:
		_begin_valley()


## True when story `id` can be played in this scene (the valley always can).
func has_story(id: String) -> bool:
	return id == Profiles.CHAPTER_VALLEY or _story_node(id) != null


func _story_node(id: String) -> Node:
	if not STORIES.has(id):
		return null
	return get_node_or_null(STORIES[id]["node"])


## -- Shared by every story ------------------------------------------------------

## What the touch button says now ("" = nothing to do): the running story answers.
func action_hint() -> String:
	var id := Profiles.current_chapter
	if STORIES.has(id):
		var story := get_node_or_null(STORIES[id]["story"])
		return story.get_action_hint() if story and story.has_method("get_action_hint") else ""
	var director := get_node_or_null("ChapterDirector")
	return director.get_action_hint() if director and director.has_method("get_action_hint") else ""


## The end-of-chapter celebration every story ends with: a cheer, confetti over the
## Wonder-Walker, Wonder Light's burst, and the banner popping in with `title`.
func play_finale(title: String = "Chapter Complete!") -> void:
	var audio := get_node_or_null("AudioDirector")
	if audio and audio.has_method("play_cheer"):
		audio.play_cheer()
	var confetti := get_node_or_null("%ConfettiBurst")
	var player := get_node_or_null("Player") as Node3D
	if confetti and confetti.has_method("burst") and player:
		confetti.burst(player.global_position + Vector3(0.0, 2.8, 0.0), 220, 1.4, 6.5, 0.95)
	var light := get_node_or_null("WonderLight")
	if light and light.has_method("celebrate"):
		light.celebrate()
	var banner := get_node_or_null("%CompleteBanner") as Label
	if banner:
		banner.text = title
		banner.visible = true
		banner.modulate.a = 0.0
		banner.pivot_offset = banner.size * 0.5
		banner.scale = Vector2(0.4, 0.4)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(banner, "modulate:a", 1.0, 0.25)
		tw.tween_property(banner, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Sizes the dialogue bar to the line in it: short lines do not sit at the top of a mostly
## empty panel, and long ones (Joshua 1:9) still grow enough to wrap comfortably.
func fit_dialogue() -> void:
	var panel := get_node_or_null("UI/Panel") as PanelContainer
	var line := get_node_or_null("%DialogueLabel") as Label
	var prompt := get_node_or_null("%PromptLabel") as Label
	if panel == null or line == null or prompt == null:
		return
	var wanted := line.get_combined_minimum_size().y + prompt.get_combined_minimum_size().y + 44.0
	var max_height := maxf(116.0, minf(240.0, get_viewport().get_visible_rect().size.y * 0.38))
	panel.offset_top = panel.offset_bottom - clampf(wanted, 116.0, max_height)


## A short friendly line when the child wanders to the edge of the play area (play_bounds.gd).
## Only the valley has nudges so far; its director decides when one may show.
func nudge(text: String) -> void:
	var director := get_node_or_null("ChapterDirector")
	if director and director.has_method("show_nudge"):
		director.show_nudge(text)
