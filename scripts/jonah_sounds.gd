extends Node
## Chapter 5's changing sound bed. Joppa has water, timber and distant harbour life; the ship
## crossfades into wind and rain as the sea rises; the deep is quiet; Nineveh has a soft,
## indistinct market murmur. All three use the Ambience bus, so dialogue ducks them automatically.

const SoundLibrary := preload("res://scripts/sound_library.gd")
const SoundBus := preload("res://scripts/sound_bus.gd")

@export var harbour_db: float = -13.0
@export var storm_db: float = -8.0
@export var market_db: float = -16.0
@export var fade_seconds: float = 1.8

var _harbour: AudioStreamPlayer
var _storm: AudioStreamPlayer
var _market: AudioStreamPlayer
var _place: String = ""
var _on: bool = false


func start() -> void:
	if _on:
		return
	_on = true
	SoundBus.ensure_buses()
	if _harbour == null:
		_harbour = _player(SoundLibrary.JONAH_HARBOUR)
		_storm = _player(SoundLibrary.JONAH_STORM)
		_market = _player(SoundLibrary.JONAH_MARKET)
	for player in [_harbour, _storm, _market]:
		if player.stream and not player.playing:
			player.play()
	_set_valley_ambience(false)


func stop() -> void:
	_on = false
	_place = ""
	for player in [_harbour, _storm, _market]:
		if player:
			player.volume_db = -80.0
			player.stop()
	_set_valley_ambience(true)


func _exit_tree() -> void:
	_set_valley_ambience(true)


func set_place(which: String) -> void:
	_place = which
	if not _on:
		start()


func is_playing() -> bool:
	return _on and (_harbour.playing or _storm.playing or _market.playing)


func _process(delta: float) -> void:
	if not _on or _harbour == null:
		return
	var sea_amount := 0.0
	var world := get_parent()
	if _place == "sea" and world and world.has_method("sea"):
		var sea_node: Node = world.sea()
		if sea_node and "storm" in sea_node:
			sea_amount = float(sea_node.storm)
	var harbour_gain := 1.0 if _place == "joppa" else 0.0
	# A little open-sea air remains before the storm reaches full strength.
	var storm_gain := (0.16 + sea_amount * 0.84) if _place == "sea" else 0.0
	var market_gain := 1.0 if _place == "land" else 0.0
	_fade(_harbour, harbour_db, harbour_gain, delta)
	_fade(_storm, storm_db, storm_gain, delta)
	_fade(_market, market_db, market_gain, delta)


func _player(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = SoundLibrary.load_stream(path, true)
	player.bus = SoundBus.AMBIENCE
	player.volume_db = -80.0
	add_child(player)
	return player


func _fade(player: AudioStreamPlayer, level_db: float, gain: float, delta: float) -> void:
	var target := -80.0 if gain <= 0.0001 else level_db + linear_to_db(gain)
	player.volume_db = move_toward(player.volume_db, target, delta * 80.0 / maxf(fade_seconds, 0.01))


## The shared meadow soundscape keeps the music, but yields its birds, wind and stream while this
## chapter supplies a location-specific ambience.
func _set_valley_ambience(on: bool) -> void:
	var main := get_parent().get_parent() if get_parent() else null
	var soundscape := main.get_node_or_null("Soundscape") if main else null
	if soundscape and soundscape.has_method("set_external_ambience"):
		soundscape.set_external_ambience(not on)
