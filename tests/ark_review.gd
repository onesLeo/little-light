extends SceneTree
## Headless pass through the Noah's Ark greybox.
const Profiles := preload("res://scripts/profiles.gd")
const Settings := preload("res://scripts/game_settings.gd")
const JournalContent := preload("res://scripts/journal_content.gd")
const PaperUI := preload("res://scripts/paper_ui.gd")

var failures: int = 0
var main: Node


func _initialize() -> void:
	DirAccess.remove_absolute("res://.godot/ark-review-profile.cfg")
	Profiles.use_file("res://.godot/ark-review-profile.cfg")
	Profiles.set_active(Profiles.create("Ark Review", "olive"))
	Profiles.current_chapter = ""
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	print("OK " if ok else "FAIL ", label)
	if not ok:
		failures += 1


func settle(frames: int = 5) -> void:
	for _i in frames:
		await process_frame


func _run() -> void:
	await settle()
	Settings.read_aloud = false
	main.get_node("AudioDirector").stop_speech()
	main.get_node("GameMenu").end_panel_delay = 0.05
	var cam: Camera3D = main.get_node("TabletopCamera")
	# The scene's own framing, before the ark borrows the camera.
	var framing: Array = [cam.offset, cam.look_height, cam.fov]
	var kid := Profiles.active_id
	check(not Profiles.is_unlocked(kid, Profiles.CHAPTER_ARK), "the ark stays closed until the camp is finished")
	Profiles.finish_chapter(Profiles.CHAPTER_VALLEY)
	Profiles.finish_chapter(Profiles.CHAPTER_CAMP)
	check(Profiles.is_unlocked(kid, Profiles.CHAPTER_ARK), "finishing the camp opens Noah's Ark")

	var ark: Node = main.get_node("NoahsArk")
	# The game opens the ark from the Faith Journey map, which closes first and unpauses.
	var journey: Node = main.get_node("FaithJourney")
	if journey.is_open():
		journey.close()
	main.switch_to(Profiles.CHAPTER_ARK)
	await settle()
	var story: Node = ark.get_node("ChapterFour")
	var player: Node3D = main.get_node("Player")
	check(ark.get_node("Noah").find_child("NoahBody", true, false) != null, "Noah in the scene is the designed model")
	check(ark.get_node("NoahsWife").find_child("NoahsWifeBody", true, false) != null, "his wife in the scene is her own model")
	var elephant: Node3D = ark.get_node("ElephantA")
	var elephant_top := 0.0
	for mesh in elephant.find_children("*", "MeshInstance3D", true, false):
		if elephant.get_node("Beacon").is_ancestor_of(mesh) or mesh.name == "Ring":
			continue  # the gold marker floats over the head on purpose
		var box: AABB = (mesh as MeshInstance3D).global_transform * (mesh as MeshInstance3D).get_aabb()
		elephant_top = maxf(elephant_top, box.end.y - elephant.global_position.y)
	var headroom: float = ark.DOOR_TOP - (ark._doorstep(0.0).y - ark.ORIGIN.y)
	check(elephant_top > 2.0 and headroom >= elephant_top,
			"the doorway (%.2f m) is tall enough for an elephant (%.2f m)" % [headroom, elephant_top])
	check(ark.get_node("Noah")._bones["Thigh_L"] >= 0 and ark.get_node("NoahsWife")._bones["Shin_R"] >= 0, "both parents have the leg bones used for boarding")
	check("Long before David" in story._line.text, "arrival names the long work")
	# The tools lie on three of the allowed spots, well apart, wherever this visit put them.
	var first_layout: Array[Vector3] = []
	var on_spots := true
	for tool_name in story.TOOLS:
		var at: Vector3 = (ark.get_node(tool_name) as Node3D).global_position - ark.ORIGIN
		first_layout.append(at)
		var near_spot := false
		for spot in ark.TOOL_SPOTS:
			near_spot = near_spot or Vector2(at.x - spot.x, at.z - spot.z).length() <= ark.TOOL_JITTER * 1.5
		on_spots = on_spots and near_spot
	check(on_spots and first_layout[0].distance_to(first_layout[1]) > 2.5 and first_layout[1].distance_to(first_layout[2]) > 2.5
			and first_layout[0].distance_to(first_layout[2]) > 2.5, "the tools lie on allowed spots, well apart")
	check(not player.can_move, "arrival holds still")
	check(not ark.get_node("Rain").visible, "the plain starts dry")
	story._advance()
	check("hurting one another" in story._line.text, "the brokenness is named once")
	story._advance()
	check(story.phase == story.Phase.FIND and player.can_move, "finding the tools unlocks walking")
	check(story._checklist.visible and "0 / 3" in story._checklist._title.text, "a picture list of Noah's tools shows during the hunt")
	story._hints.hint_delay = 0.05
	await settle(20)
	check(story._hints.is_pointing(), "the golden arrow points at a tool when the child is stuck")
	story._hints.hint_delay = story.HINT_FIND

	# Walking onto a glowing tool picks it up, like the gifts in the camp.
	player.global_position = ark.get_node("Mallet").global_position
	await settle(2)
	check("Mallet" in story._found and story._checklist.is_found("Mallet"), "walking onto a tool picks it up and ticks it")
	# The map mid-story, then the ark again: the story carries on where it was.
	var stood_at: Vector3 = player.global_position
	journey.open()
	journey._on_stop("ark")
	await settle(2)
	check(main.get_node("NoahsArk") == ark and story.phase == story.Phase.FIND and story._found == ["Mallet"],
			"tapping the ark on the map mid-story keeps the story where it was")
	check(player.global_position.distance_to(stood_at) < 0.5 and not ark.get_node("Mallet").visible,
			"the child is not sent back to the start and the mallet stays picked up")
	# The last tool lies behind Noah and the child picks it up facing away from him: back to back.
	var noah: Node3D = ark.get_node("Noah")
	var walker_model: Node3D = player.get_node("Model")
	ark.get_node("Pitch").global_position = noah.global_position + Vector3(0.0, 0.0, -1.6)
	player.global_position = ark.get_node("RopeCoil").global_position
	story._try_collect()
	player.global_position = ark.get_node("Pitch").global_position
	walker_model.rotation.y = 0.0
	story._try_collect()
	check(story.phase == story.Phase.MEET and not ark.get_node("Pitch").visible, "three tools are brought to Noah")
	check(story._turning and story.get_action_hint().is_empty(), "Noah and the child turn to each other before he speaks")
	await create_timer(story.TURN_SECONDS + 0.2).timeout
	var to_child := player.global_position - noah.global_position
	to_child.y = 0.0
	var noah_face := -noah.global_transform.basis.z
	var child_face := -walker_model.global_transform.basis.z
	noah_face.y = 0.0
	child_face.y = 0.0
	check(noah_face.normalized().dot(to_child.normalized()) > 0.95 and child_face.normalized().dot(-to_child.normalized()) > 0.95,
			"Noah and the child face each other, even when the last tool was behind him")
	var shot: Camera3D = main.get_node("CloseUpCamera")
	check(shot.current and shot.is_position_in_frustum(noah.global_position + Vector3(0.0, 1.6, 0.0))
			and shot.is_position_in_frustum(player.global_position + Vector3(0.0, 1.1, 0.0)),
			"the meeting is framed with both of them in view")
	check("I trust him" in story._line.text, "Noah says he trusts before he sees the rain")
	story._advance()
	check(story.phase == story.Phase.PANEL, "the panel activity starts")
	check(not story._checklist.visible and ark.get_node("WorkPanel/SocketGlow0").visible, "the list goes away and the first peg socket glows")

	player.global_position = ark.get_node("WorkPanel").global_position
	check(story.get_action_hint() == "PEG", "on a tablet the gold button says PEG at the bench")
	var said: String = story._line.text
	for _i in 3:
		story._place_peg()
	check(story._pegs == 3 and ark.get_node("WorkPanel/Peg2") != null, "three pegs land in the panel")
	check(story._line.text == said and "rope" in story._prompt.text, "the pegs move the prompt on without repeating the line")
	check(story.get_action_hint() == "PULL", "then the button says PULL")
	story.add_rope(story.ROPE_STEP)
	story.add_rope(story.ROPE_STEP)
	check(story.phase == story.Phase.PAIRS and story._rope_steps == 2, "two rope pulls finish the panel")
	await settle(2)
	check(ark.get_node("SheepA/Beacon").visible and not ark.get_node("SheepB").has_node("Beacon"), "gold markers show which animals to lead")
	player.global_position = ark.get_node("DoveA").global_position
	story._try_guide()
	check(story._guide == "DoveA" and ark.get_node("DoveB/Ring").visible, "leading a dove lights a ring under its partner")
	var dove_start: Vector3 = ark.get_node("DoveA").position
	story._finish_guide()
	check(ark.get_node("DoveA").position == dove_start and ark.aboard_count() == 0, "matching starts a walk instead of teleporting aboard")
	check(ark.nearest_guide(ark.get_node("DoveA").global_position, 0.1).is_empty(), "a boarding animal cannot be selected again")
	await create_timer(0.3).timeout
	check(ark.get_node("DoveA").position.distance_to(dove_start) > 0.05, "the boarding animal moves along its approach")
	check(not ark.get_node("DoveB/Ring").visible, "the ring goes when the pair boards")

	var sheep: Node3D = ark.get_node("SheepA")
	story._guide = "SheepA"
	sheep.global_position = ark.get_node("GoatB").global_position
	story._follow(0.05)
	check(story._mismatch_said and not bool(sheep.get_meta("aboard")), "a mismatch points to the real mate and boards nobody")
	var hip := sheep.get_node("Hip") as Node3D
	story._mismatch_said = false
	for _i in 6:
		story._follow(0.05)
	check(absf(hip.rotation.x) > 0.02 and sheep.find_child("Hoof*", true, false) != null, "a led animal steps on hoofed legs as it walks")
	sheep.global_position = ark.get_node("SheepB").global_position
	story._follow(0.05)
	check(story._matched == 2 and bool(sheep.get_meta("boarding", false)), "standing with the matching sheep starts boarding the pair")
	story._guide = "ElephantA"
	story._finish_guide()
	check(story.phase == story.Phase.BOARDING and ark.is_boarding(), "the final match starts the boarding story phase")
	check(not ark.get_node("Door").visible and story.get_action_hint().is_empty(), "the door stays open and NEXT is hidden during boarding")
	story._advance()
	check(story.phase == story.Phase.BOARDING and not ark.get_node("Rain").visible, "continue cannot skip boarding into rain")
	var paused_at: Vector3 = ark.get_node("DoveA").position
	paused = true
	await create_timer(0.2, true).timeout
	check(ark.get_node("DoveA").position == paused_at, "pausing also pauses boarding")
	paused = false
	var deadline := Time.get_ticks_msec() + 35000
	# Noah and his wife are the Blender models, which face -z; while they walk, their faces lead.
	var parents: Array[Node3D] = [ark.get_node("Noah"), ark.get_node("NoahsWife")]
	var was: Array[Vector3] = [parents[0].global_position, parents[1].global_position]
	var walking_frames := 0
	var backwards_frames := 0
	while ark.is_boarding() and Time.get_ticks_msec() < deadline:
		await process_frame
		for i in parents.size():
			var step := parents[i].global_position - was[i]
			was[i] = parents[i].global_position
			step.y = 0.0
			if step.length() < 0.01 or not parents[i].visible:
				continue
			walking_frames += 1
			var face := -parents[i].global_transform.basis.z
			face.y = 0.0
			if face.normalized().dot(step.normalized()) < 0.0:
				backwards_frames += 1
	check(walking_frames > 20 and backwards_frames == 0, "Noah and his wife walk up the ramp face first (%d of %d frames backwards)" % [backwards_frames, walking_frames])
	check(not ark.is_boarding() and story.phase == story.Phase.DOOR, "door phase waits for the last family member")
	check(story._matched == 3 and ark.aboard_count() == 12, "all twelve animals have actually reached the entrance")
	check(not ark.get_node("Noah").visible and not ark.get_node("NoahsWife").visible, "both parents have entered before the door closes")
	check(ark.get_node("Door").visible and not ark.get_node("SheepA/Beacon").visible, "God closes the door, and the markers are put away")
	check(ark.get_node("Noah").global_position.z < 5.0
			and player.global_position.distance_to(ark.get_node("Noah").global_position) > 3.0,
			"the guest stays outside while the family goes in")
	story._advance()
	check(ark.get_node("Rain").visible and "animals with them" in story._line.text, "rain stays on the ark and names who was kept safe")
	check(ark.get_node("Shelter").visible and ark.get_node("Shelter/ShelterCamera").current, "rain uses the sheltered interior camera")
	check(ark.get_node("Shelter/WindowRain").visible and ark.get_node("Shelter/ShelterNoah").visible, "rain is outside the window while Noah is safe inside")
	check(not player.can_move, "the child cannot wander off during the shelter scene")
	await capture("rain-shelter")
	await create_timer(0.3).timeout
	check(ark.get_node("Mountain/Flood").visible and not ark.get_node("Mountain/CloudSea").visible, "the water rises over the cloud sea while it rains")
	story._advance()
	var perch: Vector3 = ark.dove().position
	story._send_dove()
	story._send_dove()
	check(story._dove_flights == 1 and story.get_action_hint().is_empty(), "repeated SEND cannot start a second flight")
	await create_timer(1.2).timeout
	check(ark.dove().position.y > perch.y + 0.5 and absf(ark.dove().position.x - perch.x) > 0.5, "the dove climbs along a curved flight path")
	await capture("dove-flight")
	var flying_at: Vector3 = ark.dove().position
	paused = true
	await create_timer(0.2, true).timeout
	check(ark.dove().position == flying_at, "pausing freezes the dove flight")
	paused = false
	await create_timer(4.3).timeout
	check(story.phase == story.Phase.SKY and "came back safe" in story._line.text, "the first dove returns safe")
	var before: String = story._line.text
	story._turn_sky()
	check(story._line.text == before and "going down" in story._prompt.text, "the first turn of the sky lets the water go down without repeating the line")
	story._turn_sky()
	check(story.phase == story.Phase.LEAF, "turning the sky opens the second send")
	story._send_dove()
	await create_timer(5.5).timeout
	check(story.phase == story.Phase.OLIVE and ark.dove().get_node("Leaf").visible, "the dove lands with a visible olive leaf")
	await capture("olive-leaf")
	check(not ark.get_node("Rainbow").visible and ark.weather_state == "receding", "the leaf discovery happens before dry ground and rainbow")
	story._advance()
	check(story.phase == story.Phase.DRY and not ark.get_node("Shelter").visible, "dry ground returns to the exterior")
	check(not ark.get_node("Rainbow").visible, "dry ground has its own beat before the rainbow")
	await create_timer(2.7).timeout
	check(main.get_node("Sun").light_energy > 1.0, "morning has brighter sunlight than the building scene")
	await capture("dry-morning")
	check(ark.get_node("Noah").visible and ark.get_node("NoahsWife").visible, "the family emerges into the new morning")
	await create_timer(0.5).timeout
	check(not ark.get_node("Mountain/Flood").visible and ark.get_node("Mountain/CloudSea").visible, "the morning finishes draining the flood")
	story._advance()
	check(ark.get_node("Rainbow").visible and ark.get_node("RainbowCamera").current, "the verse reveals the rainbow in its wide story shot")
	await capture("rainbow")
	check(Profiles.has_verse(kid, JournalContent.VERSE_GENESIS_9_13), "Genesis 9:13 is in the journal")
	check("I set my rainbow in the cloud" in story._line.text, "the verse is the World English Bible wording")
	story._advance()
	check(story.phase == story.Phase.WORDS and story._words.visible, "Rainbow, Sign and Promise are on screen")
	story.press_word(2)
	story.press_word(0)
	story.press_word(1)
	check(story.phase == story.Phase.REFLECT and not story._words.visible, "the words can be tapped in any order and then leave")
	story._advance()
	if story._ceremony:
		story._on_charm_sealed()
	story._advance()
	await create_timer(0.2).timeout
	var menu := main.get_node("GameMenu")
	check(story.phase == story.Phase.DONE and Profiles.has_finished(kid, Profiles.CHAPTER_ARK), "the chapter finishes")
	check(Profiles.has_charm(kid, JournalContent.CHARM_TRUST), "the Trust charm is earned")
	check(menu._end_charm == JournalContent.CHARM_TRUST and "Trust" in menu._end_title.text, "the end card names the Trust charm")
	# Pausing over the end card: the pause menu is on top, and the card waits behind it.
	menu.set_paused(true)
	check(menu._pause_layer.visible and not menu._end_panel.visible
			and menu._pause_layer.get_index() > menu._end_panel.get_index(), "pausing puts the end card aside under the pause menu")
	menu.set_paused(false)
	check(menu._end_panel.visible and not menu._pause_layer.visible, "resuming brings the end card back")
	var ink: Color = menu.INK
	var toggles_stay_ink := true
	for toggle in [menu._read_check, menu._easy_check, PaperUI.button("Age")]:
		toggles_stay_ink = toggles_stay_ink and (toggle as Button).get_theme_color("font_hover_pressed_color") == ink
	check(toggles_stay_ink, "switches that are on keep their ink text when hovered")

	# Playing it again from the map, without reloading the scene, starts from a whole ark.
	journey.open()
	journey._on_stop("ark")
	await settle()
	var again: Node = main.get_node("NoahsArk")
	var story_again: Node = again.get_node("ChapterFour")
	check(again != ark and not is_instance_valid(ark), "a replay builds a fresh ark and frees the old one")
	check(story_again.phase == story_again.Phase.ARRIVE and "Long before David" in story_again._line.text, "a replay starts at the first line")
	check(again.tool_spots().size() == 3, "all three tools are back on the ground")
	var moved_tools := 0
	for i in story_again.TOOLS.size():
		var now_at: Vector3 = (again.get_node(story_again.TOOLS[i]) as Node3D).global_position - again.ORIGIN
		if now_at.distance_to(first_layout[i]) > 0.01:
			moved_tools += 1
	check(moved_tools > 0, "a replay lays the tools out afresh")
	check(again.get_node("Noah").visible and again.aboard_count() == 0 and not again.get_node("Door").visible, "the family and animals are outside and the door is open")
	check(not again.get_node("WorkPanel").has_node("Peg0") and not again.get_node("Rainbow").visible, "the panel is unpegged and the rainbow is put away")
	check(main.get_node("UI").find_children("ArkWords*", "", false, false).size() == 1
			and main.get_node("UI").find_children("ArkToolChecklist*", "", false, false).size() == 1,
			"the old word chips and tool list are gone")
	story_again._advance()
	story_again._advance()
	check(story_again.phase == story_again.Phase.FIND and story_again._checklist.visible and "0 / 3" in story_again._checklist._title.text, "the hunt can start again")

	# Mid-hunt, the child picks the camp on the map: only one story keeps running.
	story_again._hints.hint_delay = 0.05
	await settle(20)
	var ark_arrow: Node = story_again._hints._arrow2d
	journey.open()
	journey._on_stop("camp")
	await settle()
	var camp: Node = main.get_node("KingsCamp")
	var camp_story: Node = camp.get_node("ChapterTwo")
	var ark_now: Node = main.get_node("NoahsArk")
	check(not is_instance_valid(story_again) and not ark_now._built, "leaving the ark for the camp puts the ark's story away")
	check(main.get_node("UI").find_children("Ark*", "", false, false).is_empty() and not is_instance_valid(ark_arrow),
			"the ark's words, tool list and arrow leave the screen")
	check(cam.offset == framing[0] and cam.look_height == framing[1] and is_equal_approx(cam.fov, framing[2]) and cam.current,
			"the camp gets its own camera framing back")
	check(camp_story.phase == camp_story.Phase.ARRIVE and main.get_node("TouchControls")._hint() == camp_story.get_action_hint(),
			"the camp's story is the one the button follows")
	journey.open()
	journey._on_stop("ark")
	await settle()
	ark_now = main.get_node("NoahsArk")
	check(camp_story.phase == camp_story.Phase.IDLE and not camp_story._checklist.visible and not camp_story._words.visible,
			"going back to the ark puts the camp's story away")
	check(not camp.get_node("CampSounds").is_playing(), "the camp's crickets and fire stop on the mountaintop")
	var ark_story_now: Node = ark_now.get_node("ChapterFour")
	check(ark_story_now.phase == ark_story_now.Phase.ARRIVE and "Long before David" in ark_story_now._line.text,
			"the ark starts again from its first line")
	print("ARK REVIEW %s" % ("PASSED" if failures == 0 else "FAILED"))
	quit(0 if failures == 0 else 1)


## Optional real-renderer captures: -- --capture-ark (omit --headless).
func capture(label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture-ark"):
		return
	await create_timer(2.7).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/ark-visual-review")
	root.get_texture().get_image().save_png("res://.godot/ark-visual-review/%s.png" % label)
