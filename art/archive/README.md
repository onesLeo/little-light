# Archive

Old versions of the models, kept for reference and history. Godot ignores this folder (see
`.gdignore`), so nothing here is imported, loaded or shipped by the game.

`models/` holds 34 earlier models with their `.import` files and extracted textures: 9 of the
Wonder-Walker, 8 of David, 6 of the valley, 6 of the stream fish and 5 of the Wonder Items (version
numbers are not consecutive, since some were never kept). The game uses only the newest of each,
which stay in `assets/`: `wonder_walker_v13`, `david_mentor_v12`, `bethlehem_valley_v7`, `wonder_items_v7` and
`bethlehem_stream_fish_alive_v7`.

**To use one again**, move it (with its `.import` and `.uid` files and any textures named after it)
back into `assets/` and open the project so Godot imports it.

**Build scripts.** The Blender scripts in `art/blender/scripts` for the older versions
(`polish_valley_v3` to `v5`, `recolor_characters_v2` / `v3`, `fix_outlines_v6`, the preview
renderers) read these models as inputs from `assets/`. To re-run one of them, first move the model it
names back into `assets/`. The current valley (`polish_valley_v7.py`) is built procedurally and needs
no old model.
