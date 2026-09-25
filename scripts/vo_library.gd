extends RefCounted
## Recorded voice-over for what is spoken by its words, keyed by the exact text
## that is read aloud (speaker name and quotation marks removed): the verses and
## charms the journal reads, the Faith Journey map, "Who is playing?", the word
## chips and the edge nudges. A story's own lines carry their clips with them
## (assets/dialogue/, dialogue_line.gd). Each clip lives at
## res://assets/audio/vo/<id>.wav. A line with no clip, or whose file is missing,
## falls back to the system text-to-speech voice.
##
## Wonder Light is voiced by "Juno" and David by "Bram" (see docs/voice-over.md).

const DIR := "res://assets/audio/vo/"

## text -> clip id
const LINES := {
	# Chapter 1, the valley: its story lines are in assets/dialogue/bethlehem_valley.tres. These are
	# spoken by their words: the verse and charm the journal reads too, the word chips, and the
	# nudges at the edge of the play area (play_bounds.gd).
	"Joshua, chapter one, verse nine.": "wl_verse_ref",
	"Haven't I commanded you? Be strong and of good courage; don't be afraid, neither be dismayed: for Yahweh your God is with you wherever you go.": "wl_verse",
	"Don't.": "wl_word_dont",
	"Be.": "wl_word_be",
	"Afraid.": "wl_word_afraid",
	"A Courage charm — for staying with David, and breathing God's promise with him.": "wl_charm",
	"That's the edge of our little valley. Let's stay close!": "wl_edge_a",
	"There's so much to find right here. Let's turn back!": "wl_edge_b",
	# "Who is playing?" (profile_screen.gd).
	"Who is playing? Tap your picture.": "wl_who_playing",
	"What is your name? Type it, pick a picture, and tell me how old you are.": "wl_your_name",
	# Chapter 2, The King's Camp: its story lines are in assets/dialogue/kings_camp.tres. These are
	# spoken by their words: the word chips, and the verse and charm the journal reads too.
	"Knit.": "jn_word_knit",
	"Loved.": "jn_word_loved",
	"Friend.": "jn_word_friend",
	"First Samuel, chapter eighteen, verse one.": "jn_verse_ref",
	"The soul of Jonathan was knit with the soul of David, and Jonathan loved him as his own soul.": "jn_verse",
	"A Friendship charm, for Jonathan giving David what was his.": "jn_charm",
	# The Faith Journey map (faith_journey_screen.gd). The child's name is shown, not spoken.
	"One story at a time.": "wl_map_open",
	"Hello!": "wl_hello",
	"Your journey starts in the valley.": "wl_map_valley",
	"The King's Camp is next.": "wl_map_camp",
	"Tap a story to begin.": "wl_map_any",
	"Finish Chapter 1, The valley, first. Then The King's Camp will open for you.": "wl_locked_camp",
	"This part of the path is still ahead. New stories will be waiting here.": "wl_path_ahead",
	"Noah's Ark is next.": "ark_map",
	"Finish Chapter 2, The King's Camp, first. Then Noah's Ark will open for you.": "ark_locked",
	# Chapter 4, Noah's Ark: its story lines are in assets/dialogue/noahs_ark.tres (Wonder Light in
	# Juno, Noah in Arthur, his wife in Helena; docs/voice-over.md). These are spoken by their words:
	# the word chips, and the verse and charm the journal reads too.
	"Genesis, chapter nine, verse thirteen.": "ark_verse_ref",
	"I set my rainbow in the cloud, and it will be a sign of a covenant between me and the earth.": "ark_verse",
	"Rainbow.": "ark_word_rainbow",
	"Sign.": "ark_word_sign",
	"Promise.": "ark_word_promise",
	"A Trust charm. Noah kept building before he could see the rain.": "ark_charm",
}

static var _cache: Dictionary = {}


## The clip for a line of spoken text, or null when there is none.
static func clip_for(text: String) -> AudioStream:
	var id: String = LINES.get(text, "")
	if id.is_empty():
		return null
	if _cache.has(id):
		return _cache[id]
	var path := DIR + id + ".wav"
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	_cache[id] = stream
	return stream


## True when at least one recorded clip is in the project.
static func has_any() -> bool:
	for text in LINES:
		if clip_for(text) != null:
			return true
	return false
