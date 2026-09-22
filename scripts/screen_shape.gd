extends Node
## Keeps the picture framed the same way on any screen shape.
## The game is designed at 16:9 (1280 x 720). Tablets are often 16:10 or 4:3, and phones 20:9. The
## stretch setting is "expand", so menus and buttons simply use the extra room (they are anchored to the
## edges). This handles the 3D picture: on a screen narrower than 16:9 each camera keeps its view
## *width*, so the sides of the valley stay in shot and there is more sky and ground above and below
## instead of the sides being cut off. On a wider screen it keeps the height, so a wide screen shows a
## bit more valley to the sides.

const DESIGN_ASPECT := 16.0 / 9.0


func _ready() -> void:
	get_viewport().size_changed.connect(apply)
	apply()


func apply() -> void:
	var size := get_viewport().get_visible_rect().size
	if size.y <= 0.0:
		return
	for node in get_parent().find_children("*", "Camera3D", true, false):
		(node as Camera3D).keep_aspect = Camera3D.KEEP_WIDTH if size.x / size.y < DESIGN_ASPECT - 0.01 else Camera3D.KEEP_HEIGHT
