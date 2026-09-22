extends RefCounted
## The story in easier words, for younger readers. When "Easy words" is on for the child playing
## (asked when a child is made: "How old are you?", and changeable in the pause menu), each line below is
## shown and read aloud in its simpler version. Every other line, and the Joshua 1:9 verse, stays exactly as
## it is. A child of 9 or more gets the original story.
## Use through a preload constant (no class_name):
##   const EasyWords := preload("res://scripts/easy_words.gd")
##
## Each easy line needs a recorded clip (vo_library.gd, ids starting "ez_"); the smoke test checks that, and
## that every original line still exists in chapter_director.gd, so an edit there cannot silently break this.

## original line -> easier line (the text spoken, without the speaker's name or quote marks)
const LINES := {
	"Ooh, look at that! A little valley, all made of paper and light.": "Wow! A little valley made of paper and light.",
	"Three Wonder Items are hidden on the hillside. Find them!": "Three Wonder Items are hiding on the hill. Find them!",
	"Everyone's scared of the big giant. But someone has to be brave.": "Everyone is afraid of the big giant. But someone must be brave.",
	"David is scared too. But he's still going to try.": "David is scared too. But he will try anyway.",
	"Let's help David get calm and steady. Breathe in... and out.": "Let's help David feel calm. Breathe in... and out.",
	"I feel steady now. Thank you for staying with me.": "I feel calm now. Thank you for staying with me.",
	"David walked out to the valley. And when it was over, the whole camp was cheering his name.": "David walked out to the valley. When it was over, everyone in the camp cheered for him.",
	"Being brave doesn't mean you're not scared. It means you go anyway.": "Being brave does not mean you are never scared. It means you keep going.",
	"Keep this close. Courage is yours to carry.": "Keep it close. Courage is yours.",
	"Worn smooth from long days watching sheep.": "Rubbed smooth from many days watching sheep.",
}


## `text` with every line that has an easier version swapped for it. Works on a whole block of
## dialogue (several lines, speaker names and all), because it replaces only the lines themselves.
static func apply(text: String) -> String:
	for original in LINES:
		text = text.replace(original, LINES[original])
	return text
