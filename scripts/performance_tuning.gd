extends Node
## Keeps the game light enough for a tablet without changing how it looks on a computer.
##
## - Outline hulls (the dark inked edge around the characters, trees and rocks) do not cast
##   shadows. A hull is a slightly bigger copy of its mesh, so it was drawn into the shadow map a
##   second time; that was about a quarter of everything the sun's shadow pass drew.
## - On a phone or tablet the 3D picture is drawn at most `max_render_width` pixels wide and scaled
##   up to the screen. Tablet screens are often 2000+ pixels wide, which is four times the pixels
##   of the 1280 x 720 the game is designed at, and the fragment work grows with them. The menus and
##   dialogue are 2D and stay sharp. Computers are not touched.
## - On a phone or tablet the glow (bloom) is off. It needs an extra full-screen HDR pass that mobile
##   GPUs pay a lot for, and screenshots with it on and off are almost the same (a little less sparkle
##   on the water). The Wonder Light's halo is its own mesh, so it still glows.
## See docs/performance.md for the measurements behind this.

@export var max_render_width: int = 1600
## Turn on to apply the render-size cap on a computer too (the smoke test does).
@export var cap_on_computers: bool = false
## Keep the glow on a phone or tablet too. Try it once the game runs on a tablet and the frame time allows.
@export var glow_on_handhelds: bool = false

const OUTLINE_SUFFIX := "_Outline"


func _ready() -> void:
	# Deferred, so scripts that build or restyle meshes in _ready (the brook rocks) are done first.
	call_deferred("_stop_outline_shadows")
	get_window().size_changed.connect(_update_render_scale)
	_update_render_scale()
	apply_glow(OS.has_feature("mobile"))


## Fraction of the window's width to render the 3D picture at: 1.0 when the window is not wider
## than the cap, and never below 0.5 so a very large screen still gets a picture worth looking at.
static func render_scale_for(window_width: float, cap: float) -> float:
	if window_width <= cap or window_width <= 0.0:
		return 1.0
	return maxf(cap / window_width, 0.5)


func _update_render_scale() -> void:
	if not (cap_on_computers or OS.has_feature("mobile")):
		return
	get_viewport().scaling_3d_scale = render_scale_for(float(get_window().size.x), float(max_render_width))


## Switches the scene's glow off for a handheld (unless glow_on_handhelds) and back on for anything else.
func apply_glow(handheld: bool) -> void:
	for node in get_parent().find_children("*", "WorldEnvironment", true, false):
		var env := (node as WorldEnvironment).environment
		if env != null:
			env.glow_enabled = not handheld or glow_on_handhelds


func _stop_outline_shadows() -> void:
	for node in get_parent().find_children("*" + OUTLINE_SUFFIX, "MeshInstance3D", true, false):
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
