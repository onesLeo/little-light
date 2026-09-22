extends Node
## Steady Hands breathing mini-game — David & Goliath chapter.
##
## Hold Space (A on a gamepad, the BREATHE button on touch) to breathe in and the
## ring grows; let go to breathe out and it shrinks. Three slow breaths and it is
## done. There is no fail state, no aiming and no target.
##
## The breathing is deliberately slow and calm, and the ring cannot be rushed:
## - it fills over about 4 s and empties over about 4.5 s, whatever the button does
## - it changes direction gradually (over about 1.4 s), never with a snap, so
##   tapping the button quickly hardly moves it
## - a breath counts only after the ring has filled and then emptied again
## And nobody can get stuck:
## - hold at full for 2 s and the ring lets go by itself
## - wait 7 s at empty and the ring breathes in by itself, and that breath counts
##
## Wonder Light glows and David rises a little as the ring grows, and a soft hush
## of air follows it. David also settles down toward his lamb for the whole
## activity (a shape key, since he has no rig -- see companion_sheep_life.gd's
## neighbour, the "Crouch" key on his own model) instead of standing frozen.

signal minigame_completed
## Emitted after each finished breath, with how many are done.
signal breath_completed(count: int)

const SoundBus := preload("res://scripts/sound_bus.gd")
const SoundLibrary := preload("res://scripts/sound_library.gd")

@export var breaths_required: int = 3
@export var inhale_seconds: float = 4.0
@export var exhale_seconds: float = 4.5
## Seconds to go from breathing in at full pace to breathing out at full pace.
@export var turn_seconds: float = 1.4
@export var hold_at_full_seconds: float = 2.0
@export var idle_help_seconds: float = 7.0
@export var empty_scale: float = 0.62
@export var full_scale: float = 1.32
## Volume of the air sound when the ring is still and at full breathing speed, in dB.
@export var air_db_still: float = -26.0
@export var air_db_breathing: float = -8.0

## How full the ring counts as full, and how empty as empty.
const FULL := 0.9
const EMPTY := 0.15

var active: bool = false
## Ring fullness, 0 (empty) to 1 (full), and how fast it is changing per second.
var level: float = 0.0
var velocity: float = 0.0
var breaths_done: int = 0

var _armed: bool = false
var _reached_full: bool = false
var _assist: bool = false
var _locked_out: bool = false
var _full_time: float = 0.0
var _idle_time: float = 0.0
var _label_text: String = ""

@onready var _breath: Control = get_node_or_null("%BreathIndicator") as Control
@onready var _audio: Node = get_node_or_null("%AudioDirector")
var _breath_label: Label
var _dots: BreathDots
var _air: AudioStreamPlayer
var _wonder_light: Node
var _david: Node3D
var _david_base_scale: Vector3 = Vector3.ONE
var _david_meshes: Array[MeshInstance3D] = []
var _crouch_shape: int = -1
var _crouch_tween: Tween
var _tween: Tween
var _air_tween: Tween


## Little dots under the ring: one for each breath, filled as they are done.
class BreathDots extends Control:
	var total: int = 3
	var done: int = 0

	func _draw() -> void:
		var radius := 9.0
		var gap := 30.0
		var x0 := size.x * 0.5 - gap * (total - 1) * 0.5
		for i in total:
			var c := Vector2(x0 + gap * i, size.y * 0.5)
			draw_circle(c, radius, Color(0.98, 0.78, 0.25, 1.0 if i < done else 0.25))
			draw_arc(c, radius, 0.0, TAU, 24, Color(0.35, 0.2, 0.08, 0.85), 2.0)


func _ready() -> void:
	active = false
	set_process(false)
	_wonder_light = get_node_or_null("../WonderLight")
	_david = get_node_or_null("../DavidMentor") as Node3D
	if _david:
		_david_base_scale = _david.scale
		for name in ["David_Mentor", "David_Mentor_Outline"]:
			var mesh_node := _david.get_node_or_null(name) as MeshInstance3D
			if mesh_node:
				_david_meshes.append(mesh_node)
				if _crouch_shape < 0 and mesh_node.mesh:
					for i in mesh_node.mesh.get_blend_shape_count():
						if mesh_node.mesh.get_blend_shape_name(i) == "Crouch":
							_crouch_shape = i
							break
	_air = AudioStreamPlayer.new()
	_air.stream = SoundLibrary.load_stream(SoundLibrary.BREATH, true)
	_air.bus = SoundBus.EFFECTS
	_air.volume_db = -80.0
	add_child(_air)
	if _breath:
		_breath.visible = false
		_breath.modulate.a = 1.0
		_breath.scale = Vector2.ONE * empty_scale
		# "In..." / "Out..." so a child who cannot read the story still knows what to do.
		_breath_label = Label.new()
		_breath_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_breath_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_breath_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_breath_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_breath_label.add_theme_font_size_override("font_size", 30)
		_breath_label.add_theme_color_override("font_color", Color(0.35, 0.2, 0.08))
		_breath.add_child(_breath_label)
		_dots = BreathDots.new()
		_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dots.anchor_left = 0.8
		_dots.anchor_right = 0.8
		_dots.anchor_top = 0.34
		_dots.anchor_bottom = 0.34
		_dots.offset_left = -60.0
		_dots.offset_right = 60.0
		_dots.offset_top = 112.0
		_dots.offset_bottom = 142.0
		_dots.visible = false
		_breath.get_parent().add_child(_dots)


func start_minigame() -> void:
	breaths_done = 0
	level = 0.0
	velocity = 0.0
	_armed = false
	_reached_full = false
	_assist = false
	_locked_out = false
	_full_time = 0.0
	_idle_time = 0.0
	_label_text = ""
	active = true
	set_process(true)
	_kill_tween(_tween)
	_kill_tween(_air_tween)
	if _breath:
		_breath.visible = true
		_breath.modulate.a = 1.0
	if _dots:
		_dots.total = breaths_required
		_dots.done = 0
		_dots.visible = true
		_dots.queue_redraw()
	_air.volume_db = air_db_still
	_air.play()
	_update_visuals()
	# David settles down toward the lamb while the child breathes with him,
	# rather than standing frozen off to the side.
	_tween_crouch(1.0, 1.2)


func _process(delta: float) -> void:
	_advance(delta, _is_holding())


## Space, Enter, gamepad A, or the touch button held down.
func _is_holding() -> bool:
	return Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER)


## One step of the breathing, kept apart from real input so it can be tested.
func _advance(delta: float, holding: bool) -> void:
	if not active:
		return
	# The press that started this step must be let go of before it counts.
	if not _armed:
		if holding:
			holding = false
		else:
			_armed = true
	if _locked_out:
		if not holding:
			_locked_out = false
		holding = false
	if holding and _assist:
		_assist = false  # the child has taken over
	var breathe_in := holding or _assist
	if _assist and level >= 0.95:
		_assist = false
		breathe_in = holding
	# Stuck at full: the ring lets go by itself, even if the button is still down.
	if level >= 0.97 and breathe_in:
		_full_time += delta
		if _full_time >= hold_at_full_seconds:
			_assist = false
			if holding:
				_locked_out = true
			breathe_in = false
	else:
		_full_time = 0.0
	# Nothing pressed for a while at empty: the ring breathes in on its own.
	if not breathe_in and level < 0.08 and not _reached_full:
		_idle_time += delta
		if _idle_time >= idle_help_seconds:
			_assist = true
			_idle_time = 0.0
	else:
		_idle_time = 0.0

	# Move at a fixed, gentle pace and change direction gradually.
	var target := 1.0 / inhale_seconds if breathe_in else -1.0 / exhale_seconds
	var accel := (1.0 / inhale_seconds + 1.0 / exhale_seconds) / maxf(turn_seconds, 0.1)
	velocity = move_toward(velocity, target, accel * delta)
	level = clampf(level + velocity * delta, 0.0, 1.0)
	if (level <= 0.0 and velocity < 0.0) or (level >= 1.0 and velocity > 0.0):
		velocity = 0.0

	if level >= FULL:
		_reached_full = true
	if _reached_full and level <= EMPTY:
		_reached_full = false
		_complete_breath()
	if active:
		_update_visuals()


func _complete_breath() -> void:
	breaths_done += 1
	if _dots:
		_dots.done = breaths_done
		_dots.queue_redraw()
	if _audio and _audio.has_method("play_tap"):
		_audio.play_tap()
	breath_completed.emit(breaths_done)
	if breaths_done >= breaths_required:
		_finish_breath()


func _update_visuals() -> void:
	var eased := level * level * (3.0 - 2.0 * level)
	if _breath:
		_breath.scale = Vector2.ONE * lerpf(empty_scale, full_scale, eased)
		_breath.modulate.a = lerpf(0.75, 1.0, eased)
	# "In..." while it grows, "Out..." while it shrinks or waits at full, "Hold" when empty.
	if velocity > 0.04:
		_set_breath_text("In...")
	elif velocity < -0.04 or level >= 0.97:
		_set_breath_text("Out...")
	elif level < 0.1:
		_set_breath_text("Hold")
	if _wonder_light and _wonder_light.has_method("set_breath"):
		_wonder_light.set_breath(eased)
	if _david:
		_david.scale = _david_base_scale * Vector3(1.0 + 0.008 * eased, 1.0 + 0.02 * eased, 1.0 + 0.008 * eased)
	var pace := clampf(absf(velocity) * inhale_seconds, 0.0, 1.0)
	_air.volume_db = lerpf(air_db_still, air_db_breathing, pace)
	_air.pitch_scale = lerpf(0.85, 1.15, eased)


## Success: one warm bloom-out, then hide and tell the director we're done.
func _finish_breath() -> void:
	active = false
	set_process(false)
	if _wonder_light and _wonder_light.has_method("set_breath"):
		_wonder_light.set_breath(0.0)
	if _david:
		_david.scale = _david_base_scale
	_tween_crouch(0.0, 1.0)
	_kill_tween(_air_tween)
	_air_tween = create_tween()
	_air_tween.tween_property(_air, "volume_db", -60.0, 0.8)
	_air_tween.tween_callback(_air.stop)
	if _audio and _audio.has_method("play_success"):
		_audio.play_success()
	if _breath == null:
		minigame_completed.emit()
		return
	_kill_tween(_tween)
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_breath, "scale", Vector2.ONE * 1.5, 0.35)
	_tween.parallel().tween_property(_breath, "modulate:a", 0.0, 0.55)
	_tween.tween_callback(func():
		_breath.visible = false
		if _dots:
			_dots.visible = false
		_set_breath_text("")
		minigame_completed.emit()
	)


func _set_breath_text(text: String) -> void:
	if _breath_label and text != _label_text:
		_label_text = text
		_breath_label.text = text


## Blends David's "Crouch" shape key (0 standing, 1 leaned down toward the
## lamb) on both his body and its outline hull together, so the ink outline
## never lags behind and separates from the body mid-tween.
func _tween_crouch(target: float, seconds: float) -> void:
	if _crouch_shape < 0 or _david_meshes.is_empty():
		return
	_kill_tween(_crouch_tween)
	_crouch_tween = create_tween()
	_crouch_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for mesh_node in _david_meshes:
		_crouch_tween.parallel().tween_method(
			func(v: float) -> void: mesh_node.set_blend_shape_value(_crouch_shape, v),
			mesh_node.get_blend_shape_value(_crouch_shape), target, seconds)


func _kill_tween(t: Tween) -> void:
	if t and t.is_valid():
		t.kill()
