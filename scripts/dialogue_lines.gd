extends Resource
## A story's lines (dialogue_line.gd), looked up by id: one .tres per story in assets/dialogue/,
## edited in the inspector. The story shows a few of them together on the dialogue bar, and
## the voice reads them with their own clips (block()).
## Use through a preload constant (no class_name):
##   const CampLines := preload("res://assets/dialogue/kings_camp.tres")
##   var said: Dictionary = CampLines.block([&"arrive"], GameSettings.easy_words)

const DialogueLine := preload("res://scripts/dialogue_line.gd")

## DialogueLine resources (dialogue_line.gd).
@export var lines: Array[Resource] = []
## False while the story is not cast yet: its lines have no clips and the system voice reads
## them (docs/chapter-3-readiness.md). The smoke test then does not ask for clips.
@export var recorded: bool = true

var _by_id: Dictionary = {}


## The line called `id`, or null (with an error) when there is none.
func line(id: StringName) -> Resource:
	if _by_id.size() != lines.size():
		_by_id.clear()
		for l in lines:
			_by_id[l.id] = l
	if not _by_id.has(id):
		push_error("DialogueLines: no line called %s in %s" % [id, resource_path])
		return null
	return _by_id[id]


## `parts`, one to a row, as the dialogue bar shows them ("text"), and the lines read aloud
## ("spoken", for audio_director.gd speak_lines). A part is a line's id (a StringName, with
## its own clips), or text that is not the story's own, such as a verse from the journal
## (a String, shown as it is and read by its words). A missing id shows as [missing line: id],
## so a test that reads the bar notices it.
func block(parts: Array, easy: bool) -> Dictionary:
	var shown := PackedStringArray()
	var spoken: Array[Dictionary] = []
	var last: Resource = null
	for part in parts:
		if not part is StringName:
			shown.append(String(part))
			spoken.append_array(DialogueLine.spoken_in(String(part)))
			last = null
			continue
		var l := line(part)
		if l == null:
			shown.append("[missing line: %s]" % part)
			last = null
			continue
		if l.same_quote and last != null and last.speaker == l.speaker and not shown.is_empty():
			# Inside the quote marks of the line before, on a row of its own.
			shown[shown.size() - 1] = shown[shown.size() - 1].trim_suffix("\"") + "\n" + l.words(easy) + "\""
		else:
			shown.append(l.shown(easy))
		if l.is_spoken():
			spoken.append(l.spoken(easy))
		last = l
	return {"text": "\n".join(shown), "spoken": spoken}
