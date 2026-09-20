extends RefCounted
## Where the synthesized sounds live and how to load them. The files are
## rendered by tools/make_sounds.py (see docs/sound-design.md). Use through a
## preload constant, like GameSettings.

const DIR := "res://assets/audio/"
const MUSIC := DIR + "music/meadow_lullaby.wav"
const WIND := DIR + "ambience/wind.wav"
const STREAM := DIR + "ambience/stream.wav"
const FLUTTER := DIR + "sfx/flutter.wav"
const BREATH := DIR + "sfx/breath_loop.wav"
const BIRD_COUNT := 7
const STEP_COUNT := 4
const BLEAT_COUNT := 1

static var _cache: Dictionary = {}


## A sound by path, or null when the file is missing. `looped` gives a copy that
## repeats seamlessly (the loop files are rendered to join up).
static func load_stream(path: String, looped: bool = false) -> AudioStream:
	var key := path + ("#loop" if looped else "")
	if _cache.has(key):
		return _cache[key]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
		if looped and stream is AudioStreamWAV:
			var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
			var bytes_per_sample := (2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1) * (2 if wav.stereo else 1)
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = wav.data.size() / bytes_per_sample
			stream = wav
	_cache[key] = stream
	return stream


static func bird(index: int) -> AudioStream:
	return load_stream(DIR + "ambience/bird_%d.wav" % (index % BIRD_COUNT + 1))


static func step(index: int) -> AudioStream:
	return load_stream(DIR + "sfx/step_%d.wav" % (index % STEP_COUNT + 1))


static func bleat(index: int) -> AudioStream:
	return load_stream(DIR + "sfx/bleat_%d.wav" % (index % BLEAT_COUNT + 1))


## Every file the game expects, for the smoke test.
static func all_paths() -> PackedStringArray:
	var paths := PackedStringArray([MUSIC, WIND, STREAM, FLUTTER, BREATH])
	for i in BIRD_COUNT:
		paths.append(DIR + "ambience/bird_%d.wav" % (i + 1))
	for i in STEP_COUNT:
		paths.append(DIR + "sfx/step_%d.wav" % (i + 1))
	for i in BLEAT_COUNT:
		paths.append(DIR + "sfx/bleat_%d.wav" % (i + 1))
	return paths
