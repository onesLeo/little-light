extends Node
## Central SFX + VO hookup point for the P0.2 slice.
##
## SFX are tiny procedural chimes (see chime_synth.gd) so pickup / Steady
## Hands feedback is audible right now with zero external audio files.
## Swap _stream_* below for imported .wav/.ogg resources whenever real SFX
## are ready — callers (play_pickup/play_tap/play_success) don't change.
##
## VO is an intentional stub, matching this slice's existing "narration as
## text, not audio" placeholder pattern (see Courage charm / Faith Journal
## in chapter_director.gd): assign real clips into vo_clips keyed by
## ChapterDirector.Beat name (e.g. "ARRIVE") and they'll play automatically;
## beats with no clip stay silent.

const ChimeSynth := preload("res://scripts/chime_synth.gd")
const GameSettings := preload("res://scripts/game_settings.gd")

## Emitted when read-aloud is switched on or off.
signal read_aloud_changed(enabled: bool)

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

func _ready() -> void:
	_stream_pickup = ChimeSynth.build_chime([880.0, 1318.5], 0.16)
	_stream_tap = ChimeSynth.build_chime([440.0], 0.08)
	_stream_success = ChimeSynth.build_chime([523.25, 659.25, 783.99], 0.4)
	_stream_fanfare = ChimeSynth.build_fanfare()
	_stream_cheer = ChimeSynth.build_cheer()
	GameSettings.load_settings()
	_init_tts()

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


## -- Read-aloud (system text-to-speech) -------------------------------------
## Younger players (Band A, 6-8) may not read the dialogue yet, so every line
## is spoken with the operating system's voices until real recorded VO exists.
## A beat with a clip in vo_clips uses that instead. Wonder Light and David get
## different voices/pitches when the system has two English voices.

func _init_tts() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var ids := DisplayServer.tts_get_voices_for_language("en")
	if ids.is_empty():
		for voice in DisplayServer.tts_get_voices():
			ids.append(voice["id"])
	_voices = ids

func is_read_aloud_available() -> bool:
	return not _voices.is_empty()

func is_read_aloud_enabled() -> bool:
	return is_read_aloud_available() and GameSettings.read_aloud

func set_read_aloud(enabled: bool) -> void:
	GameSettings.read_aloud = enabled
	GameSettings.save_settings()
	if not enabled:
		stop_speech()
	read_aloud_changed.emit(enabled)

func stop_speech() -> void:
	if is_read_aloud_available():
		DisplayServer.tts_stop()

## Speaks a dialogue block ("Speaker: \"line\"" per line; "(...)" lines are stage
## directions and stay silent). Interrupts whatever was being spoken.
func speak_dialogue(text: String) -> void:
	if not is_read_aloud_enabled():
		return
	if _vo_active and _vo_player.playing:
		return
	DisplayServer.tts_stop()
	var voice: String = _voices[0]
	var pitch := 1.0
	for raw in text.split("
", false):
		var line := raw.strip_edges()
		if line.is_empty() or line.begins_with("("):
			continue
		if line.begins_with("Wonder Light:"):
			line = line.substr(13)
			voice = _voices[0]
			pitch = 1.35
		elif line.begins_with("David:"):
			line = line.substr(6)
			voice = _voices[1] if _voices.size() > 1 else _voices[0]
			pitch = 0.9
		elif line.begins_with("Joshua 1:9"):
			line = "Joshua, chapter one, verse nine."
			voice = _voices[0]
			pitch = 1.0
		line = line.replace("\"", "").strip_edges()
		if line.is_empty():
			continue
		DisplayServer.tts_speak(line, voice, 90, pitch, 0.95, 0, false)
