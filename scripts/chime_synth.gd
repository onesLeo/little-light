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
