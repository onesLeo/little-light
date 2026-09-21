extends Node3D
## Courage charm ceremony (placeholder paper meshes).
## Float-in → snap onto Virtue Bracelet → gold pulse → tiny walker hop / David nod.
## Models Creations Bot can later swap Bracelet/Charm for authored GLBs.
## If the child playing has coloured their Courage charm (colour_screen.gd), their picture is on its face.

signal ceremony_finished

const Profiles := preload("res://scripts/profiles.gd")
const CharmArt := preload("res://scripts/charm_art.gd")
const JournalContent := preload("res://scripts/journal_content.gd")

@export var player_path: NodePath = ^"../Player"
@export var david_path: NodePath = ^"../DavidMentor"
@export var float_height: float = 1.35
@export var snap_duration: float = 0.55
@export var pulse_duration: float = 0.45

var _bracelet: MeshInstance3D
var _charm: MeshInstance3D
var _charm_mat: StandardMaterial3D
var _face: MeshInstance3D
var _face_mat: StandardMaterial3D
var _player: Node3D
var _david: Node3D
var _audio: Node
var _confetti: Node
var _running: bool = false
var _rest_charm_pos: Vector3 = Vector3(0.0, 0.08, 0.12)

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	_david = get_node_or_null(david_path) as Node3D
	_audio = get_node_or_null("%AudioDirector")
	_confetti = get_node_or_null("%ConfettiBurst")
	_build_placeholders()
	visible = false


func _build_placeholders() -> void:
	# Virtue Bracelet — soft paper gold ring (placeholder).
	_bracelet = MeshInstance3D.new()
	_bracelet.name = "VirtueBraceletPlaceholder"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.12
	torus.outer_radius = 0.18
	torus.rings = 12
	torus.ring_segments = 16
	_bracelet.mesh = torus
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.82, 0.62, 0.28)
	bmat.roughness = 0.85
	bmat.metallic = 0.15
	_bracelet.set_surface_override_material(0, bmat)
	_bracelet.position = Vector3(0.0, 0.0, 0.0)
	_bracelet.rotation_degrees = Vector3(70.0, 0.0, 0.0)
	add_child(_bracelet)

	# Courage charm — small warm disc (placeholder).
	_charm = MeshInstance3D.new()
	_charm.name = "CourageCharmPlaceholder"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.07
	disc.bottom_radius = 0.07
	disc.height = 0.03
	disc.radial_segments = 12
	_charm.mesh = disc
	_charm_mat = StandardMaterial3D.new()
	_charm_mat.albedo_color = Color(0.95, 0.78, 0.35)
	_charm_mat.roughness = 0.7
	_charm_mat.emission_enabled = true
	_charm_mat.emission = Color(1.0, 0.85, 0.4)
	_charm_mat.emission_energy_multiplier = 0.0
	_charm.set_surface_override_material(0, _charm_mat)
	_charm.position = _rest_charm_pos
	add_child(_charm)
	apply_child_colours()


## Puts the playing child's colouring on the charm's face, or takes it off when they have none.
func apply_child_colours() -> void:
	if _face != null:
		_charm.remove_child(_face)
		_face.queue_free()
		_face = null
		_face_mat = null
	var id := Profiles.active_id
	var charm_id := JournalContent.CHARM_COURAGE
	if id.is_empty() or not Profiles.has_coloured_charm(id, charm_id):
		return
	var picture := ImageTexture.create_from_image(CharmArt.render_image(charm_id, Profiles.charm_colours(id, charm_id), 128))
	var quad := QuadMesh.new()
	quad.size = Vector2(0.15, 0.15)
	quad.orientation = PlaneMesh.FACE_Y
	_face_mat = StandardMaterial3D.new()
	_face_mat.albedo_texture = picture
	_face_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_face_mat.alpha_scissor_threshold = 0.5
	_face_mat.roughness = 0.8
	_face_mat.emission_enabled = true
	_face_mat.emission_texture = picture
	_face_mat.emission_energy_multiplier = 0.0
	_face = MeshInstance3D.new()
	_face.name = "ChildColouring"
	_face.mesh = quad
	_face.set_surface_override_material(0, _face_mat)
	_face.position = Vector3(0.0, 0.0165, 0.0)
	_charm.add_child(_face)


## Play the award ceremony. Safe to call once per chapter end.
func play_ceremony() -> void:
	if _running:
		return
	_running = true
	visible = true
	apply_child_colours()
	_charm_mat.emission_energy_multiplier = 0.0
	_charm.position = _rest_charm_pos + Vector3(0.0, float_height, 0.0)
	_charm.scale = Vector3(0.35, 0.35, 0.35)

	var tw := create_tween()
	tw.set_parallel(false)
	# Float in + grow.
	tw.tween_property(_charm, "position", _rest_charm_pos, snap_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_charm, "scale", Vector3.ONE, snap_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Snap squash.
	tw.tween_property(_charm, "scale", Vector3(1.15, 0.85, 1.15), 0.08)
	tw.tween_property(_charm, "scale", Vector3.ONE, 0.12)
	tw.tween_callback(_celebrate_snap)
	# Gold pulse.
	tw.tween_property(_charm_mat, "emission_energy_multiplier", 2.2, pulse_duration * 0.45).set_trans(Tween.TRANS_SINE)
	if _face_mat:
		tw.parallel().tween_property(_face_mat, "emission_energy_multiplier", 1.0, pulse_duration * 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_charm_mat, "emission_energy_multiplier", 0.35, pulse_duration * 0.55)
	if _face_mat:
		tw.parallel().tween_property(_face_mat, "emission_energy_multiplier", 0.05, pulse_duration * 0.55)
	tw.tween_callback(_play_reactions)
	tw.tween_interval(0.55)
	tw.tween_callback(_finish)


func _celebrate_snap() -> void:
	if _audio and _audio.has_method("play_fanfare"):
		_audio.play_fanfare()
	if _confetti and _confetti.has_method("burst"):
		_confetti.burst(_charm.global_position + Vector3(0.0, 0.1, 0.0), 90, 0.10, 2.2, 0.22)


func _play_reactions() -> void:
	# Tiny Wonder-Walker hop.
	if _player:
		var model := _player.get_node_or_null("Model") as Node3D
		var target := model if model else _player
		var base_y := target.position.y
		var hop := create_tween()
		hop.tween_property(target, "position:y", base_y + 0.18, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		hop.tween_property(target, "position:y", base_y, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	# David soft nod.
	if _david:
		var base_rx := _david.rotation.x
		var nod := create_tween()
		nod.tween_property(_david, "rotation:x", base_rx + deg_to_rad(12.0), 0.18)
		nod.tween_property(_david, "rotation:x", base_rx, 0.28).set_trans(Tween.TRANS_SINE)


func _finish() -> void:
	_running = false
	ceremony_finished.emit()
