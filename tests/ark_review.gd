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
	ark.visit()
	await settle()
	var story: Node = ark.get_node("ChapterFour")
	var player: Node3D = main.get_node("Player")
	check(ark.get_node("Noah").find_child("NoahBody", true, false) != null, "Noah in the scene is the designed model")
	check(ark.get_node("NoahsWife").find_child("NoahsWifeBody", true, false) != null, "his wife in the scene is her own model")
	check("Long before David" in story._line.text, "arrival names the long work")
	check(not player.can_move, "arrival holds still")
	check(not ark.get_node("Rain").visible, "the plain starts dry")
	story._advance()
	check("hurting one another" in story._line.text, "the brokenness is named once")
	story._advance()
	check(story.phase == story.Phase.FIND and player.can_move, "finding the tools unlocks walking")

	for tool_name in ["Mallet", "RopeCoil", "Pitch"]:
		player.global_position = ark.get_node(tool_name).global_position
		story._try_collect()
	check(story.phase == story.Phase.MEET and not ark.get_node("Pitch").visible, "three tools are brought to Noah")
	check("I trust him" in story._line.text, "Noah says he trusts before he sees the rain")
	story._advance()
	check(story.phase == story.Phase.PANEL, "the panel activity starts")

	player.global_position = ark.get_node("WorkPanel").global_position
	for _i in 3:
		story._place_peg()
	check(story._pegs == 3 and ark.get_node("WorkPanel/Peg2") != null, "three pegs land in the panel")
	story.add_rope(story.ROPE_STEP)
	story.add_rope(story.ROPE_STEP)
	check(story.phase == story.Phase.PAIRS and story._rope_steps == 2, "two rope pulls finish the panel")

	var sheep: Node3D = ark.get_node("SheepA")
	story._guide = "SheepA"
	sheep.global_position = ark.get_node("GoatB").global_position
	story._follow(0.05)
	check(story._mismatch_said and not bool(sheep.get_meta("aboard")), "a mismatch points to the real mate and boards nobody")
	sheep.global_position = ark.get_node("SheepB").global_position
	story._follow(0.05)
	check(story._matched == 1 and bool(sheep.get_meta("aboard")), "standing with the matching sheep boards the pair")
	story._guide = "DoveA"
	story._finish_guide()
	story._guide = "ElephantA"
	story._finish_guide()
	check(story._matched == 3 and ark.aboard_count() == 12, "three guided pairs and three montage pairs are aboard")
	check(ark.get_node("Noah").global_position.z < 5.0
			and player.global_position.distance_to(ark.get_node("Noah").global_position) > 3.0,
			"the guest stays outside while the family goes in")
	story._advance()
	check(ark.get_node("Rain").visible and "animals with them" in story._line.text, "rain stays on the ark and names who was kept safe")
	story._advance()
	story._send_dove()
	story._on_dove_back()
	check(story.phase == story.Phase.SKY and "came back safe" in story._line.text, "the first dove returns safe")
	story._turn_sky()
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
