extends Node3D
## The people of Nineveh outside their city gate (Jonah 3): small family and market groups, real
## people who can listen and change, never a faceless crowd. They are the Blender paper people
## (story_person.gd), each tinted their own muted colours, and they move between a few poses as
## the story needs, each change a short cross-fade rather than a snap:
##   "busy"       going about the market, turned this way and that;
##   "listening"  turned towards Jonah, still;
##   "sorry"      facing Jonah, most of them down on their knees, heads bowed (they turned from
##                the wrong they did, Jonah 3:5-8).
## Seen from a respectful distance; they have no lines of their own (Wonder Light tells what
## they did).

const StoryPerson := preload("res://scripts/story_person.gd")

## How long a change of pose takes.
const POSE_SECONDS := 0.55
## who, where (local), which way they face when busy (radians), height, and colours.
const PEOPLE := [
	{"who": "brother", "at": Vector3(0.0, 0.0, 0.0), "turn": 2.4, "height": 1.0,
			"tint": {"Tunic": Color(0.56, 0.4, 0.46), "UnderTunic": Color(0.8, 0.74, 0.62), "Sash": Color(0.4, 0.5, 0.62), "Hair": Color(0.2, 0.13, 0.08)}},
	{"who": "wife", "at": Vector3(0.8, 0.0, 0.5), "turn": -2.0, "height": 1.0,
			"tint": {"Tunic": Color(0.72, 0.8, 0.9)}},
	{"who": "brother_young", "at": Vector3(0.5, 0.0, 1.3), "turn": 0.4, "height": 0.72,
			"tint": {"Tunic": Color(0.86, 0.66, 0.44), "UnderTunic": Color(0.9, 0.84, 0.72), "Sash": Color(0.5, 0.3, 0.26), "Hair": Color(0.18, 0.12, 0.08)}},
	{"who": "brother_young", "at": Vector3(-2.6, 0.0, -2.4), "turn": 1.2, "height": 0.98,
			"tint": {"Tunic": Color(0.44, 0.52, 0.6), "UnderTunic": Color(0.78, 0.72, 0.6), "Sash": Color(0.66, 0.46, 0.3), "Hair": Color(0.14, 0.1, 0.06)}},
	{"who": "wife", "at": Vector3(-1.9, 0.0, -3.1), "turn": -0.6, "height": 0.97,
			"tint": {"Tunic": Color(0.92, 0.76, 0.72)}},
	{"who": "brother", "at": Vector3(-0.4, 0.0, 3.4), "turn": 3.0, "height": 1.03,
			"tint": {"Tunic": Color(0.6, 0.54, 0.38), "UnderTunic": Color(0.72, 0.66, 0.54), "Sash": Color(0.3, 0.36, 0.5), "Hair": Color(0.3, 0.26, 0.22)}},
	{"who": "brother_young", "at": Vector3(0.6, 0.0, 3.9), "turn": -2.6, "height": 0.7,
			"tint": {"Tunic": Color(0.62, 0.72, 0.56), "UnderTunic": Color(0.86, 0.82, 0.7), "Sash": Color(0.72, 0.5, 0.34), "Hair": Color(0.2, 0.14, 0.09)}},
	{"who": "wife", "at": Vector3(1.5, 0.0, -1.5), "turn": 1.8, "height": 0.99,
			"tint": {"Tunic": Color(0.84, 0.82, 0.66)}},
]

var pose: String = "busy"
var _people: Array[Node3D] = []
var _toward: Vector3 = Vector3.ZERO
var _tween: Tween


func _ready() -> void:
	for i in PEOPLE.size():
		var spec: Dictionary = PEOPLE[i]
		var person := Node3D.new()
		person.name = "Townsperson%d" % i
		person.set_script(StoryPerson)
		person.who = spec["who"]
		add_child(person)
		person.position = spec["at"]
		person.rotation.y = spec["turn"]
		person.scale = Vector3.ONE * float(spec["height"])
		person.tint(spec["tint"])
		_people.append(person)


func people() -> Array[Node3D]:
	return _people


## Moves everyone to pose `to` ("busy", "listening" or "sorry"), facing `toward` (a world point:
## where Jonah stands) for the last two, over POSE_SECONDS (0 for at once).
func set_pose(to: String, toward: Vector3, seconds: float = POSE_SECONDS) -> void:
	pose = to
	_toward = toward
	if _tween:
		_tween.kill()
	_tween = null
	if seconds > 0.0:
		_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in _people.size():
		var person := _people[i]
		var spec: Dictionary = PEOPLE[i]
		var turn: float = spec["turn"]
		var kneel := 0.0
		if to != "busy":
			var to_jonah := toward - person.global_position
			turn = atan2(-to_jonah.x, -to_jonah.z)
			# The grown-ups kneel; the children stand close by, heads bowed with them.
			kneel = 1.0 if to == "sorry" and float(spec["height"]) > 0.9 and i % 3 != 2 else 0.0
		var target := person.rotation.y + wrapf(turn - person.rotation.y, -PI, PI)
		if seconds <= 0.0:
			person.rotation.y = target
			person.kneel = kneel
			continue
		_tween.tween_property(person, "rotation:y", target, seconds)
		_tween.tween_property(person, "kneel", kneel, seconds)
		_tween.tween_property(person, "look_aside", -0.25 if to == "sorry" and kneel == 0.0 else 0.0, seconds)
