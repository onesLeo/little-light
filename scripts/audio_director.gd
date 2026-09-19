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

@export var vo_clips: Dictionary = {}

@onready var _sfx_players: Array[AudioStreamPlayer] = [$SfxA, $SfxB, $SfxC]
@onready var _vo_player: AudioStreamPlayer = $Vo

var _stream_pickup: AudioStreamWAV
var _stream_tap: AudioStreamWAV
var _stream_success: AudioStreamWAV
var _stream_fanfare: AudioStreamWAV
var _stream_cheer: AudioStreamWAV
var _next_player: int = 0

func _ready() -> void:
	_stream_pickup = ChimeSynth.build_chime([880.0, 1318.5], 0.16)
	_stream_tap = ChimeSynth.build_chime([440.0], 0.08)
	_stream_success = ChimeSynth.build_chime([523.25, 659.25, 783.99], 0.4)
	_stream_fanfare = ChimeSynth.build_fanfare()
	_stream_cheer = ChimeSynth.build_cheer()

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
	if clip == null:
		return
	_vo_player.stream = clip
	_vo_player.play()

func _play_sfx(stream: AudioStreamWAV) -> void:
	var player := _sfx_players[_next_player]
	_next_player = (_next_player + 1) % _sfx_players.size()
	player.stream = stream
	player.play()
