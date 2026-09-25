extends SceneTree
## Plays Chapter 3, The Beginning, from its first line to the end card, with checks at every
## beat: the courtyard and its people, the optional finds, Prepare the Welcome (any order, a
## ring only takes its own thing), the brothers' procession and its length, calling David
## home, the verse and its three words, the anointing, and the Faithful Heart charm.
##
##   godot --headless --path . --script tests/beginning_review.gd
##   godot --path . --script tests/beginning_review.gd --resolution 1280x720 -- --capture
##
## With --capture (the real renderer, not --headless), each key moment is saved to
## .godot/beginning-review/.
const Profiles := preload("res://scripts/profiles.gd")
const Settings := preload("res://scripts/game_settings.gd")
const JournalContent := preload("res://scripts/journal_content.gd")

const PROFILE_FILE := "res://.godot/beginning-review-profile.cfg"

var failures: int = 0
var main: Node
var capture: bool = false


func _initialize() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	DirAccess.remove_absolute(PROFILE_FILE)
	Profiles.use_file(PROFILE_FILE)
	Profiles.set_active(Profiles.create("Beginning Review", "star"))
	Profiles.finish_chapter(Profiles.CHAPTER_VALLEY)
	Profiles.finish_chapter(Profiles.CHAPTER_CAMP)
	Profiles.current_chapter = ""
	Settings.read_aloud = false
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.get_node("GameMenu").end_panel_delay = 0.05
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	print("OK " if ok else "FAIL ", label)
	if not ok:
		failures += 1


func settle(frames: int = 5) -> void:
	for _i in frames:
		await process_frame


func shot(label: String) -> void:
	if not capture:
		return
	await settle(3)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/beginning-review"))
	root.get_texture().get_image().save_png("res://.godot/beginning-review/%s.png" % label)


func line_text() -> String:
	return (main.find_child("DialogueLabel", true, false) as Label).text


func prompt_text() -> String:
	return (main.find_child("PromptLabel", true, false) as Label).text


## Whether a solid body (a wall the walker cannot pass) is at `point`.
func solid_at(space: PhysicsDirectSpaceState3D, point: Vector3) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	for hit in space.intersect_point(query):
		if hit["collider"] is StaticBody3D:
			return true
	return false


## Puts the walker at `at` and lets the story notice it.
func walk_to(player: Node3D, at: Vector3) -> void:
	player.global_position = Vector3(at.x, 0.3, at.z)
	await settle(3)


func _run() -> void:
	await settle()
	var journey: Node = main.get_node("FaithJourney")
	check(Profiles.is_unlocked(Profiles.active_id, Profiles.CHAPTER_BEGINNING) and not Profiles.is_unlocked(Profiles.active_id, Profiles.CHAPTER_ARK),
			"after the camp, The Beginning is open and the ark waits for it")
	journey._on_stop("beginning")
	await settle(8)
	var house: Node = main.get_node_or_null("JessesHouse")
	var story: Node = main.get_node_or_null("JessesHouse/ChapterThree")
	var player: Node3D = main.get_node("Player")
	check(house != null and story != null and story.phase == story.Phase.ARRIVE and "turning back the page" in line_text(),
			"the map's third stop opens Jesse's courtyard at its first line")
	check(house.samuel().find_child("SamuelBody", true, false) != null and house.jesse().find_child("JesseBody", true, false) != null
			and house.david().find_child("YoungDavidBody", true, false) != null,
			"Samuel, Jesse and the younger David are the Blender models")
	check(house.sons().brothers().size() == 7, "all seven of Jesse's older sons stand in the courtyard")
	check(not house.david().visible, "David is away with the sheep")
	check(not player.can_move and story.get_action_hint() == "NEXT", "the first line holds the child still, and the button says NEXT")
	var space := (house as Node3D).get_world_3d().direct_space_state
	check(solid_at(space, Vector3(-8.8, 1.0, -3.8)), "the house's side wall is solid: the walker cannot pass through it")
	var clear_of_walls := true
	for brother in house.sons().brothers():
		clear_of_walls = clear_of_walls and not solid_at(space, brother.global_position + Vector3(0.0, 1.0, 0.0))
	check(clear_of_walls, "every brother stands clear of the walls")
	var life: Node3D = house.life()
	var cloud_x: float = life.cloud_shadows()[0].position.x
	await create_timer(0.5).timeout
	check(life.cloud_shadows().size() == 3 and life.cloud_shadows()[0].position.x > cloud_x, "cloud shadows drift across the courtyard")
	await shot("01_arrive")

	print("-- Prepare the Welcome --")
	story._advance()
	await settle()
	check(story.phase == story.Phase.WELCOME and player.can_move and story._checklist.visible
			and "0 / 3" in story._checklist._title.text, "the welcome starts: the child can walk, and the list shows 0 / 3")
	var dove: Node3D = life.ground_doves()[0]
	var dove_home := dove.global_position
	await walk_to(player, dove_home + Vector3(0.6, 0.0, 0.6))
	await create_timer(1.8).timeout
	check(dove.global_position.distance_to(dove_home) > 1.5 and dove.global_position.y < 0.05,
			"a dove flutters off when the child walks up, and lands a little way away")
	await walk_to(player, house.FINDS["Harp"])
	check(house.found_things() == ["Harp"] and "small harp" in line_text(), "finding David's harp, Wonder Light says what it is for")
	check(prompt_text().begins_with("Carry the cushion"), "and the welcome prompt stays")
	await walk_to(player, house.WELCOME["Cup"]["at"])
	check(house.carrying() == "Cup", "walking to the cup picks it up")
	await walk_to(player, house.WELCOME["Cushion"]["at"])
	check(house.carrying() == "Cup", "while carrying the cup, the cushion stays where it is")
	await walk_to(player, house.WELCOME["Lamp"]["ring"])
	check(house.placed().is_empty() and house.carrying() == "Cup", "the lamp's ring does not take the cup: nothing goes wrong, it just waits")
	await shot("02_carrying")
	await walk_to(player, house.WELCOME["Cup"]["ring"])
	check(house.placed() == ["Cup"] and house.carrying().is_empty() and "1 / 3" in story._checklist._title.text,
			"the cup's ring takes the cup and ticks it on the list")
	for thing in ["Lamp", "Cushion"]:
		await walk_to(player, house.WELCOME[thing]["at"])
		await walk_to(player, house.WELCOME[thing]["ring"])
	check(house.placed().size() == 3, "the cushion, the cup and the lamp can go on the table in any order")
	await create_timer(0.8).timeout
	var cup: Node3D = house.get_node("Cup")
	check(cup.global_position.distance_to(house.WELCOME["Cup"]["on"]) < 0.05, "each one settles onto the table")

	print("-- Samuel and the brothers --")
	check(story.phase == story.Phase.MEET and "Welcome to our home" in line_text(), "with everything ready, Jesse welcomes Samuel")
	await create_timer(2.8).timeout
	check(house.samuel().global_position.distance_to(house.SAMUEL_PLACE) < 0.1, "Samuel has walked to the table")
	await shot("03_meet")
	story._advance()
	check(story.phase == story.Phase.PROCESSION and story.get_action_hint().is_empty() and not player.can_move,
			"the brothers' turn cannot be skipped or walked through")
	var started := Time.get_ticks_msec()
	await create_timer(4.0).timeout
	var stepped_out := 0
	for brother in house.sons().brothers():
		if brother.global_position.distance_to(brother.home) > 0.3:
			stepped_out += 1
	check(stepped_out >= 1 and stepped_out <= 3, "a few brothers are forward at once, not all seven (%d)" % stepped_out)
	await shot("04_procession")
	while story.phase == story.Phase.PROCESSION and Time.get_ticks_msec() - started < 20000:
		await process_frame
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	check(seconds > 7.5 and seconds < 11.5, "all seven pass before Samuel in about nine seconds (%.1f s)" % seconds)
	var home_again := true
	for brother in house.sons().brothers():
		home_again = home_again and brother.global_position.distance_to(brother.home) < 0.05
	check(home_again, "every brother is back in the line")
	check(story.phase == story.Phase.NOT_THESE and "Yahweh has not chosen these" in line_text(), "Samuel says calmly that these are not the ones")

	print("-- David comes home --")
	story._advance()
	check(story.phase == story.Phase.ASK and "Are all your children here" in line_text() and "youngest" in line_text(),
			"Samuel asks, and Jesse says the youngest is with the sheep")
	story._advance()
	check(story.phase == story.Phase.CALL and story.get_action_hint() == "CALL", "the child calls David home: the button says CALL")
	var call := InputEventAction.new()
	call.action = "interact"
	call.pressed = true
	story._input(call)
	check(story.phase == story.Phase.HOME and house.david().visible, "David comes along the sheep path")
	await create_timer(4.6).timeout
	check(story.phase == story.Phase.DAVID and house.david().global_position.distance_to(house.DAVID_PLACE) < 0.1
			and "You called for me" in line_text(), "David stands before Samuel: \"You called for me?\"")
	await shot("05_david")

	print("-- the verse and the anointing --")
	story._advance()
	check(story.phase == story.Phase.VERSE and "1 Samuel 16:7" in line_text() and "Yahweh looks at the heart" in line_text()
			and Profiles.has_verse(Profiles.active_id, JournalContent.VERSE_SAMUEL_16_7),
			"1 Samuel 16:7 is read, as written, and goes into the journal")
	story._advance()
	check(story.phase == story.Phase.WORDS and story._words.visible and "God sees who you are inside" in line_text(),
			"Wonder Light says it simply, and God, Sees and Heart wait to be tapped")
	for i in [2, 0, 1]:
		story.press_word(i)
	check(story.phase == story.Phase.ANOINT and not story._words.visible, "tapping all three, in any order, moves on to the anointing")
	await create_timer(1.2).timeout
	check(house.david().kneel > 0.95 and house.samuel().global_position.distance_to(house.david().global_position) < house.ANOINT_GAP + house.ANOINT_SIDE,
			"David kneels, and Samuel comes close to him")
	await create_timer(1.4).timeout
	check(house.oil_shown() and house.samuel().reach > 0.5, "Samuel lifts the horn and the oil runs down")
	await create_timer(0.9).timeout
	var horn: Node3D = house.samuel().find_child("OilHorn", true, false).get_node("Horn")
	var head: Vector3 = house.david().head_top()
	check(Vector2(horn.global_position.x - head.x, horn.global_position.z - head.z).length() < 0.12 and horn.global_position.y > head.y,
			"the horn is held over David's head, so the oil runs down onto it, not across to him (%.2f m aside, %.2f m above)"
			% [Vector2(horn.global_position.x - head.x, horn.global_position.z - head.z).length(), horn.global_position.y - head.y])
	await shot("06_anoint")
	await create_timer(4.4).timeout
	check(not house.oil_shown() and house.david().kneel < 0.01 and story.get_action_hint() == "NEXT",
			"the oil is gone again, David stands, and the story waits for the child")
	story._advance()
	check(story.phase == story.Phase.REFLECT and "God sees you too" in line_text(), "the reflection: God saw his heart, and sees you too")

	print("-- the charm --")
	story._advance()
	check(story.phase == story.Phase.CHARM and Profiles.has_charm(Profiles.active_id, JournalContent.CHARM_FAITHFUL_HEART),
			"the Faithful Heart charm is earned")
	await shot("07_charm")
	if story._ceremony:
		story._on_charm_sealed()
	story._advance()
	await create_timer(0.3).timeout
	var menu: Node = main.get_node("GameMenu")
	check(story.phase == story.Phase.DONE and Profiles.has_finished(Profiles.active_id, Profiles.CHAPTER_BEGINNING)
			and Profiles.is_unlocked(Profiles.active_id, Profiles.CHAPTER_ARK), "the chapter is finished, and Noah's Ark opens")
	check(menu._end_charm == JournalContent.CHARM_FAITHFUL_HEART and "Faithful Heart" in menu._end_title.text, "the end card names the Faithful Heart charm")
	await shot("08_end")

	await create_timer(0.3).timeout
	DirAccess.remove_absolute(PROFILE_FILE)
	print("BEGINNING REVIEW %s" % ("PASSED" if failures == 0 else "FAILED"))
	quit(0 if failures == 0 else 1)
