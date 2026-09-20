extends SceneTree
## Frame-cost profile of the main scene. Not part of the game.
##
## Needs the real renderer (not --headless). From the project folder:
##   godot --path . --script tools/profile_frame.gd --resolution 1280x720
##   godot --path . --rendering-method mobile --script tools/profile_frame.gd --resolution 1280x720
## The second line is how a phone or tablet build renders (Godot's default there is the Mobile
## renderer), so compare both.
##
## It prints two tables:
##   1. Triangles, mesh instances and surfaces (each surface is at least one draw call) by group.
##   2. CPU and GPU time, primitives, draw calls and objects per frame, first as the game is and then
##      with one thing switched off at a time, so the difference is what that thing costs. Primitives
##      and draw calls include the sun's shadow pass.
## Frames are measured with vsync off. Differences under about 0.05 ms are noise, and the costs do not
## add up to the total because parts share work. Absolute times only mean something on the device you
## run it on: the useful numbers on a fast computer are primitives and draw calls, and the ratios.
## docs/performance.md has the results and what they led to.

const WARM_FRAMES: int = 25
const SAMPLE_FRAMES: int = 100

var _main: Node
var _viewport: RID
var _frame: int = 0
var _variants: Array = []
var _index: int = 0
var _sampling: bool = false
var _phase_start: int = 0
var _undo: Callable
var _cpu_ms: float = 0.0
var _gpu_ms: float = 0.0
var _samples: int = 0
var _rows: Array = []


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	_viewport = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_viewport, true)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 30:
		_print_inventory()
		_variants = _make_variants()
		_start_variant()
		return false
	if _variants.is_empty():
		return false
	if not _sampling:
		if _frame - _phase_start >= WARM_FRAMES:
			_sampling = true
			_cpu_ms = 0.0
			_gpu_ms = 0.0
			_samples = 0
		return false
	_cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(_viewport) + RenderingServer.get_frame_setup_time_cpu()
	_gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(_viewport)
	_samples += 1
	if _samples < SAMPLE_FRAMES:
		return false
	_rows.append([_variants[_index][0], _cpu_ms / _samples, _gpu_ms / _samples,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))])
	_undo.call()
	_index += 1
	if _index >= _variants.size():
		_print_costs()
		quit()
		return false
	_start_variant()
	return false


func _start_variant() -> void:
	_undo = _variants[_index][1].call()
	_sampling = false
	_phase_start = _frame


# ---- what can be switched off ---------------------------------------------------------------------

func _make_variants() -> Array:
	var valley: Node = _main.get_node("BethlehemValley")
	var environment: Environment = (_main.get_node("WorldEnvironment") as WorldEnvironment).environment
	var sun: DirectionalLight3D = _main.get_node("Sun")
	var in_valley := func(prefix: String, node: Node) -> bool:
		return node is MeshInstance3D and valley.is_ancestor_of(node) and String(node.name).begins_with(prefix)
	return [
		["as the game is", func() -> Callable: return func() -> void: pass],
		["without David", func() -> Callable: return _hide([_main.get_node("DavidMentor")])],
		["without Wonder-Walker", func() -> Callable: return _hide([_main.get_node("Player")])],
		["without both characters", func() -> Callable: return _hide([_main.get_node("DavidMentor"), _main.get_node("Player")])],
		["without outline hulls", func() -> Callable: return _hide(_nodes(func(n: Node) -> bool: return n is MeshInstance3D and String(n.name).ends_with("_Outline")))],
		["without trees", func() -> Callable: return _hide(_nodes(func(n: Node) -> bool: return in_valley.call("Cypress", n) or in_valley.call("Olive", n)))],
		["without shrubs", func() -> Callable: return _hide(_nodes(func(n: Node) -> bool: return in_valley.call("Shrub", n)))],
		["without terrain", func() -> Callable: return _hide(_nodes(func(n: Node) -> bool: return in_valley.call("Valley_Terrain", n)))],
		["without stream pack and fish", func() -> Callable: return _hide([_main.get_node("StreamFishAlive"), _main.get_node("StreamFish")])],
		["without meadow grass and flowers", func() -> Callable: return _hide([_main.get_node("MeadowDressing")])],
		["sun shadows off", func() -> Callable:
			sun.shadow_enabled = false
			return func() -> void: sun.shadow_enabled = true],
		["glow off", func() -> Callable:
			environment.glow_enabled = false
			return func() -> void: environment.glow_enabled = true],
		["fog off", func() -> Callable:
			environment.fog_enabled = false
			return func() -> void: environment.fog_enabled = true],
		["3D drawn at half size (a quarter of the pixels)", func() -> Callable:
			root.scaling_3d_scale = 0.5
			return func() -> void: root.scaling_3d_scale = 1.0],
	]


func _nodes(keep: Callable) -> Array:
	var found: Array = []
	for node in _main.find_children("*", "Node3D", true, false):
		if keep.call(node):
			found.append(node)
	return found


## Hides these nodes and returns the callable that shows them again.
func _hide(nodes: Array) -> Callable:
	var before: Array = []
	for node in nodes:
		before.append([node, (node as Node3D).visible])
		(node as Node3D).visible = false
	return func() -> void:
		for entry in before:
			(entry[0] as Node3D).visible = entry[1]


# ---- reports ----------------------------------------------------------------------------------------

func _group_of(node: Node) -> String:
	var node_name: String = String(node.name)
	var path: String = str(_main.get_path_to(node))
	var group: String
	if path.begins_with("BethlehemValley"):
		group = "valley: terrain" if node_name.begins_with("Valley_Terrain") else "valley: " + node_name.get_slice("_", 0).to_lower()
	elif path.begins_with("StreamFishAlive"):
		group = "stream pack"
	elif path.begins_with("Player"):
		group = "Wonder-Walker"
	elif path.begins_with("DavidMentor"):
		group = "David"
	else:
		group = "other: " + path.get_slice("/", 0)
	return group + (" (outline)" if node_name.ends_with("_Outline") else "")


func _print_inventory() -> void:
	var triangles := {}
	var surfaces := {}
	var instances := {}
	for node in _main.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		var group: String = _group_of(node)
		for surface in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(surface)
			var indices = arrays[Mesh.ARRAY_INDEX]
			triangles[group] = triangles.get(group, 0) + (indices.size() if indices != null else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
		surfaces[group] = surfaces.get(group, 0) + mesh.get_surface_count()
		instances[group] = instances.get(group, 0) + 1
	var groups: Array = triangles.keys()
	groups.sort_custom(func(a: String, b: String) -> bool: return triangles[a] > triangles[b])
	var total: int = 0
	print("")
	print("%-32s %10s %10s %9s" % ["group", "triangles", "instances", "surfaces"])
	for group in groups:
		print("%-32s %10d %10d %9d" % [group, triangles[group], instances[group], surfaces[group]])
		total += triangles[group]
	print("%-32s %10d   (one copy of each mesh; shadows draw them again)" % ["total", total])


func _print_costs() -> void:
	var base_cpu: float = _rows[0][1]
	var base_gpu: float = _rows[0][2]
	print("")
	print("%-46s %7s %7s %11s %6s %8s" % ["", "CPU ms", "GPU ms", "primitives", "draws", "objects"])
	for row in _rows:
		print("%-46s %7.2f %7.2f %11d %6d %8d    GPU %+.2f  CPU %+.2f" % [row[0], row[1], row[2], row[3], row[4], row[5], row[2] - base_gpu, row[1] - base_cpu])
