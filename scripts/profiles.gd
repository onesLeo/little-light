extends RefCounted
## The children who play on this tablet, and what each has earned in the Faith Journal.
## Saved to user://profiles.cfg, on the tablet only: no accounts, nothing goes online.
## Use through a preload constant (no class_name, so it works before the editor has built its
## global class cache):
##   const Profiles := preload("res://scripts/profiles.gd")
##
## A profile is a Dictionary:
##   id, name, avatar (one of AVATAR_KINDS), verses (ids), charms (ids), chapters (times finished),
##   settings (that child's read-aloud and volume choices; empty means "as the tablet has them").

const DEFAULT_PATH := "user://profiles.cfg"
const MAX_PROFILES := 4
const MAX_NAME_LENGTH := 12
const AVATAR_KINDS := ["lamb", "star", "sun", "cloud", "heart", "olive"]

## Where profiles are saved. Change it with use_file(), not by assigning.
static var path: String = DEFAULT_PATH
## The child playing now, or "". It outlives a scene reload, so "Play again" keeps the same child and
## only a fresh start (or "Change player") shows the "Who is playing?" screen.
static var active_id: String = ""
## True while the "Who is playing?" screen is up, so the pause key leaves the game alone.
static var picker_open: bool = false

static var _profiles: Dictionary = {}
static var _order: Array = []
static var _next_number: int = 1
static var _loaded: bool = false


static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	_profiles.clear()
	_order.clear()
	_next_number = 1
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	_next_number = maxi(int(cfg.get_value("app", "next_number", 1)), 1)
	for id in cfg.get_value("app", "order", []):
		var section := "profile_" + str(id)
		if not cfg.has_section(section) or _profiles.has(str(id)):
			continue
		var avatar := str(cfg.get_value(section, "avatar", AVATAR_KINDS[0]))
		_profiles[str(id)] = {
			"id": str(id),
			"name": clean_name(str(cfg.get_value(section, "name", ""))),
			"avatar": avatar if avatar in AVATAR_KINDS else AVATAR_KINDS[0],
			"verses": _strings(cfg.get_value(section, "verses", [])),
			"charms": _strings(cfg.get_value(section, "charms", [])),
			"chapters": maxi(int(cfg.get_value(section, "chapters", 0)), 0),
			"settings": cfg.get_value(section, "settings", {}) if cfg.get_value(section, "settings", {}) is Dictionary else {},
		}
		_order.append(str(id))
	if count() > MAX_PROFILES:
		_order.resize(MAX_PROFILES)


## Points the profiles at another file (the smoke test uses a scratch one) and reads it. Set the path
## through this and not by assigning `path`: Godot re-runs a script's static initialisers on the first
## call of any of its static functions, which would put the default path back.
static func use_file(new_path: String) -> void:
	path = new_path
	_loaded = false
	active_id = ""
	load_all()


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("app", "next_number", _next_number)
	cfg.set_value("app", "order", _order.duplicate())
	for id in _order:
		var p: Dictionary = _profiles[id]
		var section := "profile_" + str(id)
		cfg.set_value(section, "name", p["name"])
		cfg.set_value(section, "avatar", p["avatar"])
		cfg.set_value(section, "verses", p["verses"])
		cfg.set_value(section, "charms", p["charms"])
		cfg.set_value(section, "chapters", p["chapters"])
		cfg.set_value(section, "settings", p["settings"])
	cfg.save(path)


static func _strings(values: Variant) -> Array:
	var out: Array = []
	if values is Array:
		for v in values:
			if not out.has(str(v)):
				out.append(str(v))
	return out


## A name as it will be kept: trimmed, and no longer than MAX_NAME_LENGTH letters.
static func clean_name(raw: String) -> String:
	return raw.strip_edges().substr(0, MAX_NAME_LENGTH).strip_edges()


# ---- who is there -----------------------------------------------------------------------------------

static func count() -> int:
	load_all()
	return _order.size()


static func can_add() -> bool:
	return count() < MAX_PROFILES


## The profiles in the order they were made.
static func all() -> Array:
	load_all()
	var out: Array = []
	for id in _order:
		out.append(_profiles[id])
	return out


static func get_profile(id: String) -> Dictionary:
	load_all()
	return _profiles.get(id, {})


static func active() -> Dictionary:
	return get_profile(active_id)


## Makes a profile and returns its id, or "" when the name is empty or the tablet already has
## MAX_PROFILES children.
static func create(display_name: String, avatar: String) -> String:
	load_all()
	var cleaned := clean_name(display_name)
	if cleaned.is_empty() or not can_add():
		return ""
	var id := "p%d" % _next_number
	_next_number += 1
	_profiles[id] = {
		"id": id,
		"name": cleaned,
		"avatar": avatar if avatar in AVATAR_KINDS else AVATAR_KINDS[0],
		"verses": [],
		"charms": [],
		"chapters": 0,
		"settings": {},
	}
	_order.append(id)
	save()
	return id


## Chooses who is playing. An id that does not exist means nobody.
static func set_active(id: String) -> void:
	load_all()
	active_id = id if _profiles.has(id) else ""


# ---- what they have earned --------------------------------------------------------------------------

static func has_verse(id: String, verse_id: String) -> bool:
	return get_profile(id).get("verses", []).has(verse_id)


static func has_charm(id: String, charm_id: String) -> bool:
	return get_profile(id).get("charms", []).has(charm_id)


## Adds a verse to the playing child's journal. True when it was new; false when they already had
## it, or nobody is playing.
static func unlock_verse(verse_id: String) -> bool:
	return _unlock("verses", verse_id)


static func unlock_charm(charm_id: String) -> bool:
	return _unlock("charms", charm_id)


static func _unlock(key: String, item_id: String) -> bool:
	var p := active()
	if p.is_empty() or (p[key] as Array).has(item_id):
		return false
	(p[key] as Array).append(item_id)
	save()
	return true


static func finish_chapter() -> void:
	var p := active()
	if p.is_empty():
		return
	p["chapters"] = int(p["chapters"]) + 1
	save()


## Keeps the read-aloud and volume choices of the child playing now.
static func store_settings(settings: Dictionary) -> void:
	var p := active()
	if p.is_empty():
		return
	p["settings"] = settings.duplicate()
	save()


# ---- grown-ups --------------------------------------------------------------------------------------

## Empties one child's journal but keeps them on the tablet.
static func erase_progress(id: String) -> void:
	var p := get_profile(id)
	if p.is_empty():
		return
	p["verses"] = []
	p["charms"] = []
	p["chapters"] = 0
	save()


## Takes a child off the tablet altogether.
static func remove(id: String) -> void:
	load_all()
	if not _profiles.has(id):
		return
	_profiles.erase(id)
	_order.erase(id)
	if active_id == id:
		active_id = ""
	save()
