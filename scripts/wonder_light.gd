extends Node3D
## Wonder Light — the frame story's "small firefly-like spirit" companion
## (see the design doc: it guides the child from story to story and grows
## warmer/brighter as chapters are completed). This is its first visible,
## in-world form for the David & Goliath slice: a soft glowing orb that
## hovers near the Wonder-Walker.
##
## Gameplay purpose: a literal second pair of eyes on the diorama. The
## chapter director can call point_at() to have it drift toward whatever
## the story wants the child looking at (David, a Wonder Item), and
## celebrate() to give it a warm little pulse at good moments — all
## without a single word of dialogue, which matters for the Band A (6-8)
## no-reading play mode.

@export var follow_target_path: NodePath = ^"../Player"
@export var hover_offset: Vector3 = Vector3(0.55, 1.5, 0.45)
@export var follow_speed: float = 2.5
@export var bob_height: float = 0.12
@export var bob_speed: float = 1.8

var _target: Node3D
var _look_target: Node3D = null
var _time: float = randf() * TAU
var _glow_mat: StandardMaterial3D
var _base_energy: float = 1.0
var _pulse_tween: Tween

func _ready() -> void:
	_target = get_node_or_null(follow_target_path) as Node3D
	var glow := get_node_or_null("Glow") as MeshInstance3D
	if glow:
		_glow_mat = glow.get_surface_override_material(0) as StandardMaterial3D
		if _glow_mat:
			_base_energy = _glow_mat.emission_energy_multiplier
	if _target:
		global_position = _target.global_position + hover_offset

func _process(delta: float) -> void:
	_time += delta
	var anchor := _look_target if _look_target else _target
	if anchor == null:
		return
	var desired := anchor.global_position + hover_offset
	desired.y += sin(_time * bob_speed) * bob_height
	global_position = global_position.lerp(desired, clampf(follow_speed * delta, 0.0, 1.0))

## Have the companion drift toward and hover near something the story wants
## noticed (David, a Wonder Item). Pass null to resume following the player.
func point_at(node: Node3D) -> void:
	_look_target = node

## A brief warm brighten — used for "found something" / "well done" beats.
func celebrate() -> void:
	if _glow_mat == null:
		return
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(_glow_mat, "emission_energy_multiplier", _base_energy * 2.4, 0.2)
	_pulse_tween.tween_property(_glow_mat, "emission_energy_multiplier", _base_energy, 0.7)
