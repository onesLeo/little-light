extends SceneTree
## Headless pass through the Noah's Ark greybox.
const Profiles := preload("res://scripts/profiles.gd")
const Settings := preload("res://scripts/game_settings.gd")
const JournalContent := preload("res://scripts/journal_content.gd")

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
	ark.visit()
	await settle()
	var story: Node = ark.get_node("ChapterFour")
	var player: Node3D = main.get_node("Player")
	check(ark.get_node("Noah").find_child("NoahBody", true, false) != null, "Noah in the scene is the designed model")
	check(ark.get_node("NoahsWife").find_child("NoahsWifeBody", true, false) != null, "his wife in the scene is her own model")
	check(ark.get_node("Noah")._bones["Thigh_L"] >= 0 and ark.get_node("NoahsWife")._bones["Shin_R"] >= 0, "both parents have the leg bones used for boarding")
	check("Long before David" in story._line.text, "arrival names the long work")
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
	for tool_name in ["RopeCoil", "Pitch"]:
		player.global_position = ark.get_node(tool_name).global_position
		story._try_collect()
	check(story.phase == story.Phase.MEET and not ark.get_node("Pitch").visible, "three tools are brought to Noah")
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
	while ark.is_boarding() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not ark.is_boarding() and story.phase == story.Phase.DOOR, "door phase waits for the last family member")
	check(story._matched == 3 and ark.aboard_count() == 12, "all twelve animals have actually reached the entrance")
	check(not ark.get_node("Noah").visible and not ark.get_node("NoahsWife").visible, "both parents have entered before the door closes")
	check(ark.get_node("Door").visible and not ark.get_node("SheepA/Beacon").visible, "God closes the door, and the markers are put away")
	check(ark.get_node("Noah").global_position.z < 5.0
			and player.global_position.distance_to(ark.get_node("Noah").global_position) > 3.0,
			"the guest stays outside while the family goes in")
	story._advance()
	check(ark.get_node("Rain").visible and "animals with them" in story._line.text, "rain stays on the ark and names who was kept safe")
	await create_timer(0.3).timeout
	check(ark.get_node("Mountain/Flood").visible and not ark.get_node("Mountain/CloudSea").visible, "the water rises over the cloud sea while it rains")
	story._advance()
	story._send_dove()
	story._on_dove_back()
	check(story.phase == story.Phase.SKY and "came back safe" in story._line.text, "the first dove returns safe")
	var before: String = story._line.text
	story._turn_sky()
	check(story._line.text == before and "going down" in story._prompt.text, "the first turn of the sky lets the water go down without repeating the line")
	story._turn_sky()
	check(story.phase == story.Phase.LEAF, "turning the sky opens the second send")
	story._send_dove()
	story._on_dove_back()
	check(ark.get_node("WindowDove/Leaf").visible and ark.get_node("Rainbow").visible, "the olive leaf and the rainbow arrive together")
	story._advance()
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
	print("ARK REVIEW %s" % ("PASSED" if failures == 0 else "FAILED"))
	quit(0 if failures == 0 else 1)
