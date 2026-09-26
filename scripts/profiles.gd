extends RefCounted
## The children who play on this tablet, and what each has earned in the Faith Journal.
## Saved to user://profiles.cfg, on the tablet only: no accounts, nothing goes online.
## Use through a preload constant (no class_name, so it works before the editor has built its
## global class cache):
##   const Profiles := preload("res://scripts/profiles.gd")
##
## A profile is a Dictionary:
##   id, name, avatar (one of AVATAR_KINDS), verses (ids), charms (ids), chapters (times finished),
##   finished (the chapter ids they have finished at least once, see CHAPTERS),
##   opened_early (chapters their save had open before The Beginning came before them, see is_unlocked),
##   settings (that child's read-aloud and volume choices; empty means "as the tablet has them"),
##   colours (charm id -> the paints they chose for its regions, see charm_art.gd),
##   places (chapter id -> where they got to in a chapter not finished yet: {"beat": name, and
##   whatever else that story needs to set the scene again}, see mark_place).

const CharmArt := preload("res://scripts/charm_art.gd")

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
## The chapter the story is on: "" (none yet, so the Faith Journey map comes first), or one of
## CHAPTERS. Like active_id it outlives a scene reload, so "Play again" replays this chapter.
static var current_chapter: String = ""

## The chapters in the order they are played. Each one opens once the one before it is finished.
## The Beginning (Samuel anoints David) is a look back, played after the camp and before the ark.
const CHAPTER_VALLEY := "valley"
const CHAPTER_CAMP := "camp"
const CHAPTER_BEGINNING := "beginning"
const CHAPTER_ARK := "ark"
const CHAPTERS := [CHAPTER_VALLEY, CHAPTER_CAMP, CHAPTER_BEGINNING, CHAPTER_ARK]
## The order before The Beginning was added. A save written then has no "opened_early" entry; the
## chapters it had open are worked out from this order when it is loaded, so none closes again.
const CHAPTERS_BEFORE_BEGINNING := [CHAPTER_VALLEY, CHAPTER_CAMP, CHAPTER_ARK]

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
		var finished := _finished_list(cfg.get_value(section, "finished", null), int(cfg.get_value(section, "chapters", 0)))
		var early: Array = _strings(cfg.get_value(section, "opened_early", [])).filter(func(c: String) -> bool: return c in CHAPTERS) \
				if cfg.has_section_key(section, "opened_early") else _opened_before_beginning(finished)
		_profiles[str(id)] = {
			"id": str(id),
			"name": clean_name(str(cfg.get_value(section, "name", ""))),
			"avatar": avatar if avatar in AVATAR_KINDS else AVATAR_KINDS[0],
			"verses": _strings(cfg.get_value(section, "verses", [])),
			"charms": _strings(cfg.get_value(section, "charms", [])),
			"chapters": maxi(int(cfg.get_value(section, "chapters", 0)), 0),
			"finished": finished,
			"opened_early": early,
			"settings": cfg.get_value(section, "settings", {}) if cfg.get_value(section, "settings", {}) is Dictionary else {},
			"colours": _colour_lists(cfg.get_value(section, "colours", {})),
			"places": _places(cfg.get_value(section, "places", {})),
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
		cfg.set_value(section, "finished", p["finished"])
		cfg.set_value(section, "opened_early", p["opened_early"])
		cfg.set_value(section, "settings", p["settings"])
		cfg.set_value(section, "colours", p["colours"])
		cfg.set_value(section, "places", p["places"])
	cfg.save(path)


## A saved "places" value made safe: chapter id -> a Dictionary with a String "beat".
static func _places(values: Variant) -> Dictionary:
	var out := {}
	if not values is Dictionary:
		return out
	for chapter_id in values:
		var place: Variant = values[chapter_id]
		if str(chapter_id) in CHAPTERS and place is Dictionary and (place as Dictionary).get("beat") is String:
			out[str(chapter_id)] = (place as Dictionary).duplicate(true)
	return out


## A saved "colours" value made safe: charm id -> list of paint numbers (-1 for none), nothing else.
static func _colour_lists(values: Variant) -> Dictionary:
	var out: Dictionary = {}
	if values is Dictionary:
		for charm_id in values:
			if not (values[charm_id] is Array):
				continue
			var list: Array = []
			for n in (values[charm_id] as Array).slice(0, 16):
				list.append(clampi(int(n), -1, CharmArt.PALETTE.size() - 1))
			out[str(charm_id)] = list
	return out


## A saved "finished" list made safe. Saves from before chapters were told apart only have a count:
## any finished chapter then was the valley, since it came first.
static func _finished_list(values: Variant, times: int) -> Array:
	if values is Array:
		return _strings(values).filter(func(id: String) -> bool: return id in CHAPTERS)
	return [CHAPTER_VALLEY] if times > 0 else []


## What a save from before The Beginning had open, in the order it had then, and has open no
## longer by the new order: the ark, once the camp was finished.
static func _opened_before_beginning(finished: Array) -> Array:
	var early: Array = []
	for i in range(1, CHAPTERS_BEFORE_BEGINNING.size()):
		var chapter_id: String = CHAPTERS_BEFORE_BEGINNING[i]
		var before: String = CHAPTERS[CHAPTERS.find(chapter_id) - 1]
		if finished.has(CHAPTERS_BEFORE_BEGINNING[i - 1]) and not finished.has(before):
			early.append(chapter_id)
	return early


static func _strings(values: Variant) -> Array:
	var out: Array = []
	if values is Array:
		for v in values:
			if not out.has(str(v)):
				out.append(str(v))
	return out


## Words a child's name may not be or contain. Kept short on purpose: a long list turns away real names,
## so this only stops the plain cases (see name_allowed).
const BLOCKED_INSIDE := ["fuck", "shit", "bitch", "cunt", "whore", "slut", "porn", "nazi", "hitler", "bastard", "asshole", "penis", "vagina"]
const BLOCKED_EXACT := ["sex", "ass", "arse", "piss", "cock", "tit", "tits", "poo", "poop", "butt", "crap"]


## False for a name that is a rude word: letters only, capitals and look-alike digits ignored ("sh1t" counts).
## Whole-name matches only for the short words, so names such as Cassie or Dickson are never turned away.
static func name_allowed(raw: String) -> bool:
	var plain := ""
	for ch in clean_name(raw).to_lower():
		match ch:
			"0":
				plain += "o"
			"1", "!":
				plain += "i"
			"3":
				plain += "e"
			"4", "@":
				plain += "a"
			"5", "$":
				plain += "s"
			_:
				if ch >= "a" and ch <= "z":
					plain += ch
	if plain in BLOCKED_EXACT:
		return false
	for word in BLOCKED_INSIDE:
		if plain.contains(word):
			return false
	return true


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
	if cleaned.is_empty() or not name_allowed(cleaned) or not can_add():
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
		"finished": [],
		"opened_early": [],
		"settings": {},
		"colours": {},
		"places": {},
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


## The paints a child chose for a charm: one number per region of its picture, -1 for a region they
## have not coloured. Always as long as the picture has regions.
static func charm_colours(id: String, charm_id: String) -> Array:
	var saved: Array = get_profile(id).get("colours", {}).get(charm_id, [])
	var list: Array = []
	for i in CharmArt.region_count(charm_id):
		list.append(int(saved[i]) if i < saved.size() else -1)
	return list


static func has_coloured_charm(id: String, charm_id: String) -> bool:
	return charm_colours(id, charm_id).any(func(n: int) -> bool: return n >= 0)


static func set_charm_colours(id: String, charm_id: String, colours: Array) -> void:
	var p := get_profile(id)
	if p.is_empty() or not (p["charms"] as Array).has(charm_id):
		return
	p["colours"][charm_id] = colours.duplicate()
	save()


## Counts a finished chapter for the child playing and remembers which one it was.
static func finish_chapter(chapter_id: String = CHAPTER_VALLEY) -> void:
	var p := active()
	if p.is_empty():
		return
	p["chapters"] = int(p["chapters"]) + 1
	if chapter_id in CHAPTERS and not (p["finished"] as Array).has(chapter_id):
		(p["finished"] as Array).append(chapter_id)
	(p["places"] as Dictionary).erase(chapter_id)
	save()


## Remembers where the child playing got to in `chapter_id` (a story's major beat, and anything
## else it needs to set the scene again), so it carries on from there next time, even after the
## tablet has closed the game. Finishing the chapter, or starting it again, forgets it.
static func mark_place(chapter_id: String, beat: String, extra: Dictionary = {}) -> void:
	var p := active()
	if p.is_empty() or not chapter_id in CHAPTERS:
		return
	var place := extra.duplicate(true)
	place["beat"] = beat
	p["places"][chapter_id] = place
	save()


## Where child `id` got to in `chapter_id`, or {} to start it from the beginning.
static func place_in(id: String, chapter_id: String) -> Dictionary:
	return (get_profile(id).get("places", {}) as Dictionary).get(chapter_id, {})


static func forget_place(chapter_id: String) -> void:
	var p := active()
	if p.is_empty() or not (p["places"] as Dictionary).has(chapter_id):
		return
	(p["places"] as Dictionary).erase(chapter_id)
	save()


static func has_finished(id: String, chapter_id: String) -> bool:
	return get_profile(id).get("finished", []).has(chapter_id)


## A chapter opens once the one before it is finished. The first is always open.
## Open when the chapter before it is finished. A chapter the child has finished stays open, and so
## does one their save had open before The Beginning was put ahead of it (the ark after the camp).
static func is_unlocked(id: String, chapter_id: String) -> bool:
	var at := CHAPTERS.find(chapter_id)
	if at <= 0:
		return at == 0
	return has_finished(id, CHAPTERS[at - 1]) or has_finished(id, chapter_id) \
			or (get_profile(id).get("opened_early", []) as Array).has(chapter_id)


## The first chapter this child has not finished yet, or "" when every chapter is done.
static func next_chapter(id: String) -> String:
	for chapter_id in CHAPTERS:
		if not has_finished(id, chapter_id):
			return chapter_id
	return ""


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
	p["colours"] = {}
	p["chapters"] = 0
	p["finished"] = []
	p["places"] = {}
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
