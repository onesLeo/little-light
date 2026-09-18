# Art & Tech Pipeline Reference

## Engine & Exchange Format

Godot (free, open-source) paired with Blender, connected via **glTF** — both tools have solid native support for it ([source](https://studio.blender.org/blog/our-workflow-with-blender-and-godot/)). This is the same combination DOGWALK's own team used, so their published workflow is a direct reference.

## A Right-Sized Workflow for a Small or Solo Team

DOGWALK's studio pipeline used a custom Blender extension plus a Godot import plugin to manage hundreds of assets automatically — unique IDs, de-duplicated nested instances, auto-extracted materials. That's built for a full team, and more than a first prototype needs.

For a first chapter, a simpler path is enough:

1. Model each diorama piece as a low-poly mesh in Blender.
2. Get the papercraft look without physical scanning equipment: flat/matte shading, a paper-grain texture, and thin dark edge outlines — an inexpensive stand-in for DOGWALK's scanned real paper models.
3. Export straight from Blender's built-in glTF exporter; no custom tooling needed at this scale.
4. Import into Godot, which reads glTF natively.
5. Revisit DOGWALK's custom asset pipeline, linked below, only once the project grows past a handful of artists or hundreds of assets.

## The Stylized Stop-Motion Character Look

DOGWALK's chunky, handmade character animation comes from a specific, documented technique ([source](https://studio.blender.org/blog/playable-stop-motion-in-godot/)):

- Gameplay logic still runs at a full 60fps, but the *visible* animation poses update at only about 12fps ("animating on 2s") for that frame-by-frame, stop-motion feel.
- In Blender's glTF export settings, set "Sampling Interpolation Fallback" to "Step" so poses hold instead of blending.
- In Godot, turn off the AnimationPlayer's "Optimizer" setting, which otherwise strips out those held keyframes.
- A small helper script (their "ValueSlicer") avoids flicker by only updating a value once it crosses a threshold, rather than every frame.

## Further Reading

- [Our Workflow with Blender and Godot](https://studio.blender.org/blog/our-workflow-with-blender-and-godot/) — the full Blender-to-Godot pipeline.
- [Playable Stop Motion in Godot](https://studio.blender.org/blog/playable-stop-motion-in-godot/) — the low-fps character animation technique.
- [Dogwalk Asset Creation Process](https://studio.blender.org/blog/dogwalk-asset-creation-process/) — the paper-craft asset pipeline (full article requires a Blender Studio membership).

## Getting Started With No Prior Experience

You don't need a game-dev or 3D background to start. Here's what's realistic, and what I can and can't do directly.

**What I can do with you:**

- Write real GDScript or Godot project files with you in an actual coding session — not just plan them here.
- Walk through Blender step by step in words for simple low-poly shapes; this papercraft look is one of the most beginner-friendly 3D styles there is.
- Research and recommend free, ready-made assets so you're not modeling everything from scratch on day one.
- Review and debug whatever we build together.

**What I can't do directly:**

- Click around inside Blender's or Godot's own visual editor for you. Those are hands-on tools you (or a future collaborator) operate; I can guide every step, but not run the mouse in that software myself from a planning doc like this one.

**A realistic starting path:**

1. Skip hand-modeling everything at first: start with a free, CC0 low-poly pack like [Kenney's Nature Kit](https://kenney.nl/assets/nature-kit) for the Lantern Room hub and first diorama's terrain, then swap in custom papercraft pieces later.
2. Work through Godot's official "Your First Game" tutorial, built for complete beginners.
3. For scripting, GDScript (Godot's own, Python-like language) has the largest beginner tutorial base; Godot also supports C#, which would feel more familiar coming from Java's syntax if you'd rather start there.
4. When you're ready to write real code, start a coding session with me and we build the Godot project file by file, together — not just planned in a doc.

**On ordering:** modeling doesn't need to finish before Godot starts. The common approach is the reverse — wire up the gameplay in Godot first using placeholder assets (like Kenney's pack), get movement, the camera, and the mini-game feeling right, then swap in real papercraft models once the loop is proven. That way no art effort is wasted on mechanics that still might change.
