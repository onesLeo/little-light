extends SceneTree
## Renders the app icon (Wonder Light's glow over the valley) at every size
## Android's adaptive-icon system and the desktop/editor icon need, using the
## same "draw with _draw(), capture the viewport, save PNG" technique already
## used by tests/chapter_visual_review.gd — no external image tool required.
##
## Run with the real renderer, not --headless (see docs/development.md):
##   godot --path . --script tools/render_app_icon.gd
##
## Writes:
##   assets/icons/legacy_192.png              -- Android "main" launcher icon (flattened)
##   assets/icons/adaptive_foreground_432.png  -- Android adaptive icon foreground (transparent bg)
##   assets/icons/adaptive_background_432.png  -- Android adaptive icon background (opaque)
##   assets/icons/adaptive_monochrome_432.png  -- Android 13+ themed icon (white silhouette, alpha only)

const OUTPUT_DIR := "res://assets/icons"

## Each icon layer to render: [file name, canvas size, mode].
## mode is one of "legacy", "foreground", "background", "monochrome" (see IconArt.draw below).
const JOBS := [
	["legacy_192", 192, "legacy"],
	["adaptive_foreground_432", 432, "foreground"],
	["adaptive_background_432", 432, "background"],
	["adaptive_monochrome_432", 432, "monochrome"],
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_run.call_deferred()


func _run() -> void:
	for job in JOBS:
		await _render(job[0], job[1], job[2])
	print("APP_ICON_RENDER_COMPLETE")
	quit()


func _render(file_stem: String, size: int, mode: String) -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(size, size)
	sub.transparent_bg = mode in ["foreground", "monochrome"]
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sub)

	var art := IconArt.new()
	art.canvas_size = size
	art.mode = mode
	sub.add_child(art)

	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw

	var image := sub.get_texture().get_image()
	var path := OUTPUT_DIR + "/" + file_stem + ".png"
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save icon: %s (%s)" % [path, error_string(error)])
	else:
		print("Wrote ", path, " (", size, "x", size, ", ", mode, ")")

	sub.queue_free()
	await process_frame


## Draws the icon: Wonder Light's warm glow above two valley peaks, the same
## composition as icon.svg. Kept as plain shapes (no textures) so it matches
## the game's flat paper-cutout style and stays legible at launcher size.
class IconArt extends Node2D:
	var canvas_size: int = 128
	var mode: String = "legacy"

	## Design space is a 128x128 unit square; _draw() scales it to canvas_size.
	const DESIGN := 128.0
	const BG_TOP := Color("fce29b")
	const BG_BOTTOM := Color("e8a93a")
	const GLOW_CORE := Color("fff6dc")
	const GLOW_MID := Color(1.0, 0.914, 0.659, 0.9)
	const GLOW_EDGE := Color(1.0, 0.914, 0.659, 0.0)
	const MOUNTAIN := Color("5a3a10")
	const MOUNTAIN_INK := Color("3a2408")
	const WHITE := Color(1, 1, 1, 1)

	func _draw() -> void:
		var s := canvas_size / DESIGN
		match mode:
			"background":
				_gradient_square(s)
			"legacy":
				_gradient_square(s)
				_glyph(s, 1.0, false)
			"foreground":
				_glyph(s, 0.72, false)
			"monochrome":
				_glyph(s, 0.72, true)

	## A vertical two-colour gradient filling the whole canvas (Gouraud-shaded quad).
	func _gradient_square(s: float) -> void:
		var d := DESIGN * s
		var points := PackedVector2Array([Vector2(0, 0), Vector2(d, 0), Vector2(d, d), Vector2(0, d)])
		var colors := PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM])
		draw_polygon(points, colors)

	## Wonder Light's glow plus the two-peak valley silhouette, in design-space
	## units, scaled by `s` and optionally shrunk toward the centre to respect
	## Android's adaptive-icon safe zone (the glyph must clear a centre-circle
	## mask). `mono` draws everything as a flat white alpha shape instead of
	## the warm palette, for Android's themed/monochrome icon.
	## Bounding-box centre of the glow + mountains composition, in design units.
	const GLYPH_CENTER := Vector2(64, 56)

	func _glyph(s: float, glyph_scale: float, mono: bool) -> void:
		var k := s * glyph_scale
		var to_local: Callable
		if glyph_scale >= 1.0:
			# Legacy/icon.svg layout: scale in place, same composition as icon.svg.
			to_local = func(p: Vector2) -> Vector2: return p * s
		else:
			# Shrink around the glyph's own centre and re-centre on the canvas,
			# so it clears Android's adaptive-icon safe-zone circle.
			to_local = func(p: Vector2) -> Vector2:
				return (p - GLYPH_CENTER) * k + Vector2(canvas_size, canvas_size) * 0.5

		# Glow: layered soft circles standing in for a radial gradient.
		if mono:
			draw_circle(to_local.call(Vector2(64, 46)), 34 * k, WHITE)
		else:
			draw_circle(to_local.call(Vector2(64, 46)), 34 * k, GLOW_EDGE)
			draw_circle(to_local.call(Vector2(64, 46)), 27 * k, GLOW_MID)
			draw_circle(to_local.call(Vector2(64, 46)), 14 * k, GLOW_CORE)

		# Two valley peaks.
		var peaks := PackedVector2Array([
			to_local.call(Vector2(18, 100)), to_local.call(Vector2(46, 62)),
			to_local.call(Vector2(62, 82)), to_local.call(Vector2(78, 56)),
			to_local.call(Vector2(110, 100)),
		])
		if mono:
			draw_colored_polygon(peaks, WHITE)
		else:
			draw_colored_polygon(peaks, MOUNTAIN)
			var outline := peaks.duplicate()
			outline.append(peaks[0])
			draw_polyline(outline, MOUNTAIN_INK, 3.0 * k, true)
