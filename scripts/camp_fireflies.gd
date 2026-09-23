extends Node3D
## Six to eight fireflies over the grass at the edge of the clearing: the night
## version of the meadow's butterflies. Tiny warm dots, dimmer than the lantern,
## that do not light the ground. Walk toward one and it lifts aside, then
## settles again. They make no sound.

const Paper := preload("res://scripts/camp_paper.gd")

## Where each firefly lives, in world space. Set before the node enters the tree.
var homes: Array[Vector3] = []
var player: Node3D

var _flies: Array[Node3D] = []
var _offsets: Array[Vector3] = []
var _seeds: Array[float] = []
var _time: float = 0.0


func _ready() -> void:
	visible = false
	for i in homes.size():
		var fly := Node3D.new()
		fly.name = "Firefly%d" % i
		add_child(fly)
		var dot := MeshInstance3D.new()
		dot.mesh = Paper.sphere(0.028, 6)
		dot.material_override = Paper.glow_mat(Color(1.0, 0.93, 0.55))
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fly.add_child(dot)
		var halo := Paper.halo(0.34, Color(1.0, 0.82, 0.35))
		fly.add_child(halo)
		fly.global_position = homes[i]
		_flies.append(fly)
		_offsets.append(Vector3.ZERO)
		_seeds.append(randf() * 100.0)


func light_up() -> void:
	visible = true


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	for i in _flies.size():
		var s := _seeds[i]
		var drift := Vector3(
			sin(_time * 0.37 + s) * 0.55 + sin(_time * 0.91 + s * 1.7) * 0.18,
			sin(_time * 0.53 + s * 2.3) * 0.22,
			cos(_time * 0.29 + s * 0.6) * 0.55 + sin(_time * 0.77 + s) * 0.15)
		var base := homes[i] + drift
		var away := Vector3.ZERO
		if player:
			var d := base - player.global_position
			d.y = 0.0
			var dist := d.length()
			if dist < 1.8:
				away = (d / maxf(dist, 0.01)) * (1.8 - dist) * 1.1 + Vector3(0.0, (1.8 - dist) * 0.5, 0.0)
		_offsets[i] = _offsets[i].lerp(away, minf(1.0, delta * 2.0))
		_flies[i].global_position = base + _offsets[i]
		# A slow glow and fade, each on its own clock.
		var glow := 0.55 + 0.45 * sin(_time * 1.3 + s * 3.1)
		_flies[i].scale = Vector3.ONE * (0.6 + 0.4 * glow)
