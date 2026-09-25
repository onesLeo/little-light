extends Node3D
## The game shell, on the Main root. It is the one place a story is started, stopped or
## switched, and it holds the services every story shares: the end-of-chapter finale,
## fitting the dialogue bar to its line, the gentle nudges at the edge of the play area,
## and what the touch button says. Stories never call one another, so adding a story means
## adding it here, not to every other story. main.tscn itself holds only what every story
## shares: the Wonder-Walker, the cameras and lights, the UI, the menus and the sound.
##
## Every story is a scene of its own (see STORIES). The shell loads one when it starts and
## frees it when another story starts, so only what is being played is in the tree and every
## start is a fresh one. The King's Camp stands on the valley's ridge, so the valley stays
## loaded under it ("over"), with its story stood down. A story's root node sits under Main
## and offers:
##   visit()             start it, or carry on if it is already under way
##   stand_down()        stop it: its story stops listening, its sounds stop
##   in_progress()       true while its story is under way (then switching to it carries on)
##   look                its chapter_look.gd resource: sky, lights, backdrop, night, camera
##   play_area           its play_area.gd resource: where the walker can go
##   get_action_hint()   on its story node, for the touch button
## A story's pieces reach the shared nodes through GameShell.of(self).
##
## Which story is running is Profiles.current_chapter; it survives a reload, which is how
## "Play again" works. Going back to the valley once another story has started also reloads,
## so nothing another story changed on the shared nodes (the camp's paper look) stays.

const Profiles := preload("res://scripts/profiles.gd")
const DialogueView := preload("res://scripts/dialogue_view.gd")

## The stories: their scene, the name of its root node under Main, the child holding its
## story script, and the story it stands on ("over"), which stays loaded under it.
const STORIES := {
	Profiles.CHAPTER_VALLEY: {"scene": "res://scenes/chapters/bethlehem_valley.tscn", "node": "Valley", "story": "ChapterDirector"},
	Profiles.CHAPTER_CAMP: {"scene": "res://scenes/chapters/kings_camp.tscn", "node": "KingsCamp", "story": "ChapterTwo",
			"over": Profiles.CHAPTER_VALLEY},
	Profiles.CHAPTER_BEGINNING: {"scene": "res://scenes/chapters/jesses_house.tscn", "node": "JessesHouse", "story": "ChapterThree"},
	Profiles.CHAPTER_ARK: {"scene": "res://scenes/chapters/noahs_ark.tscn", "node": "NoahsArk", "story": "ChapterFour"},
}

## True while the map is the first stop and no story has started behind it: the valley
## is then already waiting, so it starts in place instead of reloading.
var _first_map: bool = false


## The shell `node` belongs to: its nearest ancestor that is one (Main). A story's pieces use
## it to reach the shared player, cameras, UI and sound, whatever scene they are in.
static func of(node: Node) -> Node:
	var at := node.get_parent()
	while at != null and not at.has_method("start_story"):
		at = at.get_parent()
	return at


func _ready() -> void:
	_build_dialogue_view()
	start_story()


## The speaker's name tag and face over the dialogue bar, for every story (dialogue_view.gd).
func _build_dialogue_view() -> void:
	var ui := get_node_or_null("UI")
	var panel := get_node_or_null("UI/Panel") as Control
	var line := get_node_or_null("%DialogueLabel") as Label
	if ui == null or panel == null or line == null:
		return
	var view := DialogueView.new()
	view.name = "DialogueView"
	view.setup(panel, line, get_node_or_null("AudioDirector"))
	ui.add_child(view)


## Starts what this scene was loaded for. Nobody playing yet: "Who is playing?" comes first,
## then the Faith Journey map, with the valley waiting behind them. After a reload for
## "Play again", straight back into the story the child was on.
func start_story() -> void:
	var picker := get_node_or_null("ProfileScreen")
	var id := Profiles.current_chapter
	if Profiles.active_id.is_empty() and picker != null:
		_ensure_loaded(Profiles.CHAPTER_VALLEY)
		picker.profile_chosen.connect(func(_id: String) -> void: _open_map_first(), CONNECT_ONE_SHOT)
	elif id == Profiles.CHAPTER_VALLEY:
		_begin_valley()
	elif STORIES.has(id):
		switch_to(id)
	else:
		_ensure_loaded(Profiles.CHAPTER_VALLEY)
		_open_map_first.call_deferred()


## Moves to story `id`. Every other story stands down first, so only one ever listens.
func switch_to(id: String) -> void:
	if id == Profiles.CHAPTER_VALLEY:
		# On the first map the valley is already waiting, with the Wonder-Walker at its start.
		if _first_map:
			_begin_valley()
		else:
			reload(Profiles.CHAPTER_VALLEY)
		return
	if not STORIES.has(id):
		push_warning("GameShell: no story called %s" % id)
		return
	_first_map = false
	# Tapping the story already under way only closes the map: its look (the ark's rain) stays.
	var story := _story_node(id)
	var carry_on: bool = Profiles.current_chapter == id and story != null and story.has_method("in_progress") and story.in_progress()
	var under: String = STORIES[id].get("over", "")
	for other in STORIES:
		if other == id and carry_on:
			continue
		if other == under:
			_stand_down(other)
		else:
			_put_away(other)
	if not under.is_empty() and _story_node(under) == null:
		_load_story(under)
		_stand_down(under)
	Profiles.current_chapter = id
	var menu := get_node_or_null("GameMenu")
	if menu and menu.has_method("hide_end_panel"):
		menu.hide_end_panel()
	if not carry_on:
		story = _load_story(id)
		if story == null:
			return
		apply_look(story.get("look"))
	_use_play_area(story.get("play_area"))
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


## Chapter 1 in the valley as it is: loaded now if it is not waiting already.
func _begin_valley() -> void:
	_first_map = false
	for other in STORIES:
		if other != Profiles.CHAPTER_VALLEY:
			_put_away(other)
	var valley := _ensure_loaded(Profiles.CHAPTER_VALLEY)
	Profiles.current_chapter = Profiles.CHAPTER_VALLEY
	apply_look(valley.get("look"))
	_use_play_area(valley.get("play_area"))
	valley.visit()


## The Faith Journey map as the first stop, before any story. Without it (a trimmed scene),
## the valley starts as before.
func _open_map_first() -> void:
	var journey := get_node_or_null("FaithJourney")
	if journey and journey.has_method("open_to_choose"):
		_first_map = true
		journey.open_to_choose()
	else:
		_begin_valley()


func _use_play_area(area: Resource) -> void:
	var bounds := get_node_or_null("PlayBounds")
	if bounds and bounds.has_method("use_area"):
		bounds.use_area(area)


## True when story `id` can be played.
func has_story(id: String) -> bool:
	return STORIES.has(id) and ResourceLoader.exists(STORIES[id]["scene"])


## The story's root node while it is loaded, otherwise null.
func _story_node(id: String) -> Node:
	if not STORIES.has(id):
		return null
	return get_node_or_null(STORIES[id]["node"])


## The node running story `id` (the director, ChapterTwo, ChapterFour) while it is loaded.
func _story_script(id: String) -> Node:
	if not STORIES.has(id):
		return null
	return get_node_or_null("%s/%s" % [STORIES[id]["node"], STORIES[id]["story"]])


func _ensure_loaded(id: String) -> Node:
	var story := _story_node(id)
	return story if story != null else _load_story(id)


## Loads story `id` fresh from its scene, under Main, before the lights (where the stories
## always sat, so they process in the same order).
func _load_story(id: String) -> Node:
	var packed := load(STORIES[id]["scene"]) as PackedScene
	if packed == null:
		push_warning("GameShell: could not load %s" % STORIES[id]["scene"])
		return null
	var story := packed.instantiate()
	story.name = STORIES[id]["node"]
	add_child(story)
	var before := get_node_or_null("Sun")
	if before:
		move_child(story, before.get_index())
	# Outline hulls drawn into the shadow map twice cost a tablet a lot (performance_tuning.gd).
	var tuning := get_node_or_null("PerformanceTuning")
	if tuning and tuning.has_method("stop_outline_shadows"):
		tuning.stop_outline_shadows.call_deferred(story)
	return story


func _stand_down(id: String) -> void:
	var story := _story_node(id)
	if story and story.has_method("stand_down"):
		story.stand_down()


## Stops story `id` if it is loaded and frees it: it leaves the tree at once, so its name is
## free for the next one, and its tweens, sounds and cards go with it.
func _put_away(id: String) -> void:
	var story := _story_node(id)
	if story == null:
		return
	_stand_down(id)
	remove_child(story)
	story.queue_free()


## -- Shared by every story ------------------------------------------------------

## Dresses the world for a story (chapter_look.gd): its lighting, the backdrop of hills,
## night or day sounds, and the tabletop camera's framing. The story before it is never undone
## by hand: this sets every one of them.
func apply_look(look: Resource) -> void:
	if look == null:
		return
	apply_lighting(look)
	# The valley's ring of hills; a story far from the valley has none.
	var backdrop := get_node_or_null("Valley/HorizonBackdrop") as Node3D
	if backdrop:
		if look.backdrop == "blue_hour" and backdrop.has_method("set_blue_hour"):
			backdrop.set_blue_hour()
		elif backdrop.has_method("set_daylight"):
			backdrop.set_daylight()
		backdrop.visible = look.backdrop != "hidden"
	var soundscape := get_node_or_null("Soundscape")
	if soundscape and soundscape.has_method("set_night"):
		soundscape.set_night(look.night)
	var cam := get_node_or_null("TabletopCamera") as Camera3D
	if cam and "offset" in cam:
		cam.offset = look.camera_offset
		cam.set("look_height", look.camera_look_height)
		cam.fov = look.camera_fov


## Only the look's sky, air and lights: the base a story's own weather tweens from.
func apply_lighting(look: Resource) -> void:
	if look == null:
		return
	var world := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		var env := world.environment
		var sky := env.sky.sky_material as ProceduralSkyMaterial if env.sky else null
		if sky:
			sky.sky_top_color = look.sky_top
			sky.sky_horizon_color = look.sky_horizon
			sky.ground_horizon_color = look.ground_horizon
			sky.ground_bottom_color = look.ground_bottom
		env.ambient_light_color = look.ambient_color
		env.ambient_light_energy = look.ambient_energy
		env.fog_light_color = look.fog_color
		env.fog_density = look.fog_density
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = look.sun_color
		sun.light_energy = look.sun_energy
	var fill := get_node_or_null("FillLight") as DirectionalLight3D
	if fill:
		fill.light_color = look.fill_color
		fill.light_energy = look.fill_energy


## What the touch button says now ("" = nothing to do): the running story answers.
func action_hint() -> String:
	var story := _story_script(Profiles.current_chapter)
	return story.get_action_hint() if story and story.has_method("get_action_hint") else ""


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
	var director := _story_script(Profiles.CHAPTER_VALLEY)
	if director and director.has_method("show_nudge"):
		director.show_nudge(text)
