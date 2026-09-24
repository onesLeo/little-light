extends Node3D
## The King's Camp, on the ridge that is already behind the waterfall.
## The valley's ridge top is only a few steps deep, so the camp stands on its
## own stretch of ground that carries on from it: a wide, gently rolling
## clearing with trees at its edges, and the whole of chapter 1 below the
## lookout. It is built the first time the child visits, so chapter 1 never pays
## for it. visit() is what lets the child walk up there: the soft edge of the
## valley opens, the light becomes the blue hour, and she arrives at the back of
## the camp with the fire in front of her.
##
## Layout, looking the way the tabletop camera looks (toward the valley):
## the lookout stone at the far edge, the fire in the middle, the king's round
## tent to its left, three smaller tents around it, and the arrival path behind.

const Paper := preload("res://scripts/camp_paper.gd")
const ChapterTwo := preload("res://scripts/chapter_two.gd")
const Guard := preload("res://scripts/camp_guard.gd")
const Owl := preload("res://scripts/camp_owl.gd")
const Fireflies := preload("res://scripts/camp_fireflies.gd")
const CampSounds := preload("res://scripts/camp_sounds.gd")
const Profiles := preload("res://scripts/profiles.gd")
const MeadowDressing := preload("res://scripts/meadow_dressing.gd")

## The middle of the clearing. Everything below is placed relative to it (x, z).
const CAMP := Vector3(-2.0, 0.0, 36.0)
const LEVEL := 10.4
## The valley mesh ends here; the camp ground starts just inside it.
const SEAM_Z := 29.52

const FIRE := Vector2(1.0, 0.0)
const ARRIVE := Vector2(0.0, 10.0)
const LOOKOUT := Vector2(0.6, -7.4)
const KING_TENT := Vector2(-6.2, -1.2)
## Three smaller tents, further back and to the sides, so the fire and the path stay clear.
const TENTS := [Vector2(6.8, -2.0), Vector2(7.6, 4.2), Vector2(-7.8, 6.0)]
const FLAGS := [Vector2(-3.6, -3.4), Vector2(3.2, -3.6), Vector2(-4.2, 7.0), Vector2(3.6, 6.8)]
## The walking line through the camp, kept clear of props and grass.
const PATH := [Vector2(0.0, 16.0), Vector2(0.0, 12.5), Vector2(0.4, 6.0), Vector2(0.9, 2.4), Vector2(0.8, -3.0), Vector2(0.6, -7.2)]
const GUARD_ROUTES := [
	[Vector2(-9.6, -3.8), Vector2(-9.6, 3.0), Vector2(-12.0, 3.2), Vector2(-12.0, -3.6)],
	[Vector2(4.6, -5.4), Vector2(9.8, -5.4), Vector2(9.8, 1.6), Vector2(4.8, 1.6)],
	[Vector2(-11.2, 8.6), Vector2(-7.6, 15.2)],
	[Vector2(4.0, 15.0), Vector2(10.8, 13.0)],
]
## (x, z, kind, scale): kind 0 = cypress, 1 = olive.
const TREES := [
	Vector4(-9.0, -6.2, 0, 1.15), Vector4(11.6, -6.6, 1, 0.9),
	Vector4(-14.5, -3.5, 0, 1.0), Vector4(-15.2, 2.5, 1, 1.0), Vector4(-14.2, 8.0, 0, 1.05),
	Vector4(13.6, -3.0, 0, 1.0), Vector4(13.2, 7.4, 0, 1.1), Vector4(14.4, 12.8, 1, 0.95),
	# Along the back rise: always behind the tabletop camera, so they only close the camp off
	# when it is seen from the valley side (the close-ups and the lookout).
	Vector4(-7.5, 23.5, 1, 1.05), Vector4(0.5, 24.8, 0, 1.1), Vector4(8.0, 24.0, 1, 1.0),
]
const FIREFLIES := [Vector2(-10.6, 5.0), Vector2(-10.0, 11.8), Vector2(-12.4, -1.2), Vector2(11.2, -0.8),
		Vector2(11.4, 9.6), Vector2(9.4, 16.0), Vector2(-5.6, 16.8), Vector2(2.8, 17.6)]

const CLOTH := Color(0.84, 0.72, 0.52)
const CLOTH_B := Color(0.79, 0.68, 0.5)
const DOORWAY := Color(0.58, 0.47, 0.34)
const WINE := Color(0.55, 0.26, 0.3)
const BLUE := Color(0.26, 0.38, 0.62)
const WOOD := Color(0.45, 0.3, 0.17)
const WOOD_END := Color(0.78, 0.62, 0.42)
const GRASS := Color(0.44, 0.58, 0.4)
const EARTH := Color(0.63, 0.57, 0.43)
const PATH_STONE := Color(0.66, 0.56, 0.43)

const FLAG_SHADER := """
shader_type spatial;
render_mode %s;
uniform vec3 color : source_color = vec3(0.3, 0.4, 0.6);
uniform float phase = 0.0;
uniform float gust = 0.0;
uniform vec3 ink_scale = vec3(1.0);
void vertex() {
	VERTEX *= ink_scale;
	float from_pole = clamp((VERTEX.x + 0.45) / 0.9, 0.0, 1.0);
	VERTEX.z += (sin(TIME * 1.7 - from_pole * 4.0 + phase) * 0.06 + gust * 0.22) * from_pole;
	VERTEX.y -= from_pole * from_pole * (0.06 - gust * 0.04);
}
void fragment() {
	ALBEDO = color;
	ROUGHNESS = 1.0;
}
"""

var _clearing := Vector3.ZERO
var _built: bool = false
var _grid_x: PackedFloat32Array = PackedFloat32Array()
var _grid_z: PackedFloat32Array = PackedFloat32Array()
var _grid_h: PackedFloat32Array = PackedFloat32Array()
var _flames: Array[MeshInstance3D] = []
var _flame_root: Node3D
var _fire_light: OmniLight3D
var _halo: MeshInstance3D
var _lantern: Node3D
var _flag_mats: Array[ShaderMaterial] = []
var _owl: Node3D
var _fireflies: Node3D
var _sounds: Node3D
var _moon: MeshInstance3D
var _people_shader: Shader
var _white_tex: Texture2D
var _time: float = 0.0


func tent_count() -> int:
	var n := 0
	for child in get_children():
		if str(child.name).begins_with("Tent"):
			n += 1
	return n


func visit() -> void:
	# "Play again" from here comes back to the camp, not to the valley.
	Profiles.current_chapter = Profiles.CHAPTER_CAMP
	_build()
	var main := get_parent()
	var director := main.get_node_or_null("ChapterDirector")
	if director and director.has_method("stand_down"):
		director.stand_down()
	var menu := main.get_node_or_null("GameMenu")
	if menu and menu.has_method("hide_end_panel"):
		menu.hide_end_panel()
	var bounds := main.get_node_or_null("PlayBounds")
	if bounds and bounds.has_method("open_camp"):
		bounds.open_camp()
	_blue_hour()
	var soundscape := main.get_node_or_null("Soundscape")
	if soundscape and soundscape.has_method("set_night"):
		soundscape.set_night(true)
	_sounds.start(_at(FIRE))
	var player := main.get_node_or_null("Player") as CharacterBody3D
	if player:
		player.velocity = Vector3.ZERO
		player.global_position = _at(ARRIVE) + Vector3(0.0, 0.2, 0.0)
		_snap_followers(player)
	var story := get_node_or_null("ChapterTwo")
	var mid_story: bool = story != null and story.phase != ChapterTwo.Phase.IDLE and story.phase != ChapterTwo.Phase.DONE
	var line := main.find_child("DialogueLabel", true, false) as Label
	if line and not mid_story:
		line.text = "Jonathan is by the fire. His hair is long, and his tunic is red."
	if story and story.has_method("begin"):
		story.begin()
	var david := main.get_node_or_null("DavidMentor") as Node3D
	if david:
		david.global_position = _at(Vector2(2.7, 1.0))
		var jon := get_node_or_null("Jonathan") as Node3D
		if jon:
			var to_jon := jon.global_position - david.global_position
			david.rotation.y = atan2(-to_jon.x, -to_jon.z)
			jon.rotation.y = atan2(to_jon.x, to_jon.z)
			if not david.has_node("CampConversation"):
				var life := preload("res://scripts/camp_conversation.gd").new()
				life.name = "CampConversation"
				david.add_child(life)
	if _owl and _owl.has_method("arrive"):
		_owl.arrive(_owl_start())
	if _fireflies:
		_fireflies.light_up()
	_keep_people_paper()


func _snap_followers(player: Node3D) -> void:
	var cam := get_parent().get_node_or_null("TabletopCamera") as Camera3D
	if cam and "offset" in cam:
		cam.global_position = player.global_position + cam.offset
		cam.look_at(player.global_position + Vector3(0.0, cam.look_height, 0.0), Vector3.UP)
	var light := get_parent().get_node_or_null("WonderLight") as Node3D
	if light and "hover_offset" in light:
		light.global_position = player.global_position + light.hover_offset


func _process(delta: float) -> void:
	_time += delta
	_breathe_fire()
	# The wind: now and then everything that hangs leans the same way, then eases back.
	var gust := pow(maxf(sin(_time * 0.31) * sin(_time * 0.11 + 1.3), 0.0), 1.5)
	for m in _flag_mats:
		m.set_shader_parameter("gust", gust)
		var ink := m.next_pass as ShaderMaterial
		if ink:
			ink.set_shader_parameter("gust", gust)
	if _lantern:
		_lantern.rotation.z = sin(_time * 1.1) * 0.04 + gust * 0.06


func _breathe_fire() -> void:
	if _flame_root == null:
		return
	# Flat paper flames always turn toward the camera, the way the valley's cut-outs do.
	var cam := get_viewport().get_camera_3d()
	if cam:
		var d := cam.global_position - _flame_root.global_position
		_flame_root.rotation.y = atan2(d.x, d.z)
	for i in _flames.size():
		var f := _flames[i]
		var k := float(i)
		f.scale = Vector3(1.0 - 0.07 * sin(_time * 2.3 + k * 1.9), 1.0 + 0.16 * sin(_time * 1.7 + k * 2.4) + 0.05 * sin(_time * 4.1 + k), 1.0)
		f.rotation.z = 0.1 * sin(_time * 1.3 + k * 1.3)
	var breath := 1.0 + 0.07 * sin(_time * 1.7) + 0.04 * sin(_time * 4.1)
	if _fire_light:
		_fire_light.light_energy = 1.9 * breath
	if _halo:
		_halo.scale = Vector3.ONE * breath


## -- Where things go --------------------------------------------------------------

## A camp position (x, z relative to the middle of the clearing) on the ground.
func _at(p: Vector2) -> Vector3:
	return _ground(Vector3(CAMP.x + p.x, 0.0, CAMP.z + p.y))


## The ground under a world point: the camp's own ground where it has it, the valley elsewhere.
func _ground(at: Vector3) -> Vector3:
	if _grid_h.size() > 0 and at.z >= SEAM_Z + 0.05 and at.x >= _grid_x[0] and at.x <= _grid_x[_grid_x.size() - 1] \
			and at.z <= _grid_z[_grid_z.size() - 1]:
		return Vector3(at.x, _grid_height(at.x, at.z), at.z)
	var space := get_world_3d().direct_space_state
	if space == null:
		return at
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, 40.0, at.z), Vector3(at.x, -5.0, at.z))
	query.collision_mask = 1
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return at
	return hit.position


func _grid_height(x: float, z: float) -> float:
	var nx := _grid_x.size()
	var i := clampi(_index_of(_grid_x, x), 0, nx - 2)
	var j := clampi(_index_of(_grid_z, z), 0, _grid_z.size() - 2)
	var tx := clampf((x - _grid_x[i]) / (_grid_x[i + 1] - _grid_x[i]), 0.0, 1.0)
	var tz := clampf((z - _grid_z[j]) / (_grid_z[j + 1] - _grid_z[j]), 0.0, 1.0)
	var h00 := _grid_h[j * nx + i]
	var h10 := _grid_h[j * nx + i + 1]
	var h01 := _grid_h[(j + 1) * nx + i]
	var h11 := _grid_h[(j + 1) * nx + i + 1]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


func _index_of(values: PackedFloat32Array, v: float) -> int:
	var lo := 0
	var hi := values.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if values[mid] <= v:
			lo = mid
		else:
			hi = mid
	return lo


## The owl comes in from the right, over the tents, so the child sees it glide
## across the camp to its cypress by the lookout.
func _owl_start() -> Vector3:
	return _at(Vector2(13.0, 8.0)) + Vector3(0.0, 5.5, 0.0)


## -- Building ----------------------------------------------------------------------

func _build() -> void:
	if _built:
		return
	_built = true
	_build_ground()
	_clearing = _at(Vector2.ZERO)
	_build_trees()
	_build_fire()
	_build_king_tent()
	for i in TENTS.size():
		_ridge_tent(i, TENTS[i])
	for i in FLAGS.size():
		_flag(i, FLAGS[i], BLUE if i % 3 == 0 else WINE)
	_warm_the_tent()
	_build_lookout()
	for i in GUARD_ROUTES.size():
		_guard(i, GUARD_ROUTES[i])
	_place_jonathan()
	var story := Node.new()
	story.name = "ChapterTwo"
	story.set_script(ChapterTwo)
	add_child(story)
	_build_owl()
	_build_fireflies()
	_sounds = CampSounds.new()
	_sounds.name = "CampSounds"
	add_child(_sounds)
	_build_grass()


## The camp's ground: carries on from the valley's ridge top at the seam, stays
## nearly level through the clearing, and rises softly at the sides and back
## where the trees stand, so the camera never sees an edge.
func _build_ground() -> void:
	var xs := PackedFloat32Array()
	var x := -30.0
	while x <= 29.51:
		xs.append(x)
		x += 0.75
	var zs := PackedFloat32Array([29.2, 29.6])
	var z := 30.4
	while z <= 62.0:
		zs.append(z)
		z += 0.8
	_grid_x = xs
	_grid_z = zs
	var seam := PackedFloat32Array()
	for xi in xs:
		seam.append(_valley_height(xi, SEAM_Z - 0.07, LEVEL))
	var heights := PackedFloat32Array()
	heights.resize(xs.size() * zs.size())
	var colors := PackedColorArray()
	colors.resize(heights.size())
	for j in zs.size():
		for i in xs.size():
			var k := j * xs.size() + i
			var px := xs[i]
			var pz := zs[j]
			var h: float
			if pz < SEAM_Z:
				h = _valley_height(px, pz, seam[i]) - 0.03
			else:
				var b := smoothstep(SEAM_Z, 33.0, pz)
				h = lerpf(seam[i], LEVEL, b)
				h += (sin(px * 0.35 + pz * 0.21) * 0.06 + sin(px * 0.9 - pz * 0.6) * 0.03) * b
				var side := smoothstep(12.5, 22.0, absf(px - CAMP.x))
				var back := smoothstep(54.0, 62.0, pz)
				h += (side * side * 3.0 + back * 2.4) * b
			heights[k] = h
			colors[k] = _ground_color(px, pz)
	_grid_h = heights

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := xs.size()
	for j in zs.size() - 1:
		for i in nx - 1:
			var a := j * nx + i
			var b2 := a + 1
			var c := a + nx
			var d := c + 1
			for idx in [a, b2, c, b2, d, c]:
				st.set_color(colors[idx])
				st.add_vertex(Vector3(xs[idx % nx], heights[idx], zs[idx / nx]))
	st.index()
	st.generate_normals()
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var body := StaticBody3D.new()
	body.name = "CampGround"
	body.collision_layer = 1
	add_child(body)
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	mi.name = "CampGroundMesh"
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)


## The valley surface under a point (its own terrain only, not trees or rocks).
func _valley_height(x: float, z: float, fallback: float) -> float:
	var space := get_world_3d().direct_space_state
	if space == null:
		return fallback
	var exclude: Array[RID] = []
	for _i in 6:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, 60.0, z), Vector3(x, -5.0, z))
		q.collision_mask = 1
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return fallback
		var body := hit.collider as Node
		if body and body.get_parent() and String(body.get_parent().name) == "Valley_Terrain":
			return hit.position.y
		exclude.append(hit.rid)
	return fallback


func _ground_color(x: float, z: float) -> Color:
	var p := Vector2(x - CAMP.x, z - CAMP.z)
	var wobble := sin(x * 1.3 + z * 0.7) * 0.5 + sin(x * 0.4 - z * 1.1) * 0.5
	var c := GRASS.lerp(GRASS.darkened(0.06), wobble * 0.5 + 0.5)
	if z < SEAM_Z + 1.0:
		return GRASS
	# The rises at the edges are a shade deeper.
	c = c.lerp(Color(0.4, 0.54, 0.37), smoothstep(12.5, 18.0, absf(p.x)))
	# Trodden earth round the fire and at each doorway.
	var worn := 1.0 - smoothstep(1.8, 3.2, p.distance_to(FIRE))
	for t in TENTS:
		worn = maxf(worn, (1.0 - smoothstep(1.6, 2.6, p.distance_to(t))) * 0.6)
	worn = maxf(worn, (1.0 - smoothstep(2.4, 3.6, p.distance_to(KING_TENT))) * 0.7)
	c = c.lerp(EARTH, worn)
	# The walking path, the same warm stone as the valley's.
	var along := 1.0 - smoothstep(0.35, 0.8, _dist_to_path(p))
	return c.lerp(PATH_STONE, along)


func _dist_to_path(p: Vector2) -> float:
	var best := INF
	for i in PATH.size() - 1:
		var a: Vector2 = PATH[i]
		var b: Vector2 = PATH[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


## Trees from the valley itself, so the camp is the same ridge and not a new forest.
func _build_trees() -> void:
	var valley := get_parent().get_node_or_null("BethlehemValley")
	if valley == null:
		return
	var sources := {0: [], 1: []}
	for n in valley.find_children("*", "MeshInstance3D", true, false):
		var nm := String(n.name)
		if nm.ends_with("_Outline"):
			continue
		if nm.begins_with("Cypress"):
			sources[0].append(n)
		elif nm.begins_with("Olive"):
			sources[1].append(n)
	var holder := Node3D.new()
	holder.name = "Trees"
	add_child(holder)
	for i in TREES.size():
		var spec: Vector4 = TREES[i]
		var pool: Array = sources[int(spec.z)]
		if pool.is_empty():
			continue
		var src := pool[i % pool.size()] as MeshInstance3D
		var kind := "Cypress" if int(spec.z) == 0 else "Olive"
		var at := _at(Vector2(spec.x, spec.y))
		var basis := Basis(Vector3.UP, float(i) * 2.1).scaled(Vector3.ONE * spec.w)
		var tree := _copy_with_outline(src, holder, "%sCamp%d" % [kind, i], Transform3D(basis, at))
		if i == 0:
			tree.set_meta("owl_tree", true)


func _copy_with_outline(src: MeshInstance3D, holder: Node3D, node_name: String, xform: Transform3D) -> MeshInstance3D:
	var copy := src.duplicate() as MeshInstance3D
	copy.name = node_name
	holder.add_child(copy)
	copy.global_transform = xform
	var src_outline := src.get_parent().get_node_or_null(String(src.name) + "_Outline") as MeshInstance3D
	if src_outline:
		var ol := src_outline.duplicate() as MeshInstance3D
		ol.name = node_name + "_Outline"
		ol.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(ol)
		ol.global_transform = xform
	return copy


func _valley_rocks() -> Array:
	var rocks := []
	var valley := get_parent().get_node_or_null("BethlehemValley")
	if valley == null:
		return rocks
	for n in valley.find_children("Rock_*", "MeshInstance3D", true, false):
		if not String(n.name).ends_with("_Outline"):
			rocks.append(n)
	return rocks


## The fire: a low ring of the valley's own stones, a few sticks, and flat paper
## flames that breathe. A warm pool of light only near it.
func _build_fire() -> void:
	var at := _at(FIRE)
	var fire := Node3D.new()
	fire.name = "Campfire"
	add_child(fire)
	fire.global_position = at
	Paper.part(fire, "Ash", Paper.cylinder(0.58, 0.05, 10), Color(0.32, 0.28, 0.26), Vector3(0.0, 0.02, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
	var rocks := _valley_rocks()
	var ring := Node3D.new()
	ring.name = "Stones"
	add_child(ring)
	for k in 10:
		var a := TAU * k / 10.0
		var p := at + Vector3(cos(a) * 0.8, 0.0, sin(a) * 0.8)
		if rocks.is_empty():
			Paper.part(ring, "Stone", Paper.sphere(0.16, 6), Color(0.6, 0.6, 0.62), p + Vector3(0.0, 0.08, 0.0), Vector3(0.0, a, 0.0), Vector3(1.2, 0.7, 1.0))
		else:
			var src := rocks[k % rocks.size()] as MeshInstance3D
			var basis := Basis(Vector3.UP, a * 1.7).scaled(Vector3(0.34, 0.3, 0.34))
			_copy_with_outline(src, ring, "FireStone%d" % k, Transform3D(basis, _ground(p) + Vector3(0.0, 0.05, 0.0)))
	for k in 4:
		var a := TAU * k / 4.0 + 0.4
		_stick(fire, Vector3(cos(a) * 0.45, 0.05, sin(a) * 0.45), Vector3(cos(a) * 0.05, 0.42, sin(a) * 0.05), 0.045, WOOD)
	var block := StaticBody3D.new()
	block.name = "FireBlock"
	fire.add_child(block)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.95
	cyl.height = 0.6
	shape.shape = cyl
	shape.position = Vector3(0.0, 0.3, 0.0)
	block.add_child(shape)

	_flame_root = Node3D.new()
	_flame_root.name = "Flames"
	fire.add_child(_flame_root)
	_flame_root.position = Vector3(0.0, 0.08, 0.0)
	var orange := Paper.glow_mat(Color(1.0, 0.55, 0.16))
	var deep := Paper.glow_mat(Color(0.96, 0.4, 0.12))
	var yellow := Paper.glow_mat(Color(1.0, 0.86, 0.32))
	var tongues := [
		[-0.2, 0.34, 0.72, -0.08, deep], [0.02, 0.44, 1.0, 0.05, orange],
		[0.22, 0.34, 0.78, 0.1, deep], [-0.06, 0.3, 0.62, -0.12, orange],
		[-0.08, 0.2, 0.46, -0.04, yellow], [0.1, 0.18, 0.4, 0.06, yellow], [0.0, 0.16, 0.56, 0.0, yellow],
	]
	for i in tongues.size():
		var t: Array = tongues[i]
		var flame := MeshInstance3D.new()
		flame.name = "Flame%d" % i
		flame.mesh = Paper.flame(t[1], t[2], t[3])
		flame.material_override = t[4]
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flame.position = Vector3(t[0], 0.0, 0.03 * float(i >= 4) + 0.005 * i)
		_flame_root.add_child(flame)
		Paper.flat_outline(flame, 0.022)
		_flames.append(flame)
	_halo = Paper.halo(2.0, Color(1.0, 0.55, 0.2))
	(_halo.mesh.material as StandardMaterial3D).albedo_color = Color(1.0, 1.0, 1.0, 0.32)
	fire.add_child(_halo)
	_halo.position = Vector3(0.0, 0.55, 0.0)
	_fire_light = OmniLight3D.new()
	_fire_light.name = "FireLight"
	_fire_light.light_color = Color(1.0, 0.6, 0.3)
	_fire_light.light_energy = 1.9
	_fire_light.omni_range = 5.5
	_fire_light.omni_attenuation = 1.6
	fire.add_child(_fire_light)
	_fire_light.position = Vector3(0.0, 0.9, 0.0)
	# Somewhere to sit: one log on the near side, one to the right, and a woodpile.
	_log(fire, Vector3(0.0, 0.0, 1.55), 0.0, 1.5, 0.19)
	_log(fire, Vector3(1.75, 0.0, -0.45), 1.25, 1.3, 0.17)
	for k in 5:
		var row := float(k % 3)
		var layer := float(k / 3)
		_log(fire, Vector3(2.05, layer * 0.17, -2.1 + row * 0.19 + layer * 0.095), 0.0, 0.85, 0.09)


func _log(parent: Node3D, at: Vector3, yaw: float, length: float, radius: float) -> void:
	var holder := Node3D.new()
	holder.name = "Log"
	parent.add_child(holder)
	holder.position = at + Vector3(0.0, radius, 0.0)
	holder.rotation.y = yaw
	Paper.part(holder, "Bark", Paper.cylinder(radius, length, 7), WOOD, Vector3.ZERO, Vector3(0.0, 0.0, PI * 0.5), Vector3.ONE, 0.018)
	for side in [-1.0, 1.0]:
		Paper.part(holder, "End", Paper.cylinder(radius * 0.8, 0.02, 7), WOOD_END, Vector3(side * length * 0.5, 0.0, 0.0), Vector3(0.0, 0.0, PI * 0.5), Vector3.ONE, 0.0)
	if radius > 0.12:
		var body := StaticBody3D.new()
		holder.add_child(body)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(length, radius * 2.0, radius * 2.0)
		shape.shape = box
		body.add_child(shape)


## A pole, rope or stick between two local points.
func _stick(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color, line: float = 0.015) -> MeshInstance3D:
	var d := to - from
	var length := d.length()
	var mi := Paper.part(parent, "Stick", Paper.cylinder(radius, length, 6), color, (from + to) * 0.5, Vector3.ZERO, Vector3.ONE, line)
	var up := d / length
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	mi.basis = Basis(side, up, side.cross(up)).orthonormalized()
	return mi


func _face_fire(p: Vector2) -> float:
	var d := FIRE - p
	return atan2(d.x, d.y)


## The king's tent: round, cream, open toward the fire under a small awning, with
## a wine band at the eave and a pennant on the centre pole. The lantern hangs by it.
func _build_king_tent() -> void:
	var tent := Node3D.new()
	tent.name = "TentKing"
	add_child(tent)
	tent.global_position = _at(KING_TENT)
	tent.rotation.y = _face_fire(KING_TENT)
	var radius := 2.3
	var wall := 1.55
	var peak := 3.6
	var mi := Paper.part(tent, "Cloth", Paper.pavilion(radius, wall, peak, 10), CLOTH, Vector3.ZERO, Vector3(0.0, PI / 10.0, 0.0), Vector3.ONE, 0.035)
	mi.name = "Cloth"
	Paper.part(tent, "Band", Paper.cylinder(radius + 0.25, 0.12, 10), WINE, Vector3(0.0, wall - 0.14, 0.0), Vector3(0.0, PI / 10.0, 0.0), Vector3.ONE, 0.015)
	var face := radius * cos(PI / 10.0)
	Paper.part(tent, "Doorway", Paper.box(Vector3(1.05, 1.35, 0.04)), DOORWAY, Vector3(0.0, 0.68, face + 0.01), Vector3.ZERO, Vector3.ONE, 0.015)
	for side in [-1.0, 1.0]:
		Paper.part(tent, "Flap", Paper.box(Vector3(0.36, 1.3, 0.05)), CLOTH_B, Vector3(0.66 * side, 0.7, face + 0.06), Vector3(0.0, 0.35 * side, 0.0), Vector3.ONE, 0.015)
	var awning := Paper.part(tent, "Awning", Paper.box(Vector3(2.1, 0.06, 1.4)), CLOTH_B, Vector3(0.0, 1.78, face + 0.7), Vector3(0.2, 0.0, 0.0), Vector3.ONE, 0.02)
	awning.name = "Awning"
	for side in [-1.0, 1.0]:
		_stick(tent, Vector3(0.95 * side, 0.0, face + 1.3), Vector3(0.95 * side, 1.66, face + 1.3), 0.035, WOOD)
	_stick(tent, Vector3(0.0, peak - 0.1, 0.0), Vector3(0.0, peak + 0.55, 0.0), 0.035, WOOD)
	Paper.part(tent, "Pennant", Paper.box(Vector3(0.4, 0.22, 0.02)), WINE, Vector3(0.22, peak + 0.4, 0.0), Vector3.ZERO, Vector3.ONE, 0.012)
	_solid(tent, Vector3(0.0, 1.5, 0.0), null, radius, 3.0)
	# The one lantern, hung at the tent mouth.
	var post_at := Vector3(1.35, 0.0, face + 1.7)
	_stick(tent, post_at, post_at + Vector3(0.0, 2.1, 0.0), 0.04, WOOD)
	_stick(tent, post_at + Vector3(0.0, 2.0, 0.0), post_at + Vector3(-0.55, 2.0, 0.0), 0.025, WOOD)
	_lantern = Node3D.new()
	_lantern.name = "Lantern"
	tent.add_child(_lantern)
	_lantern.position = post_at + Vector3(-0.5, 1.98, 0.0)
	var dark := Color(0.32, 0.22, 0.14)
	Paper.part(_lantern, "String", Paper.cylinder(0.008, 0.18, 4), dark, Vector3(0.0, -0.09, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
	Paper.part(_lantern, "Top", Paper.cylinder(0.1, 0.05, 8, 0.05), dark, Vector3(0.0, -0.2, 0.0), Vector3.ZERO, Vector3.ONE, 0.012)
	var paper := Paper.part(_lantern, "Paper", Paper.cylinder(0.12, 0.26, 8), Color(0.97, 0.9, 0.72), Vector3(0.0, -0.36, 0.0), Vector3.ZERO, Vector3.ONE, 0.015)
	paper.material_override = Paper.glow_mat(Color(0.98, 0.9, 0.7))
	var core := Paper.part(_lantern, "Core", Paper.cylinder(0.125, 0.12, 8), Color(1.0, 0.82, 0.32), Vector3(0.0, -0.36, 0.0), Vector3.ZERO, Vector3.ONE, 0.0)
	core.material_override = Paper.glow_mat(Color(1.0, 0.82, 0.32))
	Paper.part(_lantern, "Base", Paper.cylinder(0.1, 0.04, 8), dark, Vector3(0.0, -0.51, 0.0), Vector3.ZERO, Vector3.ONE, 0.012)
	var glow := Paper.halo(0.9, Color(1.0, 0.8, 0.4))
	(glow.mesh.material as StandardMaterial3D).albedo_color = Color(1.0, 1.0, 1.0, 0.5)
	_lantern.add_child(glow)
	glow.position = Vector3(0.0, -0.36, 0.0)
	var light := OmniLight3D.new()
	light.name = "LanternLight"
	light.light_color = Color(1.0, 0.82, 0.5)
	light.light_energy = 0.9
	light.omni_range = 4.0
	_lantern.add_child(light)
	light.position = Vector3(0.0, -0.4, 0.0)
	_solid(tent, post_at + Vector3(0.0, 1.0, 0.0), null, 0.12, 2.0)


## One of the smaller ridge tents, its doorway toward the fire.
func _ridge_tent(index: int, p: Vector2) -> void:
	var tent := Node3D.new()
	tent.name = "Tent%d" % index
	add_child(tent)
	tent.global_position = _at(p)
	tent.rotation.y = _face_fire(p)
	var w := 2.0 - 0.15 * float(index % 2)
	var l := 2.6
	var h := 1.65 - 0.1 * float(index % 3)
	var cloth := CLOTH if index % 2 == 0 else CLOTH_B
	Paper.part(tent, "Cloth", Paper.ridge_tent(w, l, h), cloth, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.03)
	Paper.part(tent, "Doorway", Paper.tent_door(w * 0.55, h * 0.78), DOORWAY, Vector3(0.0, 0.0, l * 0.5 + 0.02), Vector3(atan(0.08 / h), 0.0, 0.0), Vector3.ONE, 0.012)
	for end in [-1.0, 1.0]:
		var top := Vector3(0.0, h, (l * 0.5 + 0.08) * end)
		_stick(tent, top - Vector3(0.0, 0.05, 0.0), top + Vector3(0.0, 0.22, 0.0), 0.03, WOOD)
		# Guy ropes go out the ends, away from where anyone walks past the sides.
		_stick(tent, top, Vector3(0.0, 0.0, (l * 0.5 + 0.95) * end), 0.009, Color(0.62, 0.55, 0.42), 0.0)
		Paper.part(tent, "Peg", Paper.cylinder(0.025, 0.14, 4), WOOD, Vector3(0.0, 0.05, (l * 0.5 + 0.95) * end), Vector3.ZERO, Vector3.ONE, 0.0)
	# A rolled sleeping mat by the door.
	var mat := Node3D.new()
	tent.add_child(mat)
	mat.position = Vector3(w * 0.5 + 0.1, 0.1, l * 0.3)
	Paper.part(mat, "Mat", Paper.cylinder(0.1, 0.7, 7), Color(0.7, 0.55, 0.36), Vector3.ZERO, Vector3(PI * 0.5, 0.0, 0.0), Vector3.ONE, 0.015)
	_solid(tent, Vector3(0.0, h * 0.45, 0.0), Vector3(w * 0.9, h * 0.9, l))


## A small warm pool on the king's tent wall. The fire's own light stays on the log.
## People are unshaded, so this does not turn their skin blue or orange.
func _warm_the_tent() -> void:
	var at := _at(FIRE).lerp(_at(KING_TENT), 0.62)
	at.y += 1.35
	var light := OmniLight3D.new()
	light.name = "TentWarmth"
	light.light_color = Color(1.0, 0.58, 0.24)
	light.light_energy = 2.6
	light.omni_range = 3.6
	light.omni_attenuation = 1.7
	light.shadow_enabled = false
	add_child(light)
	light.global_position = at


func _build_lookout() -> void:
	var rocks := _valley_rocks()
	if rocks.is_empty():
		return
	var src := rocks[3 % rocks.size()] as MeshInstance3D
	var basis := Basis(Vector3.UP, 0.6).scaled(Vector3(1.1, 0.8, 1.1))
	_copy_with_outline(src, self, "LookoutStone", Transform3D(basis, _at(LOOKOUT) + Vector3(0.0, 0.1, 0.0)))


## A flag: a plain pole, a finial, and a cloth that waves and leans with the wind.
func _flag(index: int, p: Vector2, color: Color) -> void:
	var holder := Node3D.new()
	holder.name = "Banner%d" % index
	add_child(holder)
	holder.global_position = _at(p)
	holder.rotation.y = 0.35 * (1.0 if index % 2 == 0 else -1.0)
	_stick(holder, Vector3.ZERO, Vector3(0.0, 2.8, 0.0), 0.04, WOOD)
	Paper.part(holder, "Finial", Paper.sphere(0.07, 6), Color(0.86, 0.68, 0.28), Vector3(0.0, 2.84, 0.0))
	var cloth := MeshInstance3D.new()
	cloth.name = "Cloth"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, 0.6, 0.03)
	mesh.subdivide_width = 8
	mesh.subdivide_height = 2
	cloth.mesh = mesh
	var mat := ShaderMaterial.new()
	mat.shader = _flag_shader("specular_disabled")
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("phase", float(index) * 1.7)
	var ink := ShaderMaterial.new()
	ink.shader = _flag_shader("unshaded, cull_front")
	ink.set_shader_parameter("color", Paper.INK)
	ink.set_shader_parameter("phase", float(index) * 1.7)
	ink.set_shader_parameter("ink_scale", Vector3(1.0 + 0.05 / 0.9, 1.0 + 0.05 / 0.6, 2.0))
	mat.next_pass = ink
	cloth.material_override = mat
	holder.add_child(cloth)
	cloth.position = Vector3(0.49, 2.45, 0.0)
	_flag_mats.append(mat)
	_solid(holder, Vector3(0.0, 1.0, 0.0), null, 0.1, 2.0)


static var _flag_shaders: Dictionary = {}


func _flag_shader(mode: String) -> Shader:
	if _flag_shaders.has(mode):
		return _flag_shaders[mode]
	var shader := Shader.new()
	shader.code = FLAG_SHADER % mode
	_flag_shaders[mode] = shader
	return shader


## A collider so the child walks round a prop instead of through it: a box, or a
## cylinder when `size` is null. `at` is in the parent's space.
func _solid(parent: Node3D, at: Vector3, size: Variant, radius: float = 0.5, height: float = 1.0) -> void:
	var body := StaticBody3D.new()
	body.name = "Solid"
	parent.add_child(body)
	body.position = at
	var shape := CollisionShape3D.new()
	if size is Vector3:
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
	else:
		var cyl := CylinderShape3D.new()
		cyl.radius = radius
		cyl.height = height
		shape.shape = cyl
	body.add_child(shape)


func _guard(index: int, route: Array) -> void:
	var guard := Guard.new()
	guard.name = "Guard%d" % index
	guard.look = index
	guard.speed = 0.75 + 0.08 * float(index % 2)
	var pts := PackedVector2Array()
	for p in route:
		pts.append(Vector2(CAMP.x, CAMP.z) + p)
	guard.route = pts
	guard.ground = _ground
	add_child(guard)


func _place_jonathan() -> void:
	var jon := preload("res://scripts/jonathan.gd").new()
	jon.name = "Jonathan"
	add_child(jon)
	jon.global_position = _at(Vector2(-0.5, 1.0))
	# He looks toward the child coming up the path, half turned to the fire.
	var look := _at(Vector2(0.6, 6.0))
	jon.look_at(Vector3(look.x, jon.global_position.y, look.z), Vector3.UP)


func _build_owl() -> void:
	var tree: Node3D = null
	var trees := get_node_or_null("Trees")
	if trees:
		for t in trees.get_children():
			if t.has_meta("owl_tree"):
				tree = t
	if tree == null:
		return
	_owl = Owl.new()
	_owl.name = "Owl"
	_owl.audio = get_parent().get_node_or_null("AudioDirector")
	var top := (tree as MeshInstance3D).get_aabb().end.y * tree.scale.y
	var base := tree.global_position
	# Two branch tips on the camera side of the cypress, each with a little bare branch.
	var tips := [base + Vector3(0.42, top * 0.66, 0.5), base + Vector3(-0.5, top * 0.5, 0.46)]
	var holder := Node3D.new()
	holder.name = "OwlBranches"
	add_child(holder)
	for tip in tips:
		_stick(holder, base + Vector3(0.0, tip.y - base.y - 0.2, 0.0), tip + Vector3(0.0, -0.02, 0.0), 0.035, WOOD)
		_owl.perches.append(tip)
	_owl.facing = PI - 0.3
	add_child(_owl)


func _build_fireflies() -> void:
	_fireflies = Fireflies.new()
	_fireflies.name = "Fireflies"
	for i in FIREFLIES.size():
		_fireflies.homes.append(_at(FIREFLIES[i]) + Vector3(0.0, 0.55 + 0.12 * float(i % 4), 0.0))
	_fireflies.player = get_parent().get_node_or_null("Player") as Node3D
	add_child(_fireflies)


## Swaying grass, a few flowers and pebbles, the same as the meadow's, left off the
## path and away from the fire and tents.
func _build_grass() -> void:
	var grass := MeadowDressing.new()
	grass.name = "CampGrass"
	grass.area_min = Vector2(CAMP.x - 16.0, SEAM_Z + 0.8)
	grass.area_max = Vector2(CAMP.x + 15.5, CAMP.z + 20.0)
	grass.ground_y_range = Vector2(LEVEL - 0.6, LEVEL + 0.9)
	grass.tuft_count = 420
	grass.flower_count = 26
	grass.pebble_count = 40
	grass.seed_override = 11
	grass.player_path = ^"../../Player"
	var clear: Array[Vector3] = []
	var c := Vector2(CAMP.x, CAMP.z)
	clear.append(Vector3(c.x + FIRE.x, c.y + FIRE.y, 2.4))
	clear.append(Vector3(c.x + KING_TENT.x, c.y + KING_TENT.y, 3.4))
	for t in TENTS:
		clear.append(Vector3(c.x + t.x, c.y + t.y, 2.1))
	for i in PATH.size() - 1:
		var a: Vector2 = PATH[i]
		var b: Vector2 = PATH[i + 1]
		var steps := int(ceil(a.distance_to(b) / 0.8))
		for s in steps + 1:
			var q := a.lerp(b, float(s) / steps)
			clear.append(Vector3(c.x + q.x, c.y + q.y, 1.0))
	grass.clear_circles = clear
	add_child(grass)


## -- The blue hour ------------------------------------------------------------------

## A calm blue hour, bright enough to play in: a clear mid-blue sky, blue light
## on the ground, the far hills a step toward violet, and a soft moon. The fire
## and the lantern stay the only warm lights.
func _blue_hour() -> void:
	var world := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		var env := world.environment
		if env.sky:
			var sky := env.sky.sky_material as ProceduralSkyMaterial
			if sky:
				sky.sky_top_color = Color(0.24, 0.38, 0.7)
				sky.sky_horizon_color = Color(0.6, 0.66, 0.88)
				sky.ground_horizon_color = Color(0.52, 0.58, 0.8)
				sky.ground_bottom_color = Color(0.3, 0.36, 0.56)
		env.ambient_light_color = Color(0.6, 0.68, 0.96)
		env.ambient_light_energy = 0.95
		env.fog_light_color = Color(0.46, 0.54, 0.8)
		env.fog_density = 0.0045
	var sun := get_parent().get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = Color(0.66, 0.74, 1.0)
		sun.light_energy = 0.5
	var fill := get_parent().get_node_or_null("FillLight") as DirectionalLight3D
	if fill:
		fill.light_color = Color(0.5, 0.56, 0.9)
		fill.light_energy = 0.25
	var backdrop := get_parent().get_node_or_null("HorizonBackdrop")
	if backdrop and backdrop.has_method("set_blue_hour"):
		backdrop.set_blue_hour()
	if _moon == null:
		_moon = MeshInstance3D.new()
		_moon.name = "Moon"
		var quad := QuadMesh.new()
		quad.size = Vector2(7.0, 7.0)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.disable_fog = true
		m.albedo_texture = _crescent_texture()
		quad.material = m
		_moon.mesh = quad
		_moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_moon)
		_moon.global_position = Vector3(-26.0, 32.0, -60.0)
		_add_stars()


## A paper crescent, bright enough to see and small enough not to be a second sun.
func _crescent_texture() -> Texture2D:
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body := Vector2(0.44, 0.50)
	var bite := Vector2(0.62, 0.42)
	for y in n:
		for x in n:
			var p := Vector2(float(x) + 0.5, float(y) + 0.5) / float(n)
			var d_body := p.distance_to(body)
			var d_bite := p.distance_to(bite)
			if d_body < 0.30 and d_bite > 0.26:
				var edge := clampf((0.30 - d_body) / 0.025, 0.0, 1.0) * clampf((d_bite - 0.26) / 0.03, 0.0, 1.0)
				img.set_pixel(x, y, Color(0.98, 0.96, 0.88, edge))
	return ImageTexture.create_from_image(img)


func _add_stars() -> void:
	var tex := _star_texture()
	var at := [
		Vector3(-18.0, 34.0, 8.0), Vector3(-6.0, 39.0, -8.0), Vector3(10.0, 36.0, 2.0),
		Vector3(18.0, 33.0, 24.0), Vector3(-12.0, 31.0, 30.0), Vector3(3.0, 41.0, 28.0),
		Vector3(24.0, 35.0, -2.0),
	]
	for i in at.size():
		var star := MeshInstance3D.new()
		star.name = "Star%d" % i
		var quad := QuadMesh.new()
		quad.size = Vector2(0.7, 0.7)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.disable_fog = true
		m.albedo_texture = tex
		quad.material = m
		star.mesh = quad
		star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(star)
		star.global_position = at[i]


func _star_texture() -> Texture2D:
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(0.5, 0.5)
	for y in n:
		for x in n:
			var p := Vector2(float(x) + 0.5, float(y) + 0.5) / float(n)
			var d := p.distance_to(c)
			if d < 0.48:
				var arm := maxf(1.0 - absf(p.x - 0.5) * 7.0, 0.0) * maxf(1.0 - absf(p.y - 0.5) * 3.5, 0.0)
				arm = maxf(arm, maxf(1.0 - absf(p.y - 0.5) * 7.0, 0.0) * maxf(1.0 - absf(p.x - 0.5) * 3.5, 0.0))
				var disc := clampf(1.0 - d / 0.16, 0.0, 1.0)
				img.set_pixel(x, y, Color(0.98, 0.96, 0.88, clampf(maxf(arm, disc), 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## The blue hour tints shaded surfaces. People keep the paper colours they were
## painted with, plus a warm cheek only on the side turned toward the fire.
const PEOPLE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D albedo_tex : source_color, hint_default_white;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float use_tex = 1.0;
uniform vec3 fire_world = vec3(0.0);
uniform float warmth = 1.0;
varying vec3 world_pos;
varying vec3 world_normal;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 base = albedo_color.rgb;
	if (use_tex > 0.5) {
		base *= texture(albedo_tex, UV).rgb;
	}
	vec3 to_fire = fire_world - world_pos;
	float dist = length(to_fire);
	float facing = clamp(dot(world_normal, to_fire / max(dist, 0.001)), 0.0, 1.0);
	float near = smoothstep(4.8, 0.8, dist);
	ALBEDO = base + vec3(0.42, 0.16, 0.04) * facing * near * warmth;
}
"""


func _keep_people_paper() -> void:
	if _people_shader == null:
		_people_shader = Shader.new()
		_people_shader.code = PEOPLE_SHADER
	if _white_tex == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white_tex = ImageTexture.create_from_image(img)
	var main := get_parent()
	_paint_people(get_node_or_null("Jonathan"))
	_paint_people(main.get_node_or_null("DavidMentor"))
	_paint_people(main.get_node_or_null("Player"))
	for child in get_children():
		if str(child.name).begins_with("Guard"):
			_paint_people(child)


func _paint_people(root: Node) -> void:
	if root == null:
		return
	var fire := _at(FIRE)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var n := str(mi.name)
		if "Outline" in n or n.ends_with("Ink"):
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i) as StandardMaterial3D
			if mat == null:
				continue
			if mat.albedo_color.get_luminance() < 0.08:
				continue
			var sh := ShaderMaterial.new()
			sh.shader = _people_shader
			sh.resource_name = mat.resource_name
			sh.set_shader_parameter("albedo_color", mat.albedo_color)
			sh.set_shader_parameter("albedo_tex", mat.albedo_texture if mat.albedo_texture else _white_tex)
			sh.set_shader_parameter("use_tex", 1.0 if mat.albedo_texture else 0.0)
			sh.set_shader_parameter("fire_world", fire)
			sh.set_shader_parameter("warmth", 1.0)
			mi.set_surface_override_material(i, sh)
