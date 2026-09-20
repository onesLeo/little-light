extends Node3D
## Fits the alive brook to the valley so it reads as one river:
## - Waterfall: the pack's fall is a ramp that runs back into the cliff, so its
##   right side is buried in rock. Squeeze the fall vertices onto the valley's
##   own notch (Waterfall_Sheet), which is where the cliff was carved for it.
## - Trees/bushes/rocks from the valley that stand in the water get nudged out, and are
##   lowered or raised to the ground where they now stand (they used to keep their old
##   height, so on a bank a moved tree was buried up to a metre or floated).
## Runs in _enter_tree (before any _ready) so the valley collision baker sees
## the moved meshes.

@export var valley_path: NodePath = ^"../../BethlehemValley"
@export var art_path: NodePath = ^"../Art"
@export var water_name: String = "Stream_Water"
@export var sheet_name: String = "Waterfall_Sheet"
@export var face_offset: float = 0.10
@export var side_inset: float = 0.05
@export var grid_cell: float = 0.12

## Size of the buckets the terrain triangles are sorted into when looking up ground height.
const TERRAIN_CELL := 1.0

var _mask: Dictionary = {}
var _cells_min := Vector2.ZERO


func _enter_tree() -> void:
	var valley := get_node_or_null(valley_path) as Node3D
	var art := get_node_or_null(art_path) as Node3D
	if valley == null or art == null:
		return
	var water := art.find_child(water_name, true, false) as MeshInstance3D
	var sheet := valley.find_child(sheet_name, true, false) as MeshInstance3D
	if water == null:
		return
	if sheet:
		_fit_waterfall(water, sheet)
	_build_mask(water)
	_move_trees_out(valley, water)


func _rows(points: Array, want_z_min: bool) -> Array:
	var buckets := {}
	for p in points:
		var k := int(round(p.y * 10.0))
		if not buckets.has(k):
			buckets[k] = {"y": 0.0, "n": 0, "xl": 1e9, "xr": -1e9, "z": 1e9}
		var b: Dictionary = buckets[k]
		b["y"] += p.y
		b["n"] += 1
		b["xl"] = minf(b["xl"], p.x)
		b["xr"] = maxf(b["xr"], p.x)
		b["z"] = minf(b["z"], p.z)
	var rows := []
	for k in buckets:
		var b: Dictionary = buckets[k]
		rows.append({"y": b["y"] / b["n"], "xl": b["xl"], "xr": b["xr"], "z": b["z"]})
	rows.sort_custom(func(a, b): return a["y"] < b["y"])
	return rows


func _sample(rows: Array, key: String, y: float) -> float:
	if y <= rows[0]["y"]:
		return rows[0][key]
	for i in range(1, rows.size()):
		if y <= rows[i]["y"]:
			var a: Dictionary = rows[i - 1]
			var b: Dictionary = rows[i]
			var t: float = (y - a["y"]) / maxf(b["y"] - a["y"], 0.0001)
			return lerpf(a[key], b[key], t)
	return rows[rows.size() - 1][key]


func _fit_waterfall(water: MeshInstance3D, sheet: MeshInstance3D) -> void:
	var sheet_pts := []
	var sxf := sheet.global_transform
	for v in sheet.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		sheet_pts.append(sxf * v)
	var notch := _rows(sheet_pts, true)
	var sb := sheet.global_transform * sheet.get_aabb()

	var mesh := water.mesh as ArrayMesh
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var xf := water.global_transform
	var inv := xf.affine_inverse()

	var in_zone := func(w: Vector3) -> bool:
		return (w.y >= 0.25 and w.y <= sb.end.y + 0.3
			and w.x >= sb.position.x - 1.2 and w.x <= sb.end.x + 1.2
			and w.z >= sb.position.z - 2.4 and w.z <= sb.end.z + 0.25)

	var zone_pts := []
	for v in verts:
		var w := xf * v
		if in_zone.call(w):
			zone_pts.append(w)
	if zone_pts.size() < 4:
		return
	var pack := _rows(zone_pts, false)

	for i in verts.size():
		var w: Vector3 = xf * verts[i]
		if not in_zone.call(w):
			continue
		var y: float = clampf(w.y, notch[0]["y"], notch[notch.size() - 1]["y"])
		var pl: float = _sample(pack, "xl", w.y)
		var pr: float = _sample(pack, "xr", w.y)
		var u: float = clampf((w.x - pl) / maxf(pr - pl, 0.0001), 0.0, 1.0)
		var nl: float = _sample(notch, "xl", y) + side_inset
		var nr: float = _sample(notch, "xr", y) - side_inset
		w.x = lerpf(nl, nr, u)
		w.z = _sample(notch, "z", y) + face_offset
		verts[i] = inv * w

	arrays[Mesh.ARRAY_VERTEX] = verts
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays)
	st.generate_normals()
	var fixed := st.commit()
	fixed.surface_set_material(0, mesh.surface_get_material(0))
	water.mesh = fixed


func _build_mask(water: MeshInstance3D) -> void:
	var xf := water.global_transform
	var arrays := water.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx = arrays[Mesh.ARRAY_INDEX]
	var tri_count: int = (idx.size() if idx != null else verts.size()) / 3
	_mask.clear()
	for t in tri_count:
		var p := []
		for c in 3:
			var vi: int = idx[t * 3 + c] if idx != null else t * 3 + c
			var w: Vector3 = xf * verts[vi]
			p.append(Vector2(w.x, w.z))
		var lo: Vector2 = Vector2(minf(p[0].x, minf(p[1].x, p[2].x)), minf(p[0].y, minf(p[1].y, p[2].y)))
		var hi: Vector2 = Vector2(maxf(p[0].x, maxf(p[1].x, p[2].x)), maxf(p[0].y, maxf(p[1].y, p[2].y)))
		for cx in range(int(floor(lo.x / grid_cell)), int(ceil(hi.x / grid_cell)) + 1):
			for cz in range(int(floor(lo.y / grid_cell)), int(ceil(hi.y / grid_cell)) + 1):
				var q := Vector2((cx + 0.5) * grid_cell, (cz + 0.5) * grid_cell)
				if _in_tri(q, p[0], p[1], p[2]):
					_mask[Vector2i(cx, cz)] = true


func _in_tri(q: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 := (q - b).cross(a - b)
	var d2 := (q - c).cross(b - c)
	var d3 := (q - a).cross(c - a)
	var neg := d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var pos := d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (neg and pos)


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / grid_cell)), int(floor(p.y / grid_cell)))


func _nearest(p: Vector2, want_water: bool, max_r: float) -> Vector2:
	var c := _cell_of(p)
	var span := int(ceil(max_r / grid_cell))
	var best := Vector2.INF
	var best_d := 1e9
	for dx in range(-span, span + 1):
		for dz in range(-span, span + 1):
			var cell := Vector2i(c.x + dx, c.y + dz)
			if _mask.has(cell) != want_water:
				continue
			var q := Vector2((cell.x + 0.5) * grid_cell, (cell.y + 0.5) * grid_cell)
			var d := p.distance_to(q)
			if d < best_d:
				best_d = d
				best = q
	return best


func _move_trees_out(valley: Node3D, water: MeshInstance3D) -> void:
	var wb := water.global_transform * water.get_aabb()
	var moved: Dictionary = {}
	var centers: Dictionary = {}
	for mi in valley.find_children("*", "MeshInstance3D", true, false):
		var n := String(mi.name)
		if n.ends_with("_Outline"):
			continue
		if not (n.begins_with("Cypress") or n.begins_with("Olive") or n.begins_with("Shrub")):
			continue
		var m := mi as MeshInstance3D
		var b := m.global_transform * m.get_aabb()
		var center := Vector2(b.get_center().x, b.get_center().z)
		if center.x < wb.position.x - 4.0 or center.x > wb.end.x + 4.0 or center.y < wb.position.z - 4.0 or center.y > wb.end.z + 4.0:
			continue
		var radius := maxf(b.size.x, b.size.z) * 0.5
		var clearance := radius * 0.55 + 0.25
		var pos := center
		for _i in 8:
			var w := _nearest(pos, true, clearance + 1.5)
			var dist := 1e9
			var dir := Vector2.ZERO
			if _mask.has(_cell_of(pos)):
				var out := _nearest(pos, false, 6.0)
				if out == Vector2.INF:
					break
				dir = (out - pos).normalized()
				dist = -(out - pos).length()
			elif w != Vector2.INF:
				dir = (pos - w).normalized()
				dist = pos.distance_to(w)
			else:
				break
			if dist >= clearance:
				break
			pos += dir * (clearance - dist + 0.05)
		var delta := pos - center
		if delta.length() > 0.01:
			moved[n] = Vector3(delta.x, 0.0, delta.y)
			# Trees have their origin at the trunk base; a bush's origin is not where it grows, so use its middle.
			var base := m.global_position if (n.begins_with("Cypress") or n.begins_with("Olive")) else b.get_center()
			centers[n] = Vector2(base.x, base.z)
	_settle_on_ground(valley, moved, centers)
	for mi in valley.find_children("*", "MeshInstance3D", true, false):
		var base := String(mi.name).trim_suffix("_Outline")
		if moved.has(base):
			(mi as Node3D).global_position += moved[base]


## Sets each moved object's height change to the difference in ground height between where it
## stood and where it now stands, read from the valley terrain mesh (there is no collision yet
## this early).
func _settle_on_ground(valley: Node3D, moved: Dictionary, centers: Dictionary) -> void:
	var terrain := valley.find_child("Valley_Terrain", true, false) as MeshInstance3D
	if terrain == null or moved.is_empty():
		return
	var wanted := {}
	for n in moved:
		var c: Vector2 = centers[n]
		var d: Vector3 = moved[n]
		for p in [c, c + Vector2(d.x, d.z)]:
			var cell := _terrain_cell(p)
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					wanted[Vector2i(cell.x + dx, cell.y + dz)] = true
	var buckets := _terrain_triangles(terrain, wanted)
	for n in moved:
		var c: Vector2 = centers[n]
		var d: Vector3 = moved[n]
		var before := _ground_y(buckets, c)
		var after := _ground_y(buckets, c + Vector2(d.x, d.z))
		if not is_nan(before) and not is_nan(after):
			d.y = after - before
			moved[n] = d


func _terrain_cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / TERRAIN_CELL)), int(floor(p.y / TERRAIN_CELL)))


## Terrain triangles in world space, sorted into buckets by the cell their centre is in. Only
## the wanted cells are kept, so the lookup stays cheap.
func _terrain_triangles(terrain: MeshInstance3D, wanted: Dictionary) -> Dictionary:
	var xf := terrain.global_transform
	var arrays := terrain.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx = arrays[Mesh.ARRAY_INDEX]
	var tri_count: int = (idx.size() if idx != null else verts.size()) / 3
	var buckets := {}
	for t in tri_count:
		var tri := PackedVector3Array()
		for c in 3:
			var vi: int = idx[t * 3 + c] if idx != null else t * 3 + c
			tri.append(xf * verts[vi])
		var centre := Vector2((tri[0].x + tri[1].x + tri[2].x) / 3.0, (tri[0].z + tri[1].z + tri[2].z) / 3.0)
		var cell := _terrain_cell(centre)
		if not wanted.has(cell):
			continue
		if not buckets.has(cell):
			buckets[cell] = []
		buckets[cell].append(tri)
	return buckets


## Ground height at a point, or NAN when no triangle covers it.
func _ground_y(buckets: Dictionary, p: Vector2) -> float:
	var cell := _terrain_cell(p)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var list = buckets.get(Vector2i(cell.x + dx, cell.y + dz))
			if list == null:
				continue
			for tri in list:
				var a := Vector2(tri[0].x, tri[0].z)
				var b := Vector2(tri[1].x, tri[1].z)
				var c := Vector2(tri[2].x, tri[2].z)
				var den := (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
				if absf(den) < 0.000001:
					continue
				var u := ((b.y - c.y) * (p.x - c.x) + (c.x - b.x) * (p.y - c.y)) / den
				var v := ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) / den
				var w := 1.0 - u - v
				if u >= -0.0001 and v >= -0.0001 and w >= -0.0001:
					return u * tri[0].y + v * tri[1].y + w * tri[2].y
	return NAN
