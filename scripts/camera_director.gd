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
##
## The close-up is placed in FRONT of the target (models face -Z, so "front" is
## read from the target's own basis rather than hard-coded), and the player can
## orbit around it with A/D or the arrow keys to look at it from other sides.

@export var tabletop_camera_path: NodePath = ^"../TabletopCamera"
@export var closeup_camera_path: NodePath = ^"../CloseUpCamera"
@export var closeup_look_height: float = 0.7
@export var closeup_distance: float = 1.9
@export var closeup_height: float = 1.2
@export var closeup_side_angle: float = 0.28
@export var orbit_speed: float = 1.6
@export var charm_camera_distance: float = 1.6
@export var charm_camera_height: float = 1.1

var _tabletop: Camera3D
var _closeup: Camera3D
var _orbit_target: Node3D = null
var _orbit_angle: float = 0.0

func _ready() -> void:
	_tabletop = get_node_or_null(tabletop_camera_path) as Camera3D
	_closeup = get_node_or_null(closeup_camera_path) as Camera3D

## Wide tabletop establishing shot — used for exploration and any beat that
## isn't a face-to-face moment.
func cut_to_tabletop() -> void:
	_orbit_target = null
	if _tabletop:
		_tabletop.current = true

## Closer framing for a dialogue/story beat. Pass the node to look toward
## (usually David) so the shot is actually composed on them.
func cut_to_closeup(look_target: Node3D = null) -> void:
	if _closeup == null:
		cut_to_tabletop()
		return
	if look_target:
		if look_target != _orbit_target:
			_orbit_angle = 0.0
		_orbit_target = look_target
		_place_closeup()
	_closeup.current = true

## True while the close-up is on a target the player can orbit around.
func is_orbiting() -> bool:
	return _orbit_target != null and _closeup != null and _closeup.current

func _process(delta: float) -> void:
	if not is_orbiting():
		return
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		_orbit_angle += axis * orbit_speed * delta
		_place_closeup()

func _place_closeup() -> void:
	var base := _orbit_target.global_position
	var front := -_orbit_target.global_transform.basis.z
	front.y = 0.0
	front = front.normalized() if front.length() > 0.001 else Vector3(0.0, 0.0, -1.0)
	var dir := front.rotated(Vector3.UP, _orbit_angle + closeup_side_angle)
	_closeup.global_position = base + dir * closeup_distance + Vector3(0.0, closeup_height, 0.0)
	_closeup.look_at(base + Vector3(0.0, closeup_look_height, 0.0), Vector3.UP)

## Intimate framing on the Courage charm / bracelet ceremony.
func cut_to_charm(look_target: Node3D = null) -> void:
	_orbit_target = null
	if _closeup == null:
		cut_to_tabletop()
		return
	if look_target:
		var focus := look_target.global_position + Vector3(0.0, 0.15, 0.0)
		_closeup.global_position = focus + Vector3(0.55, charm_camera_height, charm_camera_distance)
		_closeup.look_at(focus, Vector3.UP)
	_closeup.current = true
