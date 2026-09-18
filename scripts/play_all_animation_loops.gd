extends Node3D
## Autoplays every AnimationPlayer clip under this node on loop.
## Fans out multi-clip players so stream / foam / fish STEP loops run together.
## Keeps held STEP keys (no runtime stripping). Import Optimizer should stay off
## via .import: animation/remove_immutable_tracks=false + animation/fps=12.

func _ready() -> void:
	# Defer one frame so imported GLB children exist.
	call_deferred("_boot")


func _boot() -> void:
	var players: Array[AnimationPlayer] = []
	_collect_players(self, players)
	for player in players:
		_play_all_clips(player)


func _collect_players(node: Node, out: Array[AnimationPlayer]) -> void:
	if node is AnimationPlayer:
		out.append(node as AnimationPlayer)
	for child in node.get_children():
		_collect_players(child, out)


func _play_all_clips(player: AnimationPlayer) -> void:
	var names := player.get_animation_list()
	if names.is_empty():
		return
	for anim_name in names:
		var anim := player.get_animation(anim_name)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
	if names.size() == 1:
		player.play(names[0])
		return
	# Share libraries onto sibling players so every clip runs at once.
	var host := player.get_parent()
	if host == null:
		player.play(names[0])
		return
	var libraries := player.get_animation_library_list()
	for anim_name in names:
		var clone := AnimationPlayer.new()
		clone.name = "Loop_%s" % _safe(String(anim_name))
		host.add_child(clone)
		for lib_name in libraries:
			var src_lib := player.get_animation_library(lib_name)
			if src_lib == null:
				continue
			var new_lib := AnimationLibrary.new()
			if src_lib.has_animation(anim_name):
				var a := src_lib.get_animation(anim_name)
				if a:
					a.loop_mode = Animation.LOOP_LINEAR
					new_lib.add_animation(anim_name, a)
			clone.add_animation_library(lib_name, new_lib)
		clone.play(anim_name)
	# Silence the original so we don't double-play the first clip.
	player.stop()
	player.active = false


func _safe(text: String) -> String:
	return text.validate_node_name()
