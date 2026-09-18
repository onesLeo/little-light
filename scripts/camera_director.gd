extends Node
## CameraDirector — the "second pair of eyes" behind the camera itself.
##
## Until now the game had exactly one viewpoint: the tabletop follow-cam.
## This adds a second Camera3D the ChapterDirector can cut to for a closer,
## more intimate framing during dialogue/story beats — the way the script
## doc explicitly calls for in Beat 5 ("the camera stays on David's
## determined face"). Cuts are hard cuts (no cross-fade blending — Godot
## doesn't compositing-blend two Camera3Ds for free, and a clean cut reads
## fine for this kid-friendly, storybook-page style of pacing).

@export var tabletop_camera_path: NodePath = ^"../TabletopCamera"
@export var closeup_camera_path: NodePath = ^"../CloseUpCamera"
@export var closeup_look_height: float = 0.6

var _tabletop: Camera3D
var _closeup: Camera3D

func _ready() -> void:
	_tabletop = get_node_or_null(tabletop_camera_path) as Camera3D
	_closeup = get_node_or_null(closeup_camera_path) as Camera3D

## Wide tabletop establishing shot — used for exploration and any beat that
## isn't a face-to-face moment.
func cut_to_tabletop() -> void:
	if _tabletop:
		_tabletop.current = true

## Closer framing for a dialogue/story beat. Pass the node to look toward
## (usually David) so the shot is actually composed on them.
func cut_to_closeup(look_target: Node3D = null) -> void:
	if _closeup == null:
		cut_to_tabletop()
		return
	if look_target:
		_closeup.look_at(look_target.global_position + Vector3(0.0, closeup_look_height, 0.0), Vector3.UP)
	_closeup.current = true
