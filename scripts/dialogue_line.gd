extends Resource
## One line of a story: who says it, the words, and its recorded clip, with an easier version
## for younger readers ("Easy words"). A story asks for its lines by id (dialogue_lines.gd),
## so rewording a line can never cut it off from its clip or its easier version.
## Use through a preload constant (no class_name):
##   const DialogueLine := preload("res://scripts/dialogue_line.gd")

const JournalContent := preload("res://scripts/journal_content.gd")
## Who can speak, as the dialogue bar writes them ("Noah's wife" before "Noah").
const SPEAKERS := ["Wonder Light", "David", "Jonathan", "Samuel", "Jesse", "Noah's wife", "Noah", "Jonah", "Captain"]

@export var id: StringName = &""
## One of SPEAKERS ("Wonder Light", "David", "Samuel", ...). Empty for a stage direction,
## which is shown in brackets and never read aloud.
@export var speaker: String = ""
## The words alone, without the speaker's name or quote marks.
@export_multiline var text: String = ""
@export var clip: AudioStream
## Carries on the line before it, inside the same quote marks, on a row of its own (the
## three words after Joshua 1:9). Only for the same speaker.
@export var same_quote: bool = false

@export_group("Easy words")
## The easier version, for a child who has Easy words on. Empty: the line stays as it is.
@export_multiline var easy_text: String = ""
@export var easy_clip: AudioStream


func has_easy() -> bool:
	return not easy_text.is_empty()


## The words for a child with Easy words on (`easy`) or off.
func words(easy: bool) -> String:
	return easy_text if easy and has_easy() else text


## As the dialogue bar shows it: `Speaker: "words"`, or `(words)` for a stage direction.
func shown(easy: bool) -> String:
	if speaker.is_empty():
		return "(%s)" % words(easy)
	return "%s: \"%s\"" % [speaker, words(easy)]


func is_spoken() -> bool:
	return not speaker.is_empty()


## As the voice reads it (audio_director.gd speak_lines): who, the words, and the clip.
func spoken(easy: bool) -> Dictionary:
	return {"speaker": speaker, "text": words(easy), "clip": easy_clip if easy and has_easy() else clip}


## Dialogue written as text (a verse, a nudge, a map line) split into the lines the voice
## reads: {"speaker", "text"}, with no clip, so each is found by its words (vo_library.gd).
## A row with no speaker of its own (the verse itself) keeps the one before; a verse's
## reference ("Joshua 1:9 (WEB):") is read the way the journal reads it; "(...)" rows are silent.
static func spoken_in(block: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var speaker := "Reader"
	for raw in block.split("\n", false):
		var line := raw.strip_edges()
		if line.is_empty() or line.begins_with("("):
			continue
		for who in SPEAKERS:
			if line.begins_with(who + ":"):
				line = line.substr(who.length() + 1)
				speaker = who
				break
		for verse in JournalContent.VERSES:
			if line.begins_with(verse["ref"]):
				line = verse["spoken_ref"]
				speaker = "Reader"
				break
		line = line.replace("\"", "").strip_edges()
		if not line.is_empty():
			out.append({"speaker": speaker, "text": line})
	return out
