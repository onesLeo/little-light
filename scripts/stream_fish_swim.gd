extends Node3D
const GameShell := preload("res://scripts/game_shell.gd")
## Smooth, slow-swimming fish for the alive brook.
## The pack's baked fish are faceted and shoot along the stream at ~5 m/s, so
## they are hidden and replaced by these: soft ellipsoid bodies with a wagging
## tail that patrol back and forth along the river's centre line.

const FISH := [
	{"color": Color(0.95, 0.78, 0.25), "from": 0.05, "to": 0.55, "speed": 0.55, "lane": -0.18, "phase": 0.0},
	{"color": Color(0.95, 0.55, 0.18), "from": 0.30, "to": 0.90, "speed": 0.45, "lane": 0.20, "phase": 2.1},
	{"color": Color(0.35, 0.60, 0.90), "from": 0.45, "to": 0.98, "speed": 0.62, "lane": 0.0, "phase": 4.3},
]
const OUTLINE := Color(0.08, 0.06, 0.05)

@export var art_path: NodePath = ^"../StreamFishAlive/Art"
@export var water_name: String = "Stream_Water"
@export var river_z_min: float = -4.2
@export var lift: float = 0.09
## Who the fish shy away from; empty means the shell's Wonder-Walker.
@export var player_path: NodePath = ^""
## A fish this close to the Wonder-Walker gets shy: it turns away and darts off.
@export var scare_radius: float = 2.3
@export var scare_speed_mul: float = 4.5

var _player: Node3D

var _path: Array[Vector3] = []
var _widths: Array[float] = []
var _lengths: Array[float] = []
var _total: float = 0.0
var _fish: Array[Dictionary] = []
var _time: float = 0.0


func _ready() -> void:
	call_deferred("_setup")


func _setup() -> void:
	var art := get_node_or_null(art_path) as Node3D
	if art == null:
		return
	var from_shell := player_path.is_empty()
	_player = (GameShell.of(self).get_node_or_null("Player") if from_shell else get_node_or_null(player_path)) as Node3D
	for n in art.find_children("Fish_*", "Node3D", true, false):
		(n as Node3D).visible = false
	var water := art.find_child(water_name, true, false) as MeshInstance3D
	if water == null or not _build_path(water):
		return
	for spec in FISH:
		_fish.append(_make_fish(spec))


func _build_path(water: MeshInstance3D) -> bool:
	var xf := water.global_transform
	var pts: Array[Vector3] = []
	for v in water.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		var w: Vector3 = xf * v
		if w.y < 0.6 and w.z > river_z_min:
			pts.append(w)
	if pts.size() < 8:
		return false
	var z_lo := INF
	var z_hi := -INF
	for p in pts:
		z_lo = minf(z_lo, p.z)
		z_hi = maxf(z_hi, p.z)
	var step := 0.6
	var z := z_lo + step * 0.5
	while z < z_hi:
		var sx := 0.0
		var sy := 0.0
		var lo := INF
		var hi := -INF
		var n := 0
		for p in pts:
			if absf(p.z - z) <= step * 0.6:
				sx += p.x
				sy += p.y
				lo = minf(lo, p.x)
				hi = maxf(hi, p.x)
				n += 1
		if n > 0:
			_path.append(Vector3(sx / n, sy / n, z))
			_widths.append(hi - lo)
		z += step
	if _path.size() < 3:
		return false
	_lengths.append(0.0)
	for i in range(1, _path.size()):
		_total += _path[i].distance_to(_path[i - 1])
		_lengths.append(_total)
	return true


func _point_at(s: float) -> Dictionary:
	s = clampf(s, 0.0, _total)
	for i in range(1, _path.size()):
		if s <= _lengths[i]:
			var t: float = (s - _lengths[i - 1]) / maxf(_lengths[i] - _lengths[i - 1], 0.0001)
			var p: Vector3 = _path[i - 1].lerp(_path[i], t)
			var dir: Vector3 = (_path[i] - _path[i - 1]).normalized()
			return {"pos": p, "dir": dir, "width": lerpf(_widths[i - 1], _widths[i], t)}
	return {"pos": _path[_path.size() - 1], "dir": Vector3(0, 0, 1), "width": _widths[_widths.size() - 1]}


func _soft_mesh(color: Color, scale_v: Vector3, pos: Vector3, parent: Node3D, outline := true) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	var mi := MeshInstance3D.new()
	mi.mesh = sphere
	mi.scale = scale_v
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	if outline:
		var hull := MeshInstance3D.new()
		hull.mesh = sphere
		hull.scale = Vector3.ONE * 1.12
		var omat := StandardMaterial3D.new()
		omat.albedo_color = OUTLINE
		omat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		omat.cull_mode = BaseMaterial3D.CULL_FRONT
		hull.material_override = omat
		hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(hull)
	return mi


func _make_fish(spec: Dictionary) -> Dictionary:
	var root := Node3D.new()
	root.name = "SmoothFish%d" % _fish.size()
	add_child(root)
	var col: Color = spec["color"]
	# Forward is -Z.
	_soft_mesh(col, Vector3(0.085, 0.115, 0.27), Vector3.ZERO, root)
	_soft_mesh(col.darkened(0.08), Vector3(0.014, 0.075, 0.10), Vector3(0.0, 0.11, 0.02), root)
	for side in [-1.0, 1.0]:
		_soft_mesh(Color(0.05, 0.04, 0.04), Vector3(0.022, 0.022, 0.022), Vector3(side * 0.062, 0.03, -0.17), root, false)
	var tail := Node3D.new()
	tail.position = Vector3(0.0, 0.0, 0.25)
	root.add_child(tail)
	_soft_mesh(col.darkened(0.05), Vector3(0.016, 0.13, 0.11), Vector3(0.0, 0.0, 0.09), tail)
	return {"root": root, "tail": tail, "spec": spec, "yaw": 0.0,
			"t": float(spec["phase"]), "sign": 1.0, "mul": 1.0, "flip_cd": 0.0}


func _process(delta: float) -> void:
	if _fish.is_empty():
		return
	_time += delta
	for f in _fish:
		var spec: Dictionary = f["spec"]
		var a: float = spec["from"] * _total
		var b: float = spec["to"] * _total
		var span := maxf(b - a, 0.1)
		var root: Node3D = f["root"]

		# Shy: near the Wonder-Walker the fish speeds up and, if it was swimming
		# toward them, turns around.
		var to_player := Vector3.ZERO
		var scared := false
		if _player:
			to_player = _player.global_position - root.global_position
			to_player.y = 0.0
			scared = to_player.length() < scare_radius
		f["mul"] = lerpf(f["mul"], scare_speed_mul if scared else 1.0, clampf(delta * 4.0, 0.0, 1.0))
		f["flip_cd"] = maxf(float(f["flip_cd"]) - delta, 0.0)
		f["t"] += delta * float(spec["speed"]) * float(f["mul"]) * float(f["sign"])

		var travel: float = fposmod(float(f["t"]), span * 2.0)
		var forward: bool = travel < span
		var s: float = a + (travel if forward else span * 2.0 - travel)
		var info: Dictionary = _point_at(s)
		var pos: Vector3 = info["pos"]
		var move_sign: float = (1.0 if forward else -1.0) * float(f["sign"])
		var dir: Vector3 = info["dir"] * move_sign
		if scared and float(f["flip_cd"]) <= 0.0 and dir.dot(to_player.normalized()) > 0.2:
			f["sign"] = -float(f["sign"])
			f["flip_cd"] = 1.2
			dir = -dir
		var dive := clampf((float(f["mul"]) - 1.0) / maxf(scare_speed_mul - 1.0, 0.01), 0.0, 1.0)

		var side: Vector3 = Vector3(-dir.z, 0.0, dir.x)
		var lane_off: float = spec["lane"] * float(info["width"]) * 0.5
		var wobble: float = sin(_time * 1.3 + float(spec["phase"])) * 0.06
		pos += side * (lane_off + wobble)
		pos.y += lift + sin(_time * 2.0 + float(spec["phase"])) * 0.012 - 0.04 * dive
		root.global_position = pos
		var target_yaw: float = atan2(-dir.x, -dir.z)
		f["yaw"] = lerp_angle(f["yaw"], target_yaw, clampf(delta * (3.0 + 5.0 * dive), 0.0, 1.0))
		root.rotation = Vector3(0.0, f["yaw"] + sin(_time * 5.0 + float(spec["phase"])) * 0.06, 0.0)
		(f["tail"] as Node3D).rotation.y = sin(_time * (8.0 + 12.0 * dive) + float(spec["phase"])) * (0.45 + 0.2 * dive)
