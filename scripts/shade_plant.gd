extends Node3D
## The plant God made grow over Jonah on the hill outside Nineveh (Jonah 4:6-7): one broad-leaf
## plant that grows up quickly, its leaves unfolding one after another, and then withers the
## next day. Withering is shown as its leaves folding down and drying, one after another, never
## rot or anything crawling on it. `grown` and `withered` (0 to 1) drive it; grow() and wither()
## tween them.

const Paper := preload("res://scripts/camp_paper.gd")

const STEM := Color(0.36, 0.5, 0.26)
const LEAF := Color(0.42, 0.62, 0.3)
const DRY := Color(0.66, 0.58, 0.34)
const LEAVES := 6
const HEIGHT := 2.2

## 0 (a shoot) to 1 (full grown, leaves open).
var grown: float = 0.0
## 0 (green) to 1 (every leaf folded down and dry).
var withered: float = 0.0

var _stem: Node3D
var _leaves: Array[Node3D] = []
var _leaf_mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	_stem = Node3D.new()
	_stem.name = "Stem"
	add_child(_stem)
	Paper.part(_stem, "Stalk", Paper.cylinder(0.05, HEIGHT, 6, 0.035), STEM, Vector3(0.0, HEIGHT * 0.5, 0.0), Vector3.ZERO, Vector3.ONE, 0.012)
	for i in LEAVES:
		var holder := Node3D.new()
		holder.name = "Leaf%d" % i
		holder.position = Vector3(0.0, HEIGHT * lerpf(0.45, 1.0, float(i) / float(LEAVES - 1)), 0.0)
		holder.rotation.y = TAU * float(i) / float(LEAVES) + 0.4
		_stem.add_child(holder)
		var leaf := Paper.part(holder, "Blade", Paper.sphere(1.0, 8), LEAF, Vector3(0.62, 0.0, 0.0), Vector3.ZERO, Vector3(0.7, 0.05, 0.42), 0.012)
		var mat := (leaf.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		leaf.material_override = mat
		_leaf_mats.append(mat)
		_leaves.append(holder)
	_apply()


func grow(seconds: float = 3.0) -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "grown", 1.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tw


func wither(seconds: float = 3.0) -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "withered", 1.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


func _process(_delta: float) -> void:
	_apply()


func _apply() -> void:
	if _stem == null:
		return
	_stem.scale = Vector3.ONE * lerpf(0.08, 1.0, smoothstep(0.0, 1.0, grown))
	# The stalk droops a little as it dries.
	_stem.rotation.z = withered * 0.18
	for i in _leaves.size():
		# Each leaf unfolds a little after the one below it, and folds down in the same order.
		var open := clampf(grown * 1.6 - float(i) * 0.12, 0.0, 1.0)
		var fold := clampf(withered * 1.6 - float(i) * 0.12, 0.0, 1.0)
		_leaves[i].rotation.z = lerpf(1.2, 0.12, smoothstep(0.0, 1.0, open)) - fold * 1.25
		_leaf_mats[i].albedo_color = LEAF.lerp(DRY, fold)
