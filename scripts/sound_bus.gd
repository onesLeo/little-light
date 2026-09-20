extends RefCounted
## Audio buses and the player's volume mix. Everything the game plays goes to one
## of four buses under Master, so the pause menu can balance them and the music
## can drop out of the way while somebody is speaking. Use through a preload
## constant, like GameSettings.

const GameSettings := preload("res://scripts/game_settings.gd")

const MUSIC := "Music"
const AMBIENCE := "Ambience"
const EFFECTS := "Effects"
const VOICE := "Voice"

## Balance of each bus before the player's sliders, in dB.
const BASE_DB := {MUSIC: -11.0, AMBIENCE: -7.0, EFFECTS: -2.0, VOICE: 3.0}
## How far the music and ambience drop while a voice is speaking, in dB.
const DUCK_DB := {MUSIC: -9.0, AMBIENCE: -10.0}

## 0 = nobody speaking, 1 = fully ducked. Driven by Soundscape.
static var duck: float = 0.0


static func ensure_buses() -> void:
	for bus_name in [MUSIC, AMBIENCE, EFFECTS, VOICE]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	# A limiter on Master so the louder voice plus a sound effect can never clip.
	for i in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, i) is AudioEffectLimiter:
			return
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, limiter)


## Pushes the saved volumes and the current ducking onto the buses.
static func apply_mix() -> void:
	ensure_buses()
	GameSettings.apply_volume()
	_set_bus(MUSIC, GameSettings.music_volume)
	_set_bus(AMBIENCE, GameSettings.sounds_volume)
	_set_bus(EFFECTS, GameSettings.sounds_volume)
	_set_bus(VOICE, GameSettings.voice_volume)


static func set_duck(amount: float) -> void:
	amount = clampf(amount, 0.0, 1.0)
	if is_equal_approx(amount, duck):
		return
	duck = amount
	apply_mix()


## The dB a bus should have for a slider position (0-1) and the current ducking.
static func bus_db(bus_name: String, slider: float) -> float:
	return float(BASE_DB[bus_name]) + linear_to_db(maxf(slider, 0.0001)) + float(DUCK_DB.get(bus_name, 0.0)) * duck


static func _set_bus(bus_name: String, slider: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, bus_db(bus_name, slider))
