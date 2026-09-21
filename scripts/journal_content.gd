extends RefCounted
## What the Faith Journal can hold. The story unlocks entries by id (see chapter_director.gd);
## the journal shows only what the current child has earned.
## Use through a preload constant (no class_name):
##   const JournalContent := preload("res://scripts/journal_content.gd")
##
## Everything here is read aloud with the recorded clips in vo_library.gd, so a new verse or charm
## needs its text (and its "spoken_ref" for a verse) recorded and listed there first. The smoke
## test checks that every line below has a clip.

const VERSE_JOSHUA_1_9 := "joshua_1_9"
const CHARM_COURAGE := "courage"

## Charm slots shown as a dashed "?" after the earned charms, for adventures still to come.
const MYSTERY_SLOTS := 2

const VERSES := [
	{
		"id": VERSE_JOSHUA_1_9,
		"ref": "Joshua 1:9",
		"spoken_ref": "Joshua, chapter one, verse nine.",
		"text": "Haven't I commanded you? Be strong and of good courage; don't be afraid, neither be dismayed: for Yahweh your God is with you wherever you go.",
	},
]

const CHARMS := [
	{
		"id": CHARM_COURAGE,
		"name": "Courage",
		"reason": "For staying with David when he was scared.",
		"spoken": "A Courage charm — for staying with David when he was scared.",
		"color": Color(0.95, 0.78, 0.35),
	},
]


static func verse(id: String) -> Dictionary:
	for v in VERSES:
		if v["id"] == id:
			return v
	return {}


static func charm(id: String) -> Dictionary:
	for c in CHARMS:
		if c["id"] == id:
			return c
	return {}


## The text handed to AudioDirector.speak_dialogue for a verse: its reference, then the verse.
static func verse_dialogue(id: String) -> String:
	var v := verse(id)
	return "" if v.is_empty() else "%s\n%s" % [v["spoken_ref"], v["text"]]
