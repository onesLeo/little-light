extends Resource
## A story's lines (dialogue_line.gd), looked up by id: one .tres per story in assets/dialogue/,
## edited in the inspector. The story shows a few of them together on the dialogue bar, and
## the voice reads them with their own clips (block()).
## Use through a preload constant (no class_name):
##   const CampLines := preload("res://assets/dialogue/kings_camp.tres")
##   var said: Dictionary = CampLines.block([&"arrive"], GameSettings.easy_words)

## DialogueLine resources (dialogue_line.gd).
@export var lines: Array[Resource] = []

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


## The lines `ids`, one to a row, as the dialogue bar shows them ("text"), and the ones read
## aloud with their clips ("spoken", for audio_director.gd speak_lines). A missing id shows as
## [missing line: id], so a test that reads the bar notices it.
func block(ids: Array, easy: bool) -> Dictionary:
	var shown := PackedStringArray()
	var spoken: Array[Dictionary] = []
	for id in ids:
		var l := line(id)
		if l == null:
			shown.append("[missing line: %s]" % id)
			continue
		shown.append(l.shown(easy))
		if l.is_spoken():
			spoken.append(l.spoken(easy))
	return {"text": "\n".join(shown), "spoken": spoken}
