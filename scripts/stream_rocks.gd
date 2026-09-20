extends Node3D
## Gives the brook's rocks the valley's stone.
## The stream pack ships its rocks as flat tan 20-sided lumps, which read as cardboard boxes next
## to the mottled grey, limestone, slate and mossy stone the valley uses everywhere else. Each
## one is swapped for a valley stone mesh (with its outline), scaled to the size of the rock it
## replaces and turned a little so they do not all face the same way.
## Runs in _ready, so it is done before StreamAliveClean (deferred) and before the collision
## baker on the parent builds colliders from the new meshes.

@export var valley_path: NodePath = ^"../../BethlehemValley"
@export var art_path: NodePath = ^"../Art"
@export var rock_prefix: String = "Rock_"
## Set on outlines this script has restyled, so StreamAliveClean does not hide them.
const RESTYLED_META := "stone_restyled"


func _ready() -> void:
	var valley := get_node_or_null(valley_path) as Node3D
	var art := get_node_or_null(art_path) as Node3D
	if valley == null or art == null:
		return
	var stones := _valley_stones(valley)
	if stones.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1225
	var i := 0
	for node in art.find_children(rock_prefix + "*", "MeshInstance3D", true, false):
		var rock := node as MeshInstance3D
		if String(rock.name).ends_with("_Outline") or rock.mesh == null:
			continue
		var stone: MeshInstance3D = stones[(i * 7 + 1) % stones.size()]
		var outline := art.find_child(String(rock.name) + "_Outline", true, false) as MeshInstance3D
		_restyle(rock, outline, stone, valley, rng.randf() * TAU)
		i += 1


## The valley's stones, without their outlines, in a stable order. Pale limestone is left out:
## it is the colour the tan lumps were, and stones in a stream are darker anyway.
func _valley_stones(valley: Node3D) -> Array:
	var found := []
	for node in valley.find_children(rock_prefix + "*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if String(mi.name).ends_with("_Outline") or mi.mesh == null:
			continue
		var mat := mi.mesh.surface_get_material(0)
		if mat != null and mat.resource_name.findn("Limestone") >= 0:
			continue
		found.append(mi)
	found.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name) < String(b.name))
	return found


func _restyle(rock: MeshInstance3D, outline: MeshInstance3D, stone: MeshInstance3D, valley: Node3D, yaw: float) -> void:
	var old_box := rock.get_aabb()
	var new_box := stone.get_aabb()
	var fit: float = maxf(old_box.size.x, maxf(old_box.size.y, old_box.size.z)) \
		/ maxf(new_box.size.x, maxf(new_box.size.y, new_box.size.z))
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * fit)
	var placed := Transform3D(basis, old_box.get_center() - basis * new_box.get_center())
	rock.mesh = stone.mesh
	rock.transform = placed
	if outline == null:
		return
	var stone_outline := valley.find_child(String(stone.name) + "_Outline", true, false) as MeshInstance3D
	if stone_outline == null:
		return
	outline.mesh = stone_outline.mesh
	outline.transform = placed
	outline.visible = true
	outline.set_meta(RESTYLED_META, true)
