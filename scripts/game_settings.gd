extends RefCounted
## Player settings persisted to user://settings.cfg, and, once a child is playing, kept for that child too
## (see profiles.gd): on a shared tablet each child gets their own read-aloud and volume.
## Use through a preload constant (no class_name, so it works before the
## editor has built its global class cache):
##   const GameSettings := preload("res://scripts/game_settings.gd")

const PATH := "user://settings.cfg"
const Profiles := preload("res://scripts/profiles.gd")

static var read_aloud: bool = true
## Show and read the story in easier words (a line's easy_text, dialogue_line.gd). Set from the age a child gives, and in the pause menu.
static var easy_words: bool = false
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
		easy_words = bool(cfg.get_value("story", "easy_words", false))
		master_volume = clampf(float(cfg.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)
		music_volume = clampf(float(cfg.get_value("audio", "music_volume", 1.0)), 0.0, 1.0)
		sounds_volume = clampf(float(cfg.get_value("audio", "sounds_volume", 1.0)), 0.0, 1.0)
		voice_volume = clampf(float(cfg.get_value("audio", "voice_volume", 1.0)), 0.0, 1.0)
	apply_volume()


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "read_aloud", read_aloud)
	cfg.set_value("story", "easy_words", easy_words)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sounds_volume", sounds_volume)
	cfg.set_value("audio", "voice_volume", voice_volume)
	cfg.save(PATH)
	Profiles.store_settings(as_dictionary())


## The choices that belong to one child: read-aloud, easy words and the volumes.
static func as_dictionary() -> Dictionary:
	return {
		"read_aloud": read_aloud,
		"easy_words": easy_words,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sounds_volume": sounds_volume,
		"voice_volume": voice_volume,
	}


## Takes on a child's saved choices. An empty dictionary (a new child) leaves things as the tablet has them.
static func apply_profile(settings: Dictionary) -> void:
	if settings.is_empty():
		return
	read_aloud = bool(settings.get("read_aloud", read_aloud))
	easy_words = bool(settings.get("easy_words", false))
	master_volume = clampf(float(settings.get("master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(settings.get("music_volume", music_volume)), 0.0, 1.0)
	sounds_volume = clampf(float(settings.get("sounds_volume", sounds_volume)), 0.0, 1.0)
	voice_volume = clampf(float(settings.get("voice_volume", voice_volume)), 0.0, 1.0)
	apply_volume()


static func apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
