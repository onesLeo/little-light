extends RefCounted
## Player settings persisted to user://settings.cfg.
## Use through a preload constant (no class_name, so it works before the
## editor has built its global class cache):
##   const GameSettings := preload("res://scripts/game_settings.gd")

const PATH := "user://settings.cfg"

static var read_aloud: bool = true
static var master_volume: float = 1.0
static var music_volume: float = 1.0
static var sounds_volume: float = 1.0
static var voice_volume: float = 1.0
static var _loaded: bool = false


static func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		read_aloud = bool(cfg.get_value("audio", "read_aloud", true))
		master_volume = clampf(float(cfg.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)
		music_volume = clampf(float(cfg.get_value("audio", "music_volume", 1.0)), 0.0, 1.0)
		sounds_volume = clampf(float(cfg.get_value("audio", "sounds_volume", 1.0)), 0.0, 1.0)
		voice_volume = clampf(float(cfg.get_value("audio", "voice_volume", 1.0)), 0.0, 1.0)
	apply_volume()


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "read_aloud", read_aloud)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sounds_volume", sounds_volume)
	cfg.set_value("audio", "voice_volume", voice_volume)
	cfg.save(PATH)


static func apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
