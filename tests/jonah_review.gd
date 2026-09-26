extends SceneTree
## Plays Chapter 5, Jonah and the Great Fish, from its first line to the end card, with checks at
## every beat: Joppa and its people, finding Jonah's things, the gangway, Secure the Cargo (any
## order, a space only takes its own piece), the storm rising and calming slowly (and hardly at
## all with Calm motion), Jonah going into the sea behind the wave, the great fish, Prayer in
## the Deep (only the next light, and it lights itself if nobody taps), the verse, the shore,
## Nineveh's gate and its people, the plant, the reflection and the Mercy charm, then carrying on
## after the game is closed.
##
##   godot --headless --path . --script tests/jonah_review.gd
##   godot --path . --script tests/jonah_review.gd --resolution 1280x720 -- --capture
##
## With --capture (the real renderer, not --headless), each key moment is saved to
## .godot/jonah-review/.
const Profiles := preload("res://scripts/profiles.gd")
const Settings := preload("res://scripts/game_settings.gd")
const JournalContent := preload("res://scripts/journal_content.gd")
const CharmArt := preload("res://scripts/charm_art.gd")

const PROFILE_FILE := "res://.godot/jonah-review-profile.cfg"

var failures: int = 0
var main: Node
var capture: bool = false


func _initialize() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	DirAccess.remove_absolute(PROFILE_FILE)
	Profiles.use_file(PROFILE_FILE)
	Profiles.set_active(Profiles.create("Jonah Review", "sun"))
	for chapter in [Profiles.CHAPTER_VALLEY, Profiles.CHAPTER_CAMP, Profiles.CHAPTER_BEGINNING]:
		Profiles.finish_chapter(chapter)
	Profiles.current_chapter = ""
	# The saved settings are the tablet's (a child who plays with Easy words saves it there): load them
	# first, then set what the checks expect, so playing the game never changes a test's result.
	Settings.load_settings()
	Settings.read_aloud = false
	Settings.easy_words = false
	Settings.reduced_motion = false
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/jonah-review"))
	root.get_texture().get_image().save_png("res://.godot/jonah-review/%s.png" % label)


func line_text() -> String:
	return (main.find_child("DialogueLabel", true, false) as Label).text


func prompt_text() -> String:
	return (main.find_child("PromptLabel", true, false) as Label).text


func faces(who: Node3D, other: Node3D) -> bool:
	var forward := -who.global_basis.z
	var to := other.global_position - who.global_position
	var angle := Vector2(forward.x, forward.z).angle_to(Vector2(to.x, to.z))
	return absf(angle) < deg_to_rad(25.0)


func solid_at(space: PhysicsDirectSpaceState3D, point: Vector3) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	for hit in space.intersect_point(query):
		if hit["collider"] is StaticBody3D:
			return true
	return false


func walk_to(player: Node3D, at: Vector3) -> void:
	player.global_position = Vector3(at.x, at.y + 0.3, at.z)
	await settle(3)


## Waits until `done` is true or `seconds` pass. Returns whether it came true.
func wait_for(done: Callable, seconds: float) -> bool:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		if done.call():
			return true
		await process_frame
	return done.call()


func _run() -> void:
	await settle()
	check(not Profiles.is_unlocked(Profiles.active_id, Profiles.CHAPTER_JONAH), "Jonah waits for the ark")
	Profiles.finish_chapter(Profiles.CHAPTER_ARK)
	check(Profiles.is_unlocked(Profiles.active_id, Profiles.CHAPTER_JONAH) and Profiles.next_chapter(Profiles.active_id) == Profiles.CHAPTER_JONAH,
			"finishing Noah's Ark opens Jonah, the next story")
	var journey: Node = main.get_node("FaithJourney")
	journey.open_to_choose()
	await settle()
	check("Jonah and the Great Fish is next." in journey._line.text and journey._marker_stop == "jonah", "the map says Jonah is next, and marks the fifth stop")
	journey._on_stop("jonah")
	await settle(8)
	var world: Node = main.get_node_or_null("JonahsJourney")
	var story: Node = main.get_node_or_null("JonahsJourney/ChapterFive")
	var player: Node3D = main.get_node("Player")
	check(world != null and story != null and story.phase == story.Phase.ARRIVE and "ran the other way" in line_text(),
			"the map's fifth stop opens Joppa at its first line")
	check(world.place == "joppa" and world.place_root("joppa").visible and not world.place_root("sea").visible
			and not world.place_root("land").visible, "only Joppa is in view; the other places wait, hidden")
	check(world.jonah().find_child("*Body", true, false) != null and world.captain().find_child("*Body", true, false) != null,
			"Jonah and the captain are the Blender paper people")
	check(world.jonah().find_child("JonahBody", true, false) != null,
			"Jonah uses his own Blender model, not a tinted brother")
	check(world._sounds.is_playing() and world._sounds._harbour.stream != null,
			"Joppa starts its harbour sound bed")
	check(not player.can_move and story.get_action_hint() == "NEXT", "the first line holds the child still, and the button says NEXT")
	var space := (world as Node3D).get_world_3d().direct_space_state
	check(solid_at(space, Vector3(2.0, 1.0, world.QUAY_EDGE - 0.1)), "the quay's edge is solid: nobody walks off it into the water")
	await shot("01_joppa")

	print("-- Jonah's things --")
	story._advance()
	await settle()
	check(story.phase == story.Phase.FIND and player.can_move and story._finds.visible and "0 / 3" in story._finds._title.text,
			"finding starts: the child can walk, and the list shows 0 / 3")
	var order := ["Lamp", "Bag", "Message"]
	for i in order.size():
		await walk_to(player, world.THINGS[order[i]])
		await settle(3)
		if i < order.size() - 1:
			check(("%d / 3" % (i + 1)) in story._finds._title.text and story.phase == story.Phase.FIND,
					"the %s is found (%d / 3)" % [order[i].to_lower(), i + 1])
	check(story.phase == story.Phase.MEET and "I don't want to go" in line_text() and world.found_things().size() == 3,
			"with all three found, Jonah says he does not want to go")
	check(str(Profiles.place_in(Profiles.active_id, Profiles.CHAPTER_JONAH).get("beat", "")) == "meet", "the place is kept at meeting Jonah")
	await shot("02_meet")
	story._advance()
	await settle()
	check(story.phase == story.Phase.BOARD and player.can_move and world.gangway_ring().visible, "Jonah boards, and a ring shows the child where to follow")
	# A child can reach the ring before Jonah's boarding tween finishes; changing place must cancel
	# that tween so it cannot pull him back to Joppa after he has been placed on the ship.
	await walk_to(player, world.GANGWAY_SPOT)
	var sailed: bool = await wait_for(func() -> bool: return story.phase == story.Phase.CARGO, 3.0)
	check(sailed and world.place == "sea" and world.place_root("sea").visible and not world.place_root("joppa").visible,
			"the page turns: the ship is out at sea")
	var on_deck: Vector3 = player.global_position - world.AT_SEA
	check(absf(on_deck.x) < world.DECK_SIZE.x * 0.5 and absf(on_deck.z) < world.DECK_SIZE.y * 0.5 and absf(on_deck.y) < 0.3
			and world.jonah().global_position.distance_to(world.AT_SEA + world.JONAH_AT_SEA) < 0.1, "the child and Jonah are on the ship's deck")
	check(world._sounds._storm.playing and world._sounds._storm.stream != null, "the ship brings in the storm sound bed")
	# Reopening the current stop used to restore Joppa's bounds and push the child hundreds of metres
	# off the distant ship. Closing the map must restore the sea area's bounds without moving them.
	var before_map := player.global_position
	journey.open()
	journey._on_stop("jonah")
	await settle(3)
	check(player.global_position.distance_to(before_map) < 0.2 and main.get_node("PlayBounds").center.distance_to(world.sea_area.center) < 0.01,
			"reopening Jonah from the map keeps the child and the play bounds on the ship")
	await shot("03_at_sea")

	print("-- Secure the Cargo --")
	check(story._cargo_list.visible and "0 / 3" in story._cargo_list._title.text and "cargo" in line_text(), "the cargo list shows 0 / 3")
	var storm_before: float = world.sea().storm
	await create_timer(1.0).timeout
	check(world.sea().storm > storm_before and world.sea().storm < 0.4, "the storm begins to rise, slowly")
	await walk_to(player, world.AT_SEA + world.CARGO["Jar"]["at"])
	check(world.carrying() == "Jar", "the jar is picked up and floats beside Wonder Light")
	await walk_to(player, world.AT_SEA + world.CARGO["Sack"]["spot"])
	check(world.carrying() == "Jar" and world.secured().is_empty(), "the sack's space does not take the jar")
	await walk_to(player, world.AT_SEA + world.CARGO["Jar"]["spot"])
	check(world.secured() == ["Jar"] and "1 / 3" in story._cargo_list._title.text, "the jar goes into its own space (1 / 3)")
	for piece in ["Rope", "Sack"]:
		await walk_to(player, world.AT_SEA + world.CARGO[piece]["at"])
		await walk_to(player, world.AT_SEA + world.CARGO[piece]["spot"])
	check(world.secured().size() == 3 and story.phase == story.Phase.STORM and "Hold on" in line_text(),
			"all three are secured, and the captain speaks as the storm rises")
	await create_timer(5.5).timeout
	check(world.sea().storm > 0.95 and world.sea().rain_falling(), "the storm is at its height: waves up, rain falling")
	var band: Node3D = world.sea().band_nodes()[0]
	var sway := 0.0
	var home := band.position.x
	for _i in 60:
		await process_frame
		sway = maxf(sway, absf(band.position.x - home))
	Settings.reduced_motion = true
	var calm_sway := 0.0
	home = band.position.x
	for _i in 60:
		await process_frame
		calm_sway = maxf(calm_sway, absf(band.position.x - home))
	Settings.reduced_motion = false
	check(calm_sway < sway * 0.6, "with Calm motion on, the waves barely travel (%.2f m against %.2f m)" % [calm_sway, sway])
	await shot("04_storm")

	print("-- the sea goes calm --")
	var carried_on: bool = await wait_for(func() -> bool: return story.phase == story.Phase.ADMIT, 8.0)
	check(carried_on and "because of me" in line_text(), "with nobody tapping, the story carries on at sea: Jonah admits it")
	check(faces(world.captain(), world.jonah()) or faces(world.jonah(), world.captain()), "Jonah and the captain turn to each other")
	await create_timer(0.7).timeout
	check(world.jonah().heart > 0.9 and world.jonah().slump > 0.5 and world.captain().brace > 0.4 and world.crew()[2].sway > 0.5,
			"Jonah hangs his head, a hand on his heart; the crew brace and rock with the deck")
	story._advance()
	await settle()
	await create_timer(0.7).timeout
	check(story.phase == story.Phase.PLEAD and "please be kind" in line_text() and world.captain().plead > 0.9,
			"the captain does not want to, and raises his hands to pray")
	story._advance()
	await settle()
	check(story.phase == story.Phase.OVERBOARD and story.get_action_hint() == "", "Jonah goes to the ship's side; nothing for the child to press")
	var hidden: bool = await wait_for(func() -> bool: return not world.jonah().visible, 6.0)
	check(hidden and world.cover_wave_top() > world.COVER_WAVE.y + 2.0, "the great wave rises, and Jonah is gone behind it (never thrown)")
	var fish_came: bool = await wait_for(func() -> bool: return story.phase == story.Phase.FISH, 8.0)
	check(fish_came and world.sea().storm < 0.1, "the storm has calmed with the wave")
	await shot("05_calm")
	var surfaced: bool = await wait_for(func() -> bool: return world.fish().surfaced(), 6.0)
	check(surfaced and "great fish" in line_text() and world.fish().find_child("Eye", true, false) != null
			and world.fish().find_child("*Teeth*", true, false) == null, "the great fish rises: a calm eye, and no teeth")
	await shot("06_fish")

	print("-- Prayer in the Deep --")
	var prayed: bool = await wait_for(func() -> bool: return story.phase == story.Phase.PRAY, 12.0)
	check(prayed and world.place == "deep" and world.place_root("deep").visible and story._lights.visible,
			"the story carries on into the fish: a calm blue chamber, and three lights to tap")
	check(world.jonah().kneel > 0.9, "Jonah kneels to pray")
	story.press_light(2)
	check(story._lit == 0, "only the next light can be tapped (Go waits for Call and Hear)")
	story.press_light(0)
	await settle()
	check(story._lit == 1 and (story._light_buttons[0] as Button).text == "Call", "Call is lit, and its light rises")
	var light: Node3D = world.place_root("deep").get_node_or_null("PrayerLight0")
	var start := light.global_position if light else Vector3.ZERO
	await create_timer(1.2).timeout
	var wonder: Node3D = main.get_node("WonderLight")
	check(light != null and light.global_position.distance_to(wonder.global_position) < start.distance_to(wonder.global_position) - 0.3,
			"the light drifts up to Wonder Light")
	await shot("07_prayer")
	var self_lit: bool = await wait_for(func() -> bool: return story._lit == 2, 9.0)
	check(self_lit, "with nobody tapping, Hear lights itself after a while")
	story.press_light(2)
	var versed: bool = await wait_for(func() -> bool: return story.phase == story.Phase.VERSE, 3.0)
	check(versed and "Jonah 2:2" in line_text() and Profiles.has_verse(Profiles.active_id, JournalContent.VERSE_JONAH_2_2),
			"all three lit: the verse, Jonah 2:2, goes into the journal")
	story._advance()
	await settle()
	check(story.phase == story.Phase.THANKS and "another chance" in line_text(), "Jonah thanks God for another chance")

	print("-- the shore and Nineveh --")
	story._advance()
	var ashore: bool = await wait_for(func() -> bool: return world.place == "land" and not story._busy, 9.0)
	check(ashore and world.jonah().global_position.distance_to(world.LAND + world.JONAH_SHORE) < 0.2 and world.message_open(),
			"the fish sets Jonah on the shore, and the message opens toward Nineveh (%s, %s, %s)" % [ashore, world.jonah().global_position - world.LAND, world.message_open()])
	check(not world.shore_fish().surfaced(), "the fish goes back into the deep")
	await shot("08_shore")
	story._advance()
	await settle()
	check(story.phase == story.Phase.FOLLOW and player.can_move and world.gate_ring().visible and "this time, Jonah went" in line_text(),
			"God asks again, and the child walks with Jonah to the gate")
	await create_timer(1.0).timeout
	await walk_to(player, world.LAND + world.GATE_SPOT)
	check(story.phase == story.Phase.WARNING and "Forty more days" in line_text(), "at the gate Jonah gives God's message")
	await create_timer(0.8).timeout
	var listening := 0
	for person in world.crowd().people():
		if faces(person, world.jonah()):
			listening += 1
	check(listening == world.crowd().people().size(), "every one of Nineveh's people turns to listen (%d of %d)" % [listening, world.crowd().people().size()])
	await shot("09_gate")
	story._advance()
	await create_timer(0.8).timeout
	var kneeling := 0
	for person in world.crowd().people():
		if person.kneel > 0.9:
			kneeling += 1
	check(story.phase == story.Phase.LISTENED and kneeling >= 3 and "turned away from the wrong" in line_text(),
			"they are sorry, and turn away from the wrong they did (%d kneel)" % kneeling)
	check(world._sounds._market.playing and world._sounds._market.stream != null, "Nineveh has its market sound bed")
	var kneeler: Node3D = null
	for person in world.crowd().people():
		if person.kneel > 0.9:
			kneeler = person
	var sk := kneeler.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var knee := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Shin_L")).origin
	var foot := sk.global_transform * (sk.get_bone_global_pose(sk.find_bone("Shin_L")) * Vector3(0.0, 0.2, 0.0))
	var back := kneeler.global_basis.z
	check((foot - knee).dot(back) > 0.1 and foot.y > kneeler.global_position.y - 0.05,
			"kneeling, their feet are behind them on the ground, not stuck out in front")
	story._advance()
	var on_hill: bool = await wait_for(func() -> bool: return story.phase == story.Phase.HILL and not story._busy, 8.0)
	check(on_hill and world.plant().grown > 0.99 and "a plant grow" in line_text(), "Jonah on the hill, cross; the plant grows over him")
	await shot("10_plant")
	story._advance()
	await create_timer(3.5).timeout
	check(story.phase == story.Phase.WITHER and world.plant().withered > 0.99, "the next day the plant dries, its leaves folding down")
	story._advance()
	await settle()
	check(story.phase == story.Phase.QUESTION and "a whole city" in line_text(), "God's question: a plant, and a whole city of people")
	story._advance()
	await settle()
	check(story.phase == story.Phase.REFLECT and "another chance" in line_text(), "the reflection names both sides of mercy")

	print("-- the Mercy charm --")
	story._advance()
	await settle()
	check(story.phase == story.Phase.CHARM and Profiles.has_charm(Profiles.active_id, JournalContent.CHARM_MERCY),
			"the Mercy charm is earned")
	check(CharmArt.region_count(JournalContent.CHARM_MERCY) == 6, "the Mercy charm has its own picture to colour")
	var sealed: bool = await wait_for(func() -> bool: return not story._ceremony, 12.0)
	check(sealed and "keep your charm" in prompt_text(), "once it lands, Space keeps the charm")
	await shot("11_charm")
	story._advance()
	await create_timer(0.4).timeout
	var menu: Node = main.get_node("GameMenu")
	check(story.phase == story.Phase.DONE and Profiles.has_finished(Profiles.active_id, Profiles.CHAPTER_JONAH), "the chapter is finished")
	check(menu._end_panel.visible and menu._end_charm == JournalContent.CHARM_MERCY, "the end card names the Mercy charm")
	check(Profiles.place_in(Profiles.active_id, Profiles.CHAPTER_JONAH).is_empty(), "finishing forgets the place, so Play again starts at Joppa")
	check(JournalContent.MYSTERY_SLOTS == 0, "all five charms of the first journey have their place in the journal")

	print("-- the pause menu and the journal fit --")
	# A short screen, shorter than the laptop the menu first ran off the bottom of.
	var window_size: Vector2i = root.size
	root.size = Vector2i(1280, 600)
	await settle()
	menu.set_paused(true)
	await settle()
	var scroll: ScrollContainer = menu._pause_scroll
	var room: float = root.get_visible_rect().size.y
	var buttons: Array = menu._pause_box.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return (b as Button).text == "Change player")
	check(scroll.size.y <= room - 80.0 and buttons.size() == 1 and (menu._pause_box.size.y <= scroll.size.y + 1.0 or scroll.get_v_scroll_bar().max_value >= menu._pause_box.size.y - 1.0),
			"the pause menu fits the screen (%d of %d px), and scrolls to Change player at the bottom" % [scroll.size.y, room])
	menu.set_paused(false)
	root.size = window_size
	var journal: Node = main.get_node("JournalScreen")
	Profiles.unlock_charm(JournalContent.CHARM_FAITHFUL_HEART)
	journal.open()
	await settle()
	var fits := true
	for card in journal._charm_row.get_children():
		for label in card.find_children("*", "Label", true, false):
			var inside: bool = (label as Label).get_rect().end.x <= (card as Control).size.x + 1.0 and (label as Label).get_global_rect().position.x >= (card as Control).get_global_rect().position.x - 1.0
			if not inside:
				print("   %s: %s in a card %s" % [(label as Label).text, (label as Label).get_global_rect(), (card as Control).get_global_rect()])
			fits = fits and inside
	var heart_label: Label = null
	for label in journal._charm_row.find_children("*", "Label", true, false):
		if (label as Label).text == "Faithful Heart":
			heart_label = label
	check(fits and heart_label != null and heart_label.get_line_count() <= 2 and journal._charm_row.get_child_count() == 2,
			"every charm's name stays inside its card, Faithful Heart too (wrapping if it must)")
	journal.close()

	print("-- carrying on after the game was closed --")
	var child := Profiles.active_id
	Profiles.mark_place(Profiles.CHAPTER_JONAH, "prayer")
	Profiles.use_file(PROFILE_FILE)
	Profiles.set_active(child)
	main.switch_to(Profiles.CHAPTER_JONAH)
	await settle(8)
	world = main.get_node("JonahsJourney")
	story = world.get_node("ChapterFive")
	check(story.phase == story.Phase.PRAY and world.place == "deep" and story._lights.visible, "opening Jonah again carries on in the deep, at the prayer")
	world.stand_down()
	Profiles.mark_place(Profiles.CHAPTER_JONAH, "hill")
	main.switch_to(Profiles.CHAPTER_JONAH)
	await settle(8)
	world = main.get_node("JonahsJourney")
	story = world.get_node("ChapterFive")
	check(story.phase == story.Phase.HILL and world.place == "land" and world.plant().grown > 0.99
			and world.jonah().global_position.distance_to(world.LAND + world.JONAH_HILL) < 0.1, "or on the hill, with the plant grown")
	Profiles.forget_place(Profiles.CHAPTER_JONAH)

	print("")
	print("JONAH REVIEW %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)
