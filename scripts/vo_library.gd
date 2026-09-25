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
	# Chapter 4: Wonder Light in Juno, Noah in Arthur, his wife in Helena (docs/voice-over.md).
	"Long before David, God asked Noah to trust him and build something no one had seen before.": "ark_arrive",
	"People were hurting one another, and the world was full of violence.": "ark_hurt",
	"Find the mallet, the rope, and the jar of pitch. Bring them to Noah.": "ark_find",
	"A wooden mallet. Noah builds with it.": "ark_mallet",
	"A coil of rope. It holds the ark together.": "ark_rope",
	"A jar of sticky pitch. It keeps water out.": "ark_pitch",
	"God told me to build this ark. I cannot see the rain yet, but I trust him.": "ark_noah",
	"Let's finish this panel. Three pegs, then draw the rope tight.": "ark_panel",
	"Two by two, they're coming. Help these animals find their partners.": "ark_pairs",
	"This way. Walk together up the wide ramp.": "ark_wife",
	"This friend is looking for its match.": "ark_match",
	"Noah's family and the animals are safely inside. God closes the door and keeps them safe.": "ark_door",
	"The water covered the land. God kept Noah's family, and the animals with them, safe inside.": "ark_rain",
	"Let's open the window and send the dove.": "ark_send",
	"The dove came back safe. The water is still too high.": "ark_dove_back",
	"Look, an olive leaf. The water is going down.": "ark_leaf",
	"Dry ground. Thank you for keeping us safe.": "ark_dry",
	"Genesis, chapter nine, verse thirteen.": "ark_verse_ref",
	"I set my rainbow in the cloud, and it will be a sign of a covenant between me and the earth.": "ark_verse",
	"God's covenant is a promise God chooses to keep.": "ark_covenant",
	"Rainbow.": "ark_word_rainbow",
	"Sign.": "ark_word_sign",
	"Promise.": "ark_word_promise",
	"A Trust charm. Noah kept building before he could see the rain.": "ark_charm",
	"Keep it close. Trust God, even before you see the way through.": "ark_keep",
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
