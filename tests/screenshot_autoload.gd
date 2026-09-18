extends Node
## Debug-only: saves the real Forward+ frame to /tmp/godot_screenshot.png.
## SHOT_FRAME / HIDE_NODE / CAM_POS / CAM_LOOK tweak the capture.
var _frames := 0
func _ready() -> void:
	var hide := OS.get_environment("HIDE_NODE")
	if hide != "":
		var n := get_tree().root.get_node_or_null("Main/" + hide)
		if n is Node3D:
			(n as Node3D).visible = false
	var cp := OS.get_environment("CAM_POS")
	if cp != "":
		var cam := get_tree().root.get_node_or_null("Main/TabletopCamera") as Camera3D
		if cam:
			cam.set_script(null)
			var p := cp.split(",")
			cam.global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
			var cl := OS.get_environment("CAM_LOOK")
			if cl != "":
				var q := cl.split(",")
				cam.look_at(Vector3(float(q[0]), float(q[1]), float(q[2])), Vector3.UP)
			cam.current = true
func _process(_delta: float) -> void:
	_frames += 1
	var shot := int(OS.get_environment("SHOT_FRAME")) if OS.get_environment("SHOT_FRAME") != "" else 90
	if _frames == shot:
		get_viewport().get_texture().get_image().save_png("/tmp/godot_screenshot.png")
		print("SCREENSHOT SAVED")
	if _frames == shot + 5:
		get_tree().quit()
