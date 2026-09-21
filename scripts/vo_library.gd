extends RefCounted
## Recorded voice-over for every spoken line, keyed by the exact text that is
## read aloud (speaker name and quotation marks removed). Each clip lives at
## res://assets/audio/vo/<id>.wav. A line with no entry, or whose file is
## missing, falls back to the system text-to-speech voice.
##
## Wonder Light is voiced by "Juno" and David by "Bram" (see docs/voice-over.md).

const DIR := "res://assets/audio/vo/"

## text -> clip id
const LINES := {
	"Ooh, look at that! A little valley, all made of paper and light.": "wl_arrive",
	"Three Wonder Items are hidden on the hillside. Find them!": "wl_explore",
	"Oh! Hello there. Are you lost too?": "dv_hello",
	"Everyone's scared of the big giant. But someone has to be brave.": "dv_giant",
	"David is scared too. But he's still going to try.": "wl_david_scared",
	"Thanks. Will you stay close while I get ready?": "dv_stay_close",
	"Let's help David get calm and steady. Breathe in... and out.": "wl_steady_intro",
	"In... and out. Just like counting sheep.": "dv_in_and_out",
	"Breathe with David...": "wl_breathe",
	"I feel steady now. Thank you for staying with me.": "dv_steady_now",
	"David walked out to the valley. And when it was over, the whole camp was cheering his name.": "wl_resolution",
	"Being brave doesn't mean you're not scared. It means you go anyway.": "wl_reflect",
	"Joshua, chapter one, verse nine.": "wl_verse_ref",
	"Haven't I commanded you? Be strong and of good courage; don't be afraid, neither be dismayed: for Yahweh your God is with you wherever you go.": "wl_verse",
	"This verse has three special words. Can you say them with me?": "wl_three_words",
	"Don't. Be. Afraid.": "wl_dont_be_afraid",
	"A Courage charm — for staying with David when he was scared.": "wl_charm",
	"Keep this close. Courage is yours to carry.": "wl_keep_close",
	"That's the edge of our little valley. Let's stay close!": "wl_edge_a",
	"There's so much to find right here. Let's turn back!": "wl_edge_b",
	"A stone, just right for a sling.": "wl_item_stone",
	"Worn smooth from long days watching sheep.": "wl_item_staff",
	"Baa! This little one wandered off again.": "wl_item_lamb",
	"Who is playing? Tap your picture.": "wl_who_playing",
	"What is your name? Type it, then pick a picture.": "wl_your_name",
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
