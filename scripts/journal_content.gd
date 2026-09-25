extends RefCounted
## What the Faith Journal can hold. The story unlocks entries by id (see chapter_director.gd);
## the journal shows only what the current child has earned.
## Use through a preload constant (no class_name):
##   const JournalContent := preload("res://scripts/journal_content.gd")
##
## Everything here is read aloud with the recorded clips in vo_library.gd, so a new verse or charm
## needs its text (and its "spoken_ref" for a verse) recorded and listed there. The smoke test checks
## that every line below has a clip, except an entry marked "recorded": false, which the system voice
## reads until its chapter is cast (The Beginning, for now).

const VERSE_JOSHUA_1_9 := "joshua_1_9"
const VERSE_SAMUEL_18_1 := "samuel_18_1"
const VERSE_GENESIS_9_13 := "genesis_9_13"
const VERSE_SAMUEL_16_7 := "samuel_16_7"
const CHARM_COURAGE := "courage"
const CHARM_FRIENDSHIP := "friendship"
const CHARM_TRUST := "trust"
const CHARM_FAITHFUL_HEART := "faithful_heart"

## Charm slots shown as a dashed "?" after the earned charms, for adventures still to come.
## With The Beginning's Faithful Heart in, one slot stays open, for Jonah.
const MYSTERY_SLOTS := 1

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
	{
		"id": VERSE_SAMUEL_16_7,
		"ref": "1 Samuel 16:7",
		"spoken_ref": "First Samuel, chapter sixteen, verse seven.",
		# World English Bible Classic, verified in docs/chapter-3-concept.md.
		"text": "But Yahweh said to Samuel, ‘Don't look on his face, or on the height of his stature, because I have rejected him; for I don't see as man sees. For man looks at the outward appearance, but Yahweh looks at the heart.’",
		"why": "David was out caring for the sheep when Samuel came. People look at the outside first. God sees the heart.",
		"recorded": false,
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
	{
		"id": CHARM_FAITHFUL_HEART,
		"name": "Faithful Heart",
		"reason": "For caring well in quiet places.",
		"spoken": "A Faithful Heart charm, for caring well in quiet places.",
		"color": Color(0.9, 0.52, 0.42),
		"recorded": false,
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
## The verse as a story shows it on the dialogue bar: `Joshua 1:9 (WEB):` over the words in
## quote marks. The voice reads the reference the way the journal does (dialogue_line.gd).
static func verse_card(id: String) -> String:
	var v := verse(id)
	return "" if v.is_empty() else "%s (WEB):\n\"%s\"" % [v["ref"], v["text"]]


static func verse_dialogue(id: String) -> String:
	var v := verse(id)
	return "" if v.is_empty() else "%s\n%s" % [v["spoken_ref"], v["text"]]
