extends Node3D
## David's valley, chapter 1, in its own scene (scenes/chapters/bethlehem_valley.tscn): the
## terrain, the brook, the meadow and the ring of hills, David and his sheep, the three
## Wonder Items, Steady Hands, and the story itself (chapter_director.gd). The shell loads
## it and frees it like any story (game_shell.gd). The King's Camp stands on its ridge, so
## the shell keeps the valley loaded under the camp, with its story stood down.
##
## Its pieces reach the shared player, cameras, UI and sound through the shell
## (GameShell.of), never through paths out of this scene.

const PlayArea := preload("res://scripts/play_area.gd")

## The valley's daylight (chapter_look.gd); the shell applies it when the valley starts.
@export var look: Resource = preload("res://assets/looks/valley_day.tres")
## Where the walker can go in the valley (play_area.gd); the shell hands it to PlayBounds.
@export var play_area: Resource = PlayArea.new(Vector2(0.0, 2.4), Vector2(10.4, 8.2))


## Starts chapter 1 from its first line, in the valley as it is. Only the shell calls this.
func visit() -> void:
	var story := get_node_or_null("ChapterDirector")
	if story and story.has_method("begin_valley"):
		story.begin_valley()


## True while chapter 1 is under way.
func in_progress() -> bool:
	var story := get_node_or_null("ChapterDirector")
	return story != null and story.beat != story.Beat.DONE and story.beat != story.Beat.CAMP


## Another story is starting: chapter 1 stops listening, and the valley stays as scenery
## (under the camp) or is freed next (anywhere else).
func stand_down() -> void:
	var story := get_node_or_null("ChapterDirector")
	if story and story.has_method("stand_down"):
		story.stand_down()
