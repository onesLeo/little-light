extends Resource
## How a story looks and sounds when it starts: the sky, the ambient light and haze, the
## sun and fill lights, the valley's ring of hills behind it, whether the soundscape is at
## night, and how the tabletop camera frames the Wonder-Walker. The shell applies it when
## the story starts (game_shell.gd apply_look), so a story never has to undo the one
## before it. Weather inside a story (the ark's flood) starts from it and tweens on.
##
## Each story's look is a .tres in assets/looks/, tuned in the inspector.
## Use through a preload constant (no class_name):
##   const ChapterLook := preload("res://scripts/chapter_look.gd")

@export_group("Sky")
@export var sky_top: Color = Color(0.5, 0.72, 0.92)
@export var sky_horizon: Color = Color(0.98, 0.91, 0.78)
@export var ground_horizon: Color = Color(0.98, 0.91, 0.78)
@export var ground_bottom: Color = Color(0.7, 0.8, 0.6)

@export_group("Air")
@export var ambient_color: Color = Color(1.0, 0.92, 0.78)
@export var ambient_energy: float = 1.15
@export var fog_color: Color = Color(0.96, 0.9, 0.78)
@export var fog_density: float = 0.003

@export_group("Lights")
@export var sun_color: Color = Color(1.0, 0.93, 0.78)
@export var sun_energy: float = 1.1
@export var fill_color: Color = Color(0.75, 0.85, 1.0)
@export var fill_energy: float = 0.55

@export_group("World")
## The valley's ring of hills and clouds: as painted, recoloured for the blue hour, or hidden.
@export_enum("day", "blue_hour", "hidden") var backdrop: String = "day"
## Night sounds instead of the day's birds and breeze (soundscape.gd).
@export var night: bool = false

@export_group("Camera")
@export var camera_offset: Vector3 = Vector3(0.0, 8.7, 10.1)
@export var camera_look_height: float = 0.7
@export var camera_fov: float = 40.0
