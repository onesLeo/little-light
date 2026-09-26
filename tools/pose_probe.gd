extends SceneTree
## Prints where the hands and head of a story person (story_person.gd) land in each feeling pose,
## in the model's own space (it faces -z): run it after changing ARM_* or FOREARM_*.
##   godot --headless --path . --script tools/pose_probe.gd
const StoryPerson := preload("res://scripts/story_person.gd")
func _initialize() -> void:
	_go.call_deferred()

func _go() -> void:
	await process_frame
	var p := Node3D.new()
	p.set_script(StoryPerson)
	p.who = "brother"
	root.add_child(p)
	await process_frame
	var sk := p.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var s := p.scale.x
	for mood in [{}, {"brace": 1.0}, {"plead": 1.0}, {"heart": 1.0}, {"slump": 1.0}]:
		for k in ["slump", "brace", "plead", "heart", "sway"]:
			p.set(k, float(mood.get(k, 0.0)))
		p._time = 0.0
		p._process(0.0)
		sk.force_update_all_bone_transforms()
		var chest := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Chest")).origin
		var head := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin
		var out := "%s chest y=%.2f head=(%.2f,%.2f,%.2f)" % [str(mood), chest.y, head.x, head.y, head.z]
		for side in ["L", "R"]:
			var fa := sk.get_bone_global_pose(sk.find_bone("LowerArm_" + side))
			var hand := sk.global_transform * (fa * Vector3(0, 0.2, 0))
			var elbow := sk.global_transform * fa.origin
			out += "  %s hand=(%.2f,%.2f,%.2f) elbow=(%.2f,%.2f,%.2f)" % [side, hand.x, hand.y, hand.z, elbow.x, elbow.y, elbow.z]
		print(out)
	quit()
