extends Node
## Animate David's fused model and its outline together; his lamb stays planted.
const CharacterMotion := preload("res://scripts/chapter_two_character_motion.gd")
var _time: float = 0.0
var _parts: Array[Node3D] = []
var _rest: Array[Transform3D] = []

func _ready() -> void:
	for part in get_parent().find_children("David_Mentor*", "MeshInstance3D", true, false):
		_parts.append(part)
		_rest.append(part.transform)

func _process(delta: float) -> void:
	_time += delta
	var main := get_parent().get_parent()
	var jon := main.get_node_or_null("KingsCamp/Jonathan")
	var story := main.get_node_or_null("KingsCamp/ChapterTwo")
	if jon == null or story == null or story.phase == story.Phase.IDLE:
		return
	var audio: Node = main.get_node("AudioDirector")
	var listening: bool = jon.speaking and audio.is_speaking()
	var nod := CharacterMotion.listening_nod(_time) * (0.026 if listening else 0.006)
	var breath := CharacterMotion.breath(_time)
	var basis := Basis.from_euler(Vector3(nod, sin(_time * 0.72) * 0.018, breath * 0.007))
	var pivot := Vector3(0, 0.55, 0)
	for i in _parts.size():
		_parts[i].transform = Transform3D(basis, pivot - basis * pivot + Vector3(0, breath * 0.004, 0)) * _rest[i]
