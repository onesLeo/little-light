extends RefCounted
## The story in easier words, for younger readers. When "Easy words" is on for the child playing
## (asked when a child is made: "How old are you?", and changeable in the pause menu), each line below is
## shown and read aloud in its simpler version. Every other line, and the Joshua 1:9 verse, stays exactly as
## it is. A child of 9 or more gets the original story.
## Use through a preload constant (no class_name):
##   const EasyWords := preload("res://scripts/easy_words.gd")
##
## Each easy line needs a recorded clip (vo_library.gd, ids starting "ez_"); the smoke test checks that, and
## that every original line still exists in chapter_director.gd or chapter_two.gd, so an edit there cannot
## silently break this.

## original line -> easier line (the text spoken, without the speaker's name or quote marks)
const LINES := {
	"This is David's valley. He looks after sheep. God looks after him.": "This is David's valley. God looks after him.",
	"David needs his stone, his staff, and his little lamb. Find them for him!": "Find David's stone, staff, and little lamb.",
	"Everyone's scared of the big giant. But God gave me these sheep to keep safe.": "Everyone is afraid of the big giant. God gave me these sheep to keep safe.",
	"The Lord kept me safe from the lion and the bear. He will keep me safe now.": "God kept me safe before. He will keep me safe now.",
	"God gave David a job: keep the sheep safe. That's why he will go.": "God gave David a job: keep the sheep safe.",
	"Let's breathe God's promise with David. In: God is with you. Out: don't be afraid.": "Let's breathe God's words with David. In... God is with you. Out... do not be afraid.",
	"I still feel small. But I'm not alone. Thank you for staying.": "I am still small. But I am not alone.",
	"David walked out to the valley. When it was over, the camp cheered his name.": "David walked out to the valley. Then everyone cheered.",
	"Being brave doesn't mean you're not scared. It means you go with God anyway.": "Being brave does not mean you are never scared. It means you go with God.",
	"God had a job for David. He has one for you too. Stay close, and remember the words.": "God had a job for David. He has one for you too. Stay close.",
	"Keep this close. Courage is yours to carry.": "Keep it close. Courage is yours.",
	"A shepherd's staff. David stays with his sheep.": "David's staff. He stays with his sheep.",
	# Chapter 2, The King's Camp (chapter_two.gd). Jonathan's two lines are in his voice.
	"This is the king's camp. The day is turning into night.": "This is the king's camp. It is almost night.",
	"I am Jonathan. David was brave today, because God was with him.": "I am Jonathan. God was with David today.",
	"Find Jonathan's robe, his bow, and his belt. They are gifts for David.": "Find the robe, the bow, and the belt. They are gifts for David.",
	"A folded robe. Jonathan is giving it to David.": "A robe. It is a gift for David.",
	"A bow with no arrow. It is a gift, not a fight.": "A bow. It is a gift, not for fighting.",
	"A belt with one gold square. A friend shares what he has.": "A belt. Friends share what they have.",
	"These were mine. I give them to David, because he is my friend.": "These were mine. Now they are David's. He is my friend.",
	"Hold still, and loop the cord. Three slow loops.": "Loop the cord. Three slow loops.",
	"A Friendship charm, for Jonathan giving David what was his.": "A Friendship charm, because Jonathan gave to his friend.",
}


## `text` with every line that has an easier version swapped for it. Works on a whole block of
## dialogue (several lines, speaker names and all), because it replaces only the lines themselves.
static func apply(text: String) -> String:
	for original in LINES:
		text = text.replace(original, LINES[original])
	return text
