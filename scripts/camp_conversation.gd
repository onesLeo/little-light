extends Node
## Animate David's fused model and its outline together; his lamb stays planted.
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
	var listening: bool = jon.speaking and main.get_node("AudioDirector").is_speaking()
	var nod := maxf(sin(_time * 2.5), 0.0) * (0.035 if listening else 0.012)
	var basis := Basis.from_euler(Vector3(nod, sin(_time * 0.8) * 0.025, sin(_time * 1.1) * 0.012))
	var pivot := Vector3(0, 0.55, 0)
	for i in _parts.size():
		_parts[i].transform = Transform3D(basis, pivot - basis * pivot + Vector3(0, sin(_time * 1.8) * 0.003, 0)) * _rest[i]
