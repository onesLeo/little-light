extends Button
## One of the verse words a child taps (chapter 1: Don't / Be / Afraid, chapter 2: Knit /
## Loved / Friend). Paper and ink like the rest of the UI, with a warm glow that tells her
## what she has done:
## - waiting: gold, and the next word to tap breathes a little and glows softly;
## - tapped: it pops, a ring and a handful of sparkles fly out, then it stays lit, a soft
##   gold light around it with a tick badge and two twinkles, so she can see which words
##   she has said.
## Each word keeps its own glow, so three lit words never run together into one block.
## Use through a preload constant (no class_name):
##   const WordChip := preload("res://scripts/word_chip.gd")

const PaperUI := preload("res://scripts/paper_ui.gd")

const WAIT_FILL := PaperUI.GOLD
const LIT_FILL := Color(1.0, 0.93, 0.55)
const GLOW := Color(1.0, 0.8, 0.25)
const SPARK := Color(1.0, 0.96, 0.7)

var lit: bool = false
var beckon: bool = false

var _t: float = 0.0
var _glow: float = 0.0
var _burst: float = 0.0
var _sparks: Array[Dictionary] = []
var _halo: Control
var _fx: Control
var _pop: Tween


func _init(word: String, min_size: Vector2, font_size: int) -> void:
	text = word
	custom_minimum_size = min_size
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", font_size)
	for color_name in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		add_theme_color_override(color_name, PaperUI.INK)
	for state in ["normal", "hover", "focus", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = WAIT_FILL
		sb.border_color = PaperUI.INK
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(22)
		add_theme_stylebox_override(state, sb)
	# The light sits behind the word; the sparkles, twinkles and tick sit in front.
	_halo = Control.new()
	_halo.name = "Glow"
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_halo.show_behind_parent = true
	_halo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_halo.draw.connect(_draw_halo)
	add_child(_halo)
	_fx = Control.new()
	_fx.name = "Sparkles"
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	_paint()


## Lit once she has tapped it; it stays lit.
func set_lit(on: bool) -> void:
	if lit == on:
		return
	lit = on
	if not lit:
		_sparks.clear()
		_burst = 0.0
	_paint()


## The word she might tap next: a slow breath and a soft glow, never a flash.
func set_beckon(on: bool) -> void:
	beckon = on and not lit


## The tap itself: a squash and pop, a ring going out and sparkles flying off.
func pop() -> void:
	pivot_offset = size * 0.5 if size.x > 1.0 else custom_minimum_size * 0.5
	if _pop and _pop.is_valid():
		_pop.kill()
	scale = Vector2(0.9, 0.9)
	_pop = create_tween()
	_pop.tween_property(self, "scale", Vector2(1.14, 1.14), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pop.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_burst = 1.0
	_glow = 1.6
	var centre := (size if size.x > 1.0 else custom_minimum_size) * 0.5
	for i in 12:
		var angle := TAU * i / 12.0 + randf_range(-0.2, 0.2)
		_sparks.append({
			"pos": centre + Vector2(cos(angle) * centre.x * 0.7, sin(angle) * centre.y * 0.7),
			"vel": Vector2(cos(angle), sin(angle)) * randf_range(140.0, 260.0),
			"life": randf_range(0.45, 0.75),
			"age": 0.0,
			"size": randf_range(6.0, 11.0),
		})


func _paint() -> void:
	for state in ["normal", "hover", "focus", "pressed"]:
		var sb := get_theme_stylebox(state) as StyleBoxFlat
		if sb == null:
			continue
		var fill := LIT_FILL if lit else WAIT_FILL
		if state == "hover":
			fill = fill.lightened(0.1)
		elif state == "pressed":
			fill = fill.darkened(0.06)
		sb.bg_color = fill
		sb.border_color = Color(0.55, 0.32, 0.06) if lit else PaperUI.INK
		sb.set_border_width_all(4 if lit else 3)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	var target := 1.0 if lit else (0.35 if beckon else 0.0)
	_glow = move_toward(_glow, target, delta * (3.0 if _glow > target else 2.0))
	_burst = maxf(_burst - delta * 1.8, 0.0)
	for spark in _sparks:
		spark["age"] += delta
		spark["pos"] += spark["vel"] * delta
		spark["vel"] *= 0.9
	_sparks.assign(_sparks.filter(func(s: Dictionary) -> bool: return s["age"] < s["life"]))
	if beckon and not lit and (_pop == null or not _pop.is_valid()):
		pivot_offset = size * 0.5
		scale = Vector2.ONE * (1.0 + 0.04 * (0.5 + 0.5 * sin(_t * 3.4)))
	elif not lit and scale != Vector2.ONE and (_pop == null or not _pop.is_valid()):
		scale = Vector2.ONE
	_halo.queue_redraw()
	_fx.queue_redraw()


## A soft light the shape of the word: a few rounded layers, fading outward, breathing
## gently while lit. Kept within about 20 px so neighbours do not merge.
func _draw_halo() -> void:
	if _glow <= 0.01:
		return
	var breath := 0.85 + 0.15 * sin(_t * 2.2) if lit else 0.7 + 0.3 * sin(_t * 3.4)
	var amount := minf(_glow * breath, 1.4)
	var rect := Rect2(Vector2.ZERO, size)
	for i in 5:
		var grow := 4.0 + i * 4.0
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(int(22.0 + grow))
		sb.bg_color = Color(GLOW, clampf(0.28 * amount * (1.0 - i / 5.0), 0.0, 1.0))
		sb.anti_aliasing = true
		_halo.draw_style_box(sb, rect.grow(grow))


func _draw_fx() -> void:
	var s := size
	# The ring from a tap, going out and fading.
	if _burst > 0.0:
		var k := 1.0 - _burst
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.set_corner_radius_all(int(22.0 + k * 30.0))
		sb.border_color = Color(1.0, 0.86, 0.35, _burst)
		sb.set_border_width_all(int(2.0 + 4.0 * _burst))
		_fx.draw_style_box(sb, Rect2(Vector2.ZERO, s).grow(6.0 + k * 34.0))
	for spark in _sparks:
		var fade: float = 1.0 - spark["age"] / spark["life"]
		_star(spark["pos"], spark["size"] * (0.4 + 0.6 * fade), Color(SPARK, fade))
	if not lit:
		return
	# Two twinkles on opposite corners, taking turns.
	var tw1 := 0.5 + 0.5 * sin(_t * 3.0)
	var tw2 := 0.5 + 0.5 * sin(_t * 3.0 + PI)
	_star(Vector2(10.0, 8.0), 5.0 + 6.0 * tw1, Color(1.0, 1.0, 0.9, 0.5 + 0.5 * tw1))
	_star(Vector2(s.x - 14.0, s.y - 8.0), 5.0 + 6.0 * tw2, Color(1.0, 1.0, 0.9, 0.5 + 0.5 * tw2))
	# The tick badge: this one is said.
	var c := Vector2(s.x - 6.0, 6.0)
	_fx.draw_circle(c, 15.0, Color(0.36, 0.62, 0.26))
	_fx.draw_arc(c, 15.0, 0.0, TAU, 24, PaperUI.INK, 2.5, true)
	_fx.draw_polyline(PackedVector2Array([c + Vector2(-7.0, 0.0), c + Vector2(-2.0, 5.5), c + Vector2(7.5, -5.5)]), Color.WHITE, 3.5, true)


## A four-point sparkle.
func _star(at: Vector2, radius: float, color: Color) -> void:
	var thin := radius * 0.28
	_fx.draw_colored_polygon(PackedVector2Array([
		at + Vector2(0.0, -radius), at + Vector2(thin, -thin), at + Vector2(radius, 0.0), at + Vector2(thin, thin),
		at + Vector2(0.0, radius), at + Vector2(-thin, thin), at + Vector2(-radius, 0.0), at + Vector2(-thin, -thin)]), color)
