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
var _push_in: float = 0.0
var _shot_distance: float = 1.9
var _shot_look_height: float = 0.7
var _camp_shot: bool = false
var _shot_time: float = 0.0

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
	_camp_shot = false
	_push_in = 0.0
	_shot_distance = closeup_distance
	_shot_look_height = closeup_look_height
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
func move_to_closeup(target: Node3D) -> void:
	cut_to_closeup(target)
	_camp_shot = true
	_shot_time = 0.0
	_shot_distance = 2.7
	_shot_look_height = 0.94
	_push_in = 1.0
	_place_closeup()


func is_orbiting() -> bool:
	return _orbit_target != null and _closeup != null and _closeup.current

func _process(delta: float) -> void:
	if not is_orbiting():
		return
	_shot_time += delta
	_push_in = move_toward(_push_in, 0.0, delta * 0.65)
	_place_closeup()
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		_orbit_angle += axis * orbit_speed * delta
		_place_closeup()

func _place_closeup() -> void:
	var base := _orbit_target.global_position
	var front := -_orbit_target.global_transform.basis.z
	front.y = 0.0
	front = front.normalized() if front.length() > 0.001 else Vector3(0.0, 0.0, -1.0)
	# The camp conversation gets a very small automatic arc, like turning a
	# storybook page toward both friends. Player look input remains additive.
	var story_arc := sin(_shot_time * 0.42) * 0.055 if _camp_shot else 0.0
	var dir := front.rotated(Vector3.UP, _orbit_angle + closeup_side_angle + story_arc)
	var cam := base + dir * (_shot_distance + _push_in * 1.1) + Vector3(0.0, closeup_height, 0.0)
	var look := base + Vector3(0.0, _shot_look_height, 0.0)
	var walker := get_node_or_null("../Player") as Node3D
	if walker and (not _camp_shot or walker.global_position.distance_to(base) < 4.5):
		var framed := _frame_around_walker(cam, look, dir, base, walker)
		cam = framed[0]
		look = framed[1]
	_closeup.global_position = cam
	_closeup.look_at(look, Vector3.UP)


## The orbit ring passes through where the Wonder-Walker is standing. Left alone,
## the camera ends up inside that body: the head is cut off, and looking back
## from David shows only the neck. When the ring gets close, step aside to
## David's shoulder and frame the walker's face instead.
func _frame_around_walker(cam: Vector3, look: Vector3, dir: Vector3, david_pos: Vector3, walker: Node3D) -> Array:
	var to_walker := walker.global_position - david_pos
	to_walker.y = 0.0
	if to_walker.length() < 0.4 or to_walker.length() > 4.5:
		var clear := _push_out_of_walker(cam, walker.global_position)
		clear = _keep_head_in_frame(clear, look, walker.global_position + Vector3(0.0, 1.17, 0.0))
		return [clear, look]
	var body := walker.global_position + Vector3(0.0, 0.75, 0.0)
	var closeness := clampf((2.15 - cam.distance_to(body)) / 1.15, 0.0, 1.0)
	var align := dir.dot(to_walker.normalized())
	if closeness > 0.0 and align > 0.15:
		var blend := closeness * clampf((align - 0.15) / 0.55, 0.0, 1.0)
		var side := dir.cross(Vector3.UP)
		side = side.normalized() if side.length() > 0.001 else Vector3.RIGHT
		var face := walker.global_position + Vector3(0.0, 0.95, 0.0)
		var shoulder := david_pos + Vector3(0.0, 1.15, 0.0) + side * 0.6
		var from_face := shoulder - face
		if from_face.length() < 2.15:
			shoulder = face + from_face.normalized() * 2.15
		shoulder.y = maxf(shoulder.y, face.y + 0.5)
		cam = cam.lerp(shoulder, blend)
		look = look.lerp(face, blend)
	cam = _push_out_of_walker(cam, walker.global_position)
	cam = _keep_head_in_frame(cam, look, walker.global_position + Vector3(0.0, 1.17, 0.0))
	return [cam, look]


func _push_out_of_walker(cam: Vector3, walker_pos: Vector3) -> Vector3:
	var body := walker_pos + Vector3(0.0, 0.7, 0.0)
	var delta := cam - body
	if delta.length() < 1.15:
		if delta.length() < 0.01:
			delta = Vector3(0.0, 0.4, 1.0)
		cam = body + delta.normalized() * 1.15
	return cam


## Pulls the camera back and up until the top of the walker's head sits inside
## the picture. Does nothing when the walker is off to the side, so David's
## own close-up stays put.
func _keep_head_in_frame(cam: Vector3, look: Vector3, head: Vector3) -> Vector3:
	var to_head := head - cam
	var flat_head := Vector3(to_head.x, 0.0, to_head.z)
	var flat_look := look - cam
	flat_look.y = 0.0
	if flat_head.length() > 1.8 and flat_look.length() > 0.05 and flat_look.normalized().dot(flat_head.normalized()) < 0.45:
		return cam
	var limit := deg_to_rad(_closeup.fov if _closeup else 32.0) * 0.5 * 0.7
	for _i in 8:
		var forward := look - cam
		if forward.length() < 0.05:
			break
		forward = forward.normalized()
		to_head = head - cam
		if to_head.length() > 0.85 and forward.dot(to_head) > 0.0 and forward.angle_to(to_head) <= limit:
			break
		var back := cam - look
		back.y = 0.0
		if back.length() < 0.05:
			back = Vector3(0.0, 0.0, 1.0)
		cam += back.normalized() * 0.4
		cam.y += 0.14
	return cam

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
