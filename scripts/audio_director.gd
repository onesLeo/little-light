extends Node
## Central SFX + voice hookup point.
##
## SFX are tiny procedural chimes (see chime_synth.gd) plus soft footsteps
## (sound files rendered by tools/make_sounds.py). Callers (play_pickup,
## play_tap, play_success, play_step) don't care where the sound comes from.
##
## Voice: every dialogue line is read aloud, with recorded clips (vo_library.gd)
## or, for a line without one, the system voice. A clip in vo_clips keyed by
## ChapterDirector.Beat name (e.g. "ARRIVE") plays automatically for that beat.
##
## Sounds go to the Effects bus and the voice to the Voice bus (sound_bus.gd),
## so the pause menu can balance them and Soundscape can duck the music.

const ChimeSynth := preload("res://scripts/chime_synth.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const VoLibrary := preload("res://scripts/vo_library.gd")
const SoundBus := preload("res://scripts/sound_bus.gd")
const SoundLibrary := preload("res://scripts/sound_library.gd")

## Silence between two recorded lines of one dialogue block, in seconds.
## Long enough for a breath, short enough that a child does not wander off.
const CLIP_GAP := 0.45

## Emitted when read-aloud is switched on or off.
signal read_aloud_changed(enabled: bool)
## Emitted when a run of recorded lines has finished on its own, not when speech
## is cut off to start another line.
signal speech_finished

var _suppress_finish: bool = false

@export var vo_clips: Dictionary = {}

@onready var _sfx_players: Array[AudioStreamPlayer] = [$SfxA, $SfxB, $SfxC]
@onready var _vo_player: AudioStreamPlayer = $Vo

var _stream_pickup: AudioStreamWAV
var _stream_tap: AudioStreamWAV
var _stream_success: AudioStreamWAV
var _stream_fanfare: AudioStreamWAV
var _stream_cheer: AudioStreamWAV
var _next_player: int = 0
var _voices: PackedStringArray = PackedStringArray()
var _vo_active: bool = false
var _has_clips: bool = false
var _speaking_clips: bool = false
var _clip_queue: Array[AudioStream] = []
## Bumped whenever speech is cut off, so a queued clip knows it is stale.
var _clip_run: int = 0
var _step_players: Array[AudioStreamPlayer] = []
var _next_step: int = 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_stream_pickup = ChimeSynth.build_chime([880.0, 1318.5], 0.16)
	_stream_tap = ChimeSynth.build_chime([440.0], 0.08)
	_stream_success = ChimeSynth.build_chime([523.25, 659.25, 783.99], 0.4)
	_stream_fanfare = ChimeSynth.build_fanfare()
	_stream_cheer = ChimeSynth.build_cheer()
	_rng.randomize()
	SoundBus.ensure_buses()
	for player in _sfx_players:
		player.bus = SoundBus.EFFECTS
	_vo_player.bus = SoundBus.VOICE
	# Two players so quick steps overlap instead of cutting each other off.
	for i in 2:
		var step := AudioStreamPlayer.new()
		step.bus = SoundBus.EFFECTS
		add_child(step)
		_step_players.append(step)
	GameSettings.load_settings()
	SoundBus.apply_mix()
	_init_tts()
	_has_clips = VoLibrary.has_any()
	_vo_player.finished.connect(_on_vo_finished)

func play_pickup() -> void:
	_play_sfx(_stream_pickup)

func play_tap() -> void:
	_play_sfx(_stream_tap)

func play_success() -> void:
	_play_sfx(_stream_success)

func play_fanfare() -> void:
	_play_sfx(_stream_fanfare)

func play_cheer() -> void:
	_play_sfx(_stream_cheer)

## A soft footstep, a little different every time: on "grass", the "path" or in "water".
func play_step(surface: String = "grass") -> void:
	var player := _step_players[_next_step]
	_next_step = (_next_step + 1) % _step_players.size()
	var stream := SoundLibrary.step(_rng.randi(), surface)
	if stream == null:
		return
	player.stream = stream
	player.pitch_scale = _rng.randf_range(0.92, 1.08)
	player.volume_db = _rng.randf_range(-3.0, 0.0)
	player.play()

## True while any line is being spoken (a clip, the gap between two clips, or
## system speech). Soundscape ducks the music while this is true.
func is_speaking() -> bool:
	if _speaking_clips or _vo_player.playing:
		return true
	return not _voices.is_empty() and DisplayServer.tts_is_speaking()

## No-op until vo_clips[beat_name] is assigned a real recorded/imported clip.
func play_vo(beat_name: String) -> void:
	var clip: AudioStream = vo_clips.get(beat_name)
	_vo_active = clip != null
	if clip == null:
		return
	_vo_player.stream = clip
	_vo_player.play()

func _play_sfx(stream: AudioStreamWAV) -> void:
	var player := _sfx_players[_next_player]
	_next_player = (_next_player + 1) % _sfx_players.size()
	player.stream = stream
	player.play()


## -- Read-aloud ---------------------------------------------------------------
## Younger players (Band A, 6-8) may not read the dialogue yet, so every line is
## spoken. A line with a recorded clip in VoLibrary plays that clip (Wonder Light
## and David each have their own voice); a block with any line that has no clip
## is spoken with the operating system's text-to-speech voice instead. A beat
## with a clip in vo_clips takes priority over both.

func _init_tts() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var ids := DisplayServer.tts_get_voices_for_language("en")
	if ids.is_empty():
		for voice in DisplayServer.tts_get_voices():
			ids.append(voice["id"])
	_voices = ids

func is_read_aloud_available() -> bool:
	return _has_clips or not _voices.is_empty()

func is_read_aloud_enabled() -> bool:
	return is_read_aloud_available() and GameSettings.read_aloud

func set_read_aloud(enabled: bool) -> void:
	GameSettings.read_aloud = enabled
	GameSettings.save_settings()
	if not enabled:
		stop_speech()
	read_aloud_changed.emit(enabled)

## Cuts off whatever is being read aloud, clips and system speech alike.
func stop_speech() -> void:
	_clip_run += 1
	_clip_queue.clear()
	_suppress_finish = true
	if _speaking_clips:
		_speaking_clips = false
		_vo_player.stop()
	_suppress_finish = false
	if not _voices.is_empty():
		DisplayServer.tts_stop()


## Speaks one recorded line, cutting off whatever was playing. Used when the
## child taps a single word. Does nothing if that line has no clip.
func play_line(text: String) -> void:
	if not is_read_aloud_enabled():
		return
	var clip := VoLibrary.clip_for(text)
	if clip == null:
		return
	stop_speech()
	_speaking_clips = true
	_vo_player.stream = clip
	_vo_player.play()

## Speaks a dialogue block ("Speaker: \"line\"" per line; "(...)" lines are stage
## directions and stay silent). Interrupts whatever was being spoken, so pressing
## Space quickly cuts the old line and starts the new one.
func speak_dialogue(text: String) -> void:
	if not is_read_aloud_enabled():
		return
	if _vo_active and _vo_player.playing and not _speaking_clips:
		return
	stop_speech()
	var lines := _spoken_lines(text)
	var clips: Array[AudioStream] = []
	for line in lines:
		var clip := VoLibrary.clip_for(line["text"])
		if clip == null:
			clips.clear()
			break
		clips.append(clip)
	if not clips.is_empty():
		_clip_queue = clips
		_play_next_clip()
	else:
		_speak_with_tts(lines)

func _play_next_clip() -> void:
	if _clip_queue.is_empty():
		_speaking_clips = false
		return
	_speaking_clips = true
	_vo_player.stream = _clip_queue.pop_front()
	_vo_player.play()

func _on_vo_finished() -> void:
	if _suppress_finish:
		return
	if not _speaking_clips or _clip_queue.is_empty():
		_speaking_clips = false
		speech_finished.emit()
		return
	var run := _clip_run
	await get_tree().create_timer(CLIP_GAP).timeout
	if run == _clip_run:
		_play_next_clip()

## Splits a dialogue block into spoken lines: {"speaker", "text"}. A line with no
## speaker of its own (the verse itself, "Don't. Be. Afraid.") keeps the previous one.
func _spoken_lines(text: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var speaker := "Reader"
	for raw in text.split("\n", false):
		var line := raw.strip_edges()
		if line.is_empty() or line.begins_with("("):
			continue
		if line.begins_with("Wonder Light:"):
			line = line.substr(13)
			speaker = "Wonder Light"
		elif line.begins_with("David:"):
			line = line.substr(6)
			speaker = "David"
		elif line.begins_with("Jonathan:"):
			line = line.substr(10)
			speaker = "Jonathan"
		elif line.begins_with("Joshua 1:9"):
			line = "Joshua, chapter one, verse nine."
			speaker = "Reader"
		elif line.begins_with("1 Samuel 18:1"):
			line = "First Samuel, chapter eighteen, verse one."
			speaker = "Reader"
		line = line.replace("\"", "").strip_edges()
		if not line.is_empty():
			out.append({"speaker": speaker, "text": line})
	return out

## Fallback: the operating system's voices. David gets a second English voice
## when the machine has one; otherwise the two are told apart by pitch alone.
func _speak_with_tts(lines: Array[Dictionary]) -> void:
	if _voices.is_empty():
		return
	for line in lines:
		var voice: String = _voices[0]
		var pitch := 1.0
		match line["speaker"]:
			"Wonder Light":
				pitch = 1.35
			"David":
				voice = _voices[1] if _voices.size() > 1 else _voices[0]
				pitch = 0.9
		DisplayServer.tts_speak(line["text"], voice, 90, pitch, 0.95, 0, false)
