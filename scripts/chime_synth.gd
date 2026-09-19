extends RefCounted
## Builds tiny procedural chime tones at runtime so Steady Hands / pickup
## SFX are audible with zero external audio files in the project. Swap
## AudioDirector's cached streams for imported .wav/.ogg resources later —
## nothing else needs to change, callers only see an AudioStream.

const MIX_RATE := 22050

## frequencies_hz plays back-to-back as equal-length notes across
## duration_seconds, each shaped by a click-free half-sine envelope.
static func build_chime(frequencies_hz: Array, duration_seconds: float) -> AudioStreamWAV:
	var total_frames := int(MIX_RATE * duration_seconds)
	var note_count := maxi(frequencies_hz.size(), 1)
	var note_frames := maxi(total_frames / note_count, 1)

	var data := PackedByteArray()
	data.resize(total_frames * 2) # 16-bit mono

	for i in total_frames:
		var note_index := mini(i / note_frames, note_count - 1)
		var freq: float = frequencies_hz[note_index]
		var note_t := float(i % note_frames) / float(note_frames)
		var envelope := sin(PI * note_t) # 0 -> 1 -> 0 across each note, no clicks
		var sample := sin(TAU * freq * (float(i) / MIX_RATE)) * envelope
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


## Bright rising arpeggio that lands on a held major chord: the "you did it" sting.
static func build_fanfare() -> AudioStreamWAV:
	var total := 2.0
	var buf := PackedFloat32Array()
	buf.resize(int(MIX_RATE * total))
	var arpeggio := [523.25, 659.25, 783.99, 1046.5]
	for n in arpeggio.size():
		_add_note(buf, arpeggio[n], float(n) * 0.13, 0.55, 0.32)
	for f in [523.25, 659.25, 783.99, 1046.5]:
		_add_note(buf, f, 0.55, 1.4, 0.24)
	_add_note(buf, 2093.0, 0.55, 0.9, 0.08)
	return _to_wav(buf)


## Synthesised applause: many tiny noise "claps" under a swell-and-fade envelope,
## plus a couple of rising whoops so it reads as cheering, not static.
static func build_cheer(duration_seconds: float = 2.4) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var buf := PackedFloat32Array()
	buf.resize(int(MIX_RATE * duration_seconds))
	var clap_len := int(MIX_RATE * 0.03)
	for _c in int(duration_seconds * 55.0):
		var start := rng.randi_range(0, buf.size() - clap_len - 1)
		var t_norm := float(start) / float(buf.size())
		var swell := sin(PI * clampf(t_norm * 1.15, 0.0, 1.0))
		var amp := rng.randf_range(0.25, 0.7) * swell * 0.55
		var lp := 0.0
		for i in clap_len:
			lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.55)
			buf[start + i] += lp * amp * exp(-float(i) / (clap_len * 0.28))
	for w in 3:
		_add_whoop(buf, rng.randf_range(0.15, 0.7) * duration_seconds, rng.randf_range(420.0, 620.0))
	return _to_wav(buf)


static func _add_note(buf: PackedFloat32Array, freq: float, start_s: float, length_s: float, amp: float) -> void:
	var first := int(start_s * MIX_RATE)
	var count := mini(int(length_s * MIX_RATE), buf.size() - first)
	for i in count:
		var t := float(i) / MIX_RATE
		var env := minf(t / 0.008, 1.0) * exp(-3.2 * t / length_s)
		var ph := TAU * freq * t
		buf[first + i] += (sin(ph) + 0.3 * sin(2.0 * ph) + 0.12 * sin(3.0 * ph)) * env * amp


static func _add_whoop(buf: PackedFloat32Array, start_s: float, base_hz: float) -> void:
	var first := int(start_s * MIX_RATE)
	var length := int(0.32 * MIX_RATE)
	var phase := 0.0
	for i in mini(length, buf.size() - first):
		var t := float(i) / float(length)
		phase += TAU * (base_hz * (1.0 + 0.9 * t)) / MIX_RATE
		buf[first + i] += sin(phase) * sin(PI * t) * 0.05


static func _to_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var peak := 0.001
	for v in buf:
		peak = maxf(peak, absf(v))
	var gain := minf(0.9 / peak, 1.0) if peak > 0.9 else 1.0
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i] * gain, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
