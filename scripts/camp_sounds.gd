extends Node3D
## What you hear on the ridge: a few soft crickets as the bed, and a small dry
## crackle sitting on the fire, louder as the child walks up to it. Both are on
## the Ambience bus, so they duck while somebody speaks. The owl carries its
## own hoot (camp_owl.gd). Silent until the camp is visited.

const SoundLibrary := preload("res://scripts/sound_library.gd")
const SoundBus := preload("res://scripts/sound_bus.gd")

@export var crickets_db: float = -12.0
@export var fire_db: float = -4.0
@export var fade_in: float = 4.0

var _crickets: AudioStreamPlayer
var _fire: AudioStreamPlayer3D
var _gain: float = 0.0
var _on: bool = false


## `fire_at` is where the crackle sits.
func start(fire_at: Vector3) -> void:
	if _on:
		return
	_on = true
	SoundBus.ensure_buses()
	_crickets = AudioStreamPlayer.new()
	_crickets.stream = SoundLibrary.load_stream(SoundLibrary.CRICKETS, true)
	_crickets.bus = SoundBus.AMBIENCE
	_crickets.volume_db = -80.0
	add_child(_crickets)
	_fire = AudioStreamPlayer3D.new()
	_fire.stream = SoundLibrary.load_stream(SoundLibrary.CAMPFIRE, true)
	_fire.bus = SoundBus.AMBIENCE
	_fire.volume_db = -80.0
	_fire.unit_size = 2.5
	_fire.max_distance = 22.0
	add_child(_fire)
	_fire.global_position = fire_at + Vector3(0.0, 0.3, 0.0)
	if _crickets.stream:
		_crickets.play()
	if _fire.stream:
		_fire.play()


func is_playing() -> bool:
	return _on


func _process(delta: float) -> void:
	if not _on:
		return
	_gain = move_toward(_gain, 1.0, delta / maxf(fade_in, 0.01))
	var fade := linear_to_db(maxf(_gain, 0.0001))
	_crickets.volume_db = crickets_db + fade
	_fire.volume_db = fire_db + fade
