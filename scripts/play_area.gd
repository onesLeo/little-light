extends Resource
## Where the Wonder-Walker can go in a story: a rounded rectangle on the ground (x, z in
## world space), with a soft edge that pushes back gently (play_bounds.gd). Each story has
## one, tuned in the inspector on its node; the shell hands it to PlayBounds when the story
## starts (game_shell.gd switch_to).
## Use through a preload constant (no class_name):
##   const PlayArea := preload("res://scripts/play_area.gd")
##   PlayArea.new(Vector2(0.0, 2.4), Vector2(10.4, 8.2))

@export var center: Vector2 = Vector2.ZERO
@export var half_extents: Vector2 = Vector2(10.0, 10.0)
@export var corner_radius: float = 3.0


func _init(at: Vector2 = Vector2.ZERO, half: Vector2 = Vector2(10.0, 10.0), corner: float = 3.0) -> void:
	center = at
	half_extents = half
	corner_radius = corner
