extends Node3D
## The sound of the valley: a slow music-box lullaby, wind, a stream you can hear
## get louder and pan as the Wonder-Walker walks toward it, and birds calling now
## and then from around the meadow. Everything under it drops out of the way while
## Wonder Light or David is speaking, and while the game is paused.

const SoundBus := preload("res://scripts/sound_bus.gd")
const SoundLibrary := preload("res://scripts/sound_library.gd")
const MeadowDressing := preload("res://scripts/meadow_dressing.gd")

## Seconds between bird calls (min, max).
@export var bird_interval: Vector2 = Vector2(4.0, 11.0)
## How far from the Wonder-Walker a bird sits (min, max).
@export var bird_radius: Vector2 = Vector2(6.0, 14.0)
## Chance that a second bird answers the first.
@export_range(0.0, 1.0) var bird_reply_chance: float = 0.3
@export var music_fade_in: float = 4.0
## Extra ducking while the game is paused (0-1).
@export_range(0.0, 1.0) var pause_duck: float = 0.6

var _music: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _stream: AudioStreamPlayer3D
var _birds: Array[AudioStreamPlayer3D] = []
var _listener: AudioListener3D
var _player: Node3D
var _camera: Camera3D
var _audio: Node
var _rng := RandomNumberGenerator.new()
var _bird_timer: float = 3.0
var _reply_timer: float = -1.0
var _music_gain: float = 0.0


func _ready() -> void:
	# Keeps playing (a little quieter) behind the pause menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	SoundBus.ensure_buses()
	var main := get_parent()
	_player = main.get_node_or_null("Player") as Node3D
	_camera = main.get_node_or_null("TabletopCamera") as Camera3D
	_audio = main.get_node_or_null("AudioDirector")

	# 3D sounds are heard from the Wonder-Walker, but panned the way the camera
	# looks, so "the stream is on the left" matches the screen.
	_listener = AudioListener3D.new()
	add_child(_listener)
	_listener.make_current()

	_music = _make_player(SoundLibrary.load_stream(SoundLibrary.MUSIC, true), SoundBus.MUSIC, -80.0)
	_wind = _make_player(SoundLibrary.load_stream(SoundLibrary.WIND, true), SoundBus.AMBIENCE, -4.0)
	_stream = _make_player3d(SoundLibrary.load_stream(SoundLibrary.STREAM, true), SoundBus.AMBIENCE, -2.0, 3.0, 32.0)
	for i in 3:
		_birds.append(_make_player3d(null, SoundBus.AMBIENCE, 0.0, 6.0, 40.0))
	_move_stream()
	_update_listener()


func _process(delta: float) -> void:
	_update_listener()
	_move_stream()
	# Music fades in gently instead of starting at full level.
	_music_gain = move_toward(_music_gain, 1.0, delta / maxf(music_fade_in, 0.01))
	_music.volume_db = linear_to_db(maxf(_music_gain, 0.0001))
	_update_ducking(delta)
	_update_birds(delta)


func _make_player(stream: AudioStream, bus: String, volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = volume_db
	add_child(p)
	if stream:
		p.play()
	return p


func _make_player3d(stream: AudioStream, bus: String, volume_db: float, unit_size: float, max_distance: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = volume_db
	p.unit_size = unit_size
	p.max_distance = max_distance
	add_child(p)
	if stream:
		p.play()
	return p


func _update_listener() -> void:
	if _player == null:
		return
	var basis := Basis.IDENTITY
	if _camera:
		basis = _camera.global_transform.basis.orthonormalized()
	_listener.global_transform = Transform3D(basis, _player.global_position + Vector3(0.0, 0.6, 0.0))


## The stream sounds like it is where the water is: the point on the stream
## nearest to the Wonder-Walker.
func _move_stream() -> void:
	if _player == null:
		return
	var p := Vector2(_player.global_position.x, _player.global_position.z)
	var pts: Array = MeadowDressing.STREAM_XZ
	var best := Vector2.ZERO
	var best_d := INF
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab := b - a
		var len2 := ab.length_squared()
		var t := 0.0 if len2 < 0.0001 else clampf((p - a).dot(ab) / len2, 0.0, 1.0)
		var q := a + ab * t
		if p.distance_to(q) < best_d:
			best_d = p.distance_to(q)
			best = q
	_stream.global_position = Vector3(best.x, 0.3, best.y)


func _update_ducking(delta: float) -> void:
	var target := 0.0
	if _audio and _audio.has_method("is_speaking") and _audio.is_speaking():
		target = 1.0
	if get_tree().paused:
		target = maxf(target, pause_duck)
	var rate := 4.0 if target > SoundBus.duck else 1.0  # dips quickly, comes back slowly
	SoundBus.set_duck(move_toward(SoundBus.duck, target, delta * rate))


func _update_birds(delta: float) -> void:
	_bird_timer -= delta
	if _bird_timer <= 0.0:
		_bird_timer = _rng.randf_range(bird_interval.x, bird_interval.y)
		_call_bird(0.0)
		if _rng.randf() < bird_reply_chance:
			_reply_timer = _rng.randf_range(0.6, 1.3)
	if _reply_timer >= 0.0:
		_reply_timer -= delta
		if _reply_timer < 0.0:
			_call_bird(-5.0)


func _call_bird(extra_db: float) -> void:
	if _player == null:
		return
	for bird in _birds:
		if bird.playing:
			continue
		var angle := _rng.randf() * TAU
		var radius := _rng.randf_range(bird_radius.x, bird_radius.y)
		bird.global_position = _player.global_position + Vector3(cos(angle) * radius, _rng.randf_range(2.0, 4.5), sin(angle) * radius)
		bird.stream = SoundLibrary.bird(_rng.randi())
		bird.pitch_scale = _rng.randf_range(0.9, 1.15)
		bird.volume_db = _rng.randf_range(-3.0, 1.0) + extra_db
		bird.play()
		return
