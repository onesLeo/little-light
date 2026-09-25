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
const VERSE_SAMUEL_18_1 := "samuel_18_1"
const VERSE_GENESIS_9_13 := "genesis_9_13"
const CHARM_COURAGE := "courage"
const CHARM_FRIENDSHIP := "friendship"
const CHARM_TRUST := "trust"

## Charm slots shown as a dashed "?" after the earned charms, for adventures still to come.
## Chapter 3's charm is not on this branch, so two slots stay open for The Beginning and Jonah.
const MYSTERY_SLOTS := 2

const VERSES := [
	{
		"id": VERSE_JOSHUA_1_9,
		"ref": "Joshua 1:9",
		"spoken_ref": "Joshua, chapter one, verse nine.",
		"text": "Haven't I commanded you? Be strong and of good courage; don't be afraid, neither be dismayed: for Yahweh your God is with you wherever you go.",
		"why": "The same God who was with Joshua was with David — the Lord who kept him safe from the lion and the bear. That is why this verse lives here.",
	},
	{
		"id": VERSE_SAMUEL_18_1,
		"ref": "1 Samuel 18:1",
		"spoken_ref": "First Samuel, chapter eighteen, verse one.",
		"text": "The soul of Jonathan was knit with the soul of David, and Jonathan loved him as his own soul.",
		"why": "After the valley, Jonathan gave David what was his. A friend can do that.",
	},
	{
		"id": VERSE_GENESIS_9_13,
		"ref": "Genesis 9:13",
		"spoken_ref": "Genesis, chapter nine, verse thirteen.",
		"text": "I set my rainbow in the cloud, and it will be a sign of a covenant between me and the earth.",
		"why": "The rainbow is the sign of God's covenant, a promise God chooses to keep. It is not a prize Noah earned.",
	},
]

const CHARMS := [
	{
		"id": CHARM_COURAGE,
		"name": "Courage",
		"reason": "For staying with David, and breathing God's promise with him.",
		"spoken": "A Courage charm — for staying with David, and breathing God's promise with him.",
		"color": Color(0.95, 0.78, 0.35),
	},
	{
		"id": CHARM_FRIENDSHIP,
		"name": "Friendship",
		"reason": "For Jonathan giving David what was his.",
		"spoken": "A Friendship charm, for Jonathan giving David what was his.",
		"color": Color(0.55, 0.22, 0.28),
	},
	{
		"id": CHARM_TRUST,
		"name": "Trust",
		"reason": "Noah kept building before he could see the rain.",
		"spoken": "A Trust charm. Noah kept building before he could see the rain.",
		"color": Color(0.4, 0.66, 0.92),
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
