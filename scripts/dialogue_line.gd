extends Resource
## One line of a story: who says it, the words, and its recorded clip, with an easier version
## for younger readers ("Easy words"). A story asks for its lines by id (dialogue_lines.gd),
## so rewording a line can never cut it off from its clip or its easier version.
## Use through a preload constant (no class_name):
##   const DialogueLine := preload("res://scripts/dialogue_line.gd")

@export var id: StringName = &""
## "Wonder Light", "David", "Jonathan", "Noah" or "Noah's wife". Empty for a stage direction,
## which is shown in brackets and never read aloud.
@export var speaker: String = ""
## The words alone, without the speaker's name or quote marks.
@export_multiline var text: String = ""
@export var clip: AudioStream

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
