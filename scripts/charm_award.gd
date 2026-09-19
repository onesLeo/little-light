extends Node3D
## Courage charm ceremony.
## Float-in → snap onto Virtue Bracelet → gold pulse → tiny walker hop / David nod.
## Bracelet/charm art comes from assets/courage_charm_v1.glb
## (art/blender/scripts/props/generate_courage_charm.py).

signal ceremony_finished

const CHARM_ART: PackedScene = preload("res://assets/courage_charm_v1.glb")

@export var player_path: NodePath = ^"../Player"
@export var david_path: NodePath = ^"../DavidMentor"
@export var float_height: float = 1.35
@export var snap_duration: float = 0.55
@export var pulse_duration: float = 0.45

var _bracelet: MeshInstance3D
var _charm: MeshInstance3D
var _charm_mat: StandardMaterial3D
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
	_build_art()
	visible = false


func _build_art() -> void:
	var art := CHARM_ART.instantiate()
	add_child(art)
	_bracelet = art.find_child("VirtueBracelet", true, false) as MeshInstance3D
	_charm = art.find_child("CourageCharm", true, false) as MeshInstance3D

	# The outline hulls are separate root nodes in the GLB (matching the rest
	# of the papercraft pipeline's single-skin-hull convention); reparent the
	# charm's hull onto the charm itself so it rides along with the ceremony
	# tween instead of staying behind at its rest transform.
	var charm_outline := art.find_child("CourageCharm_Outline", true, false) as Node3D
	if charm_outline and _charm:
		charm_outline.reparent(_charm, true)

	if _charm:
		var mat := _charm.get_active_material(0)
		if mat is StandardMaterial3D:
			_charm_mat = mat
		else:
			# Fallback if a re-export ever yields a non-StandardMaterial3D.
			_charm_mat = StandardMaterial3D.new()
			_charm_mat.albedo_color = Color(0.92, 0.70, 0.20)
			_charm.set_surface_override_material(0, _charm_mat)
		_charm_mat.emission_enabled = true
		_charm_mat.emission = Color(1.0, 0.85, 0.4)
		_charm_mat.emission_energy_multiplier = 0.0
		_charm.position = _rest_charm_pos


## Play the award ceremony. Safe to call once per chapter end.
func play_ceremony() -> void:
	if _running:
		return
	_running = true
	visible = true
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
	tw.tween_property(_charm_mat, "emission_energy_multiplier", 0.35, pulse_duration * 0.55)
	tw.tween_callback(_play_reactions)
	tw.tween_interval(0.55)
	tw.tween_callback(_finish)


func _celebrate_snap() -> void:
	if _audio and _audio.has_method("play_fanfare"):
		_audio.play_fanfare()
	if _confetti and _confetti.has_method("burst"):
		_confetti.burst(_charm.global_position + Vector3(0.0, 0.1, 0.0), 70, 0.12, 2.6, 0.32)


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
