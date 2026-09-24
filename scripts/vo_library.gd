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
	"This is David's valley. He looks after sheep. God looks after him.": "wl_arrive",
	"David needs his stone, his staff, and his little lamb. Find them for him!": "wl_explore",
	"Oh! Hello there. Are you lost too?": "dv_hello",
	"Everyone's scared of the big giant. But God gave me these sheep to keep safe.": "dv_giant",
	"The Lord kept me safe from the lion and the bear. He will keep me safe now.": "dv_lion_bear",
	"God gave David a job: keep the sheep safe. That's why he will go.": "wl_david_scared",
	"Thanks. Will you stay close while I get ready?": "dv_stay_close",
	"Let's breathe God's promise with David. In: God is with you. Out: don't be afraid.": "wl_steady_intro",
	"In... and out. Just like counting sheep.": "dv_in_and_out",
	"Breathe with David...": "wl_breathe",
	"I still feel small. But I'm not alone. Thank you for staying.": "dv_steady_now",
	"David took the small stone. God can use even a small thing.": "wl_took_stone",
	"David walked out to the valley. When it was over, the camp cheered his name.": "wl_resolution",
	"David trusted God, faced Goliath with his sling, and defeated him. The people were safe.": "wl_resolution_clear",
	"Being brave doesn't mean you're not scared. It means you go with God anyway.": "wl_reflect",
	"God had a job for David. He has one for you too. Stay close, and remember the words.": "wl_purpose",
	"Joshua, chapter one, verse nine.": "wl_verse_ref",
	"Haven't I commanded you? Be strong and of good courage; don't be afraid, neither be dismayed: for Yahweh your God is with you wherever you go.": "wl_verse",
	"This verse has three special words. Can you say them with me?": "wl_three_words",
	"Don't. Be. Afraid.": "wl_dont_be_afraid",
	"Don't.": "wl_word_dont",
	"Be.": "wl_word_be",
	"Afraid.": "wl_word_afraid",
	"Yahweh is God's name. It means He is with you.": "wl_yahweh",
	"A Courage charm — for staying with David, and breathing God's promise with him.": "wl_charm",
	"Keep this close. Courage is yours to carry.": "wl_keep_close",
	"God was with David. God is with you.": "wl_complete",
	"That's the edge of our little valley. Let's stay close!": "wl_edge_a",
	"There's so much to find right here. Let's turn back!": "wl_edge_b",
	"A small stone. God can use even a small thing.": "wl_item_stone",
	"A shepherd's staff. David stays with his sheep.": "wl_item_staff",
	"A lamb David is keeping safe. That is his job.": "wl_item_lamb",
	"Who is playing? Tap your picture.": "wl_who_playing",
	"What is your name? Type it, pick a picture, and tell me how old you are.": "wl_your_name",
	# The story in easier words (easy_words.gd), for a child who said they are 8 or younger.
	"This is David's valley. God looks after him.": "ez_arrive",
	"Find David's stone, staff, and little lamb.": "ez_explore",
	"Everyone is afraid of the big giant. God gave me these sheep to keep safe.": "ez_giant",
	"God kept me safe before. He will keep me safe now.": "ez_lion_bear",
	"God gave David a job: keep the sheep safe.": "ez_david_scared",
	"Let's breathe God's words with David. In... God is with you. Out... do not be afraid.": "ez_steady_intro",
	"I am still small. But I am not alone.": "ez_steady_now",
	"David walked out to the valley. Then everyone cheered.": "ez_resolution",
	"Being brave does not mean you are never scared. It means you go with God.": "ez_reflect",
	"God had a job for David. He has one for you too. Stay close.": "ez_purpose",
	"Keep it close. Courage is yours.": "ez_keep_close",
	"David's staff. He stays with his sheep.": "ez_item_staff",
	"This is the king's camp. The day is turning into night.": "jn_arrive",
	"I am Jonathan. David was brave today, because God was with him.": "jn_hello",
	"Find Jonathan's robe, his bow, and his belt. They are gifts for David.": "jn_find",
	"A folded robe. Jonathan is giving it to David.": "jn_robe",
	"A bow with no arrow. It is a gift, not a fight.": "jn_bow",
	"A belt with one gold square. A friend shares what he has.": "jn_belt",
	"These were mine. I give them to David, because he is my friend.": "jn_give",
	"Hold still, and loop the cord. Three slow loops.": "jn_cord",
	"Knit.": "jn_word_knit",
	"Loved.": "jn_word_loved",
	"Friend.": "jn_word_friend",
	"Friends stay tied together.": "jn_tied",
	"First Samuel, chapter eighteen, verse one.": "jn_verse_ref",
	"The soul of Jonathan was knit with the soul of David, and Jonathan loved him as his own soul.": "jn_verse",
	"A Friendship charm, for Jonathan giving David what was his.": "jn_charm",
	"Look. David's valley is still down there.": "jn_lookout",
	# Chapter 2 in easier words (easy_words.gd).
	"This is the king's camp. It is almost night.": "ez_jn_arrive",
	"I am Jonathan. God was with David today.": "ez_jn_hello",
	"Find the robe, the bow, and the belt. They are gifts for David.": "ez_jn_find",
	"A robe. It is a gift for David.": "ez_jn_robe",
	"A bow. It is a gift, not for fighting.": "ez_jn_bow",
	"A belt. Friends share what they have.": "ez_jn_belt",
	"These were mine. Now they are David's. He is my friend.": "ez_jn_give",
	"Loop the cord. Three slow loops.": "ez_jn_cord",
	"A Friendship charm, because Jonathan gave to his friend.": "ez_jn_charm",
	# The Faith Journey map (faith_journey_screen.gd). The child's name is shown, not spoken.
	"One story at a time.": "wl_map_open",
	"Hello!": "wl_hello",
	"Your journey starts in the valley.": "wl_map_valley",
	"The King's Camp is next.": "wl_map_camp",
	"Tap a story to begin.": "wl_map_any",
	"Finish Chapter 1, The valley, first. Then The King's Camp will open for you.": "wl_locked_camp",
	"This part of the path is still ahead. New stories will be waiting here.": "wl_path_ahead",
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
