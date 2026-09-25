# Little Light — David & Goliath P0.2 (Godot slice)

[![Smoke test](https://github.com/onesLeo/little-light/actions/workflows/smoke-test.yml/badge.svg)](https://github.com/onesLeo/little-light/actions/workflows/smoke-test.yml)

Working on the game? See the [development guide](docs/development.md): setup, tests, CI, and what is committed.

Vertical slice: Wonder-Walker explores a Bethlehem valley diorama, finds three Wonder Items, meets David (Band A), hears **Joshua 1:9**, breathes that promise with him in **Steady Hands**, then watches him walk out. No violence is shown. Wonder-Walker is a **guest**, not David. Courage comes from God being with David, not from feeling calm.

**Engine:** project configuration declares Godot **4.7** (Forward+). Compatibility with older 4.x versions has not been verified.

## Open & run

1. Open Godot matching the **4.7** version declared in `project.godot`.
2. **Import** → choose `project.godot` in this folder (`little-light-godot/`).
3. Wait for the GLB assets to finish importing (see the current asset list below).
4. Press **F5** (main scene: `res://scenes/main.tscn`).

## Controls

| Action   | Keyboard      | Gamepad         | Touch                          | Notes |
|----------|---------------|-----------------|--------------------------------|-------|
| Move     | WASD / arrows | Left stick / D-pad | Drag a thumb on the left half of the screen | Camera-relative; avatar faces move direction |
| Continue | Space / Enter | A               | Big gold button (says **NEXT**) | Advance dialogue |
| Breathe  | Hold Space / Enter | Hold A     | Hold the big gold button (says **BREATHE**) | Hold to breathe in, let go to breathe out; three slow breaths finish Steady Hands |
| Interact | E             | A or X          | Big gold button (says **GRAB**) | Collect a Wonder Item when near it |
| Pause    | Esc / P       | Start           | Round pause button, top right  | Resume, read-aloud, volume, music / sounds / voices, play again |

On-screen prompts reword themselves for whichever device you used last ("Press Space" / "Press A" / "Tap NEXT", "Hold Space" / "Hold A" / "Hold BREATHE").
The big touch button is only shown while touch is in use, and it sends both "continue" and "interact", so a child never has to choose.
The speaker button (top right) turns **read-aloud** on or off; settings are saved to `user://settings.cfg`.

## What you'll play through

1. **Arrive** — Wonder Light names this as **David's valley**: he looks after sheep, God looks after him
2. **Explore** — find David's 3 Wonder Items (stone / staff / lamb), placed at random spots in the meadow each run; press **E** (or tap GRAB). A checklist keeps their purpose visible. If nothing is found for ~18 s, a bobbing arrow (and an edge-of-screen arrow) points to the nearest missing item
3. **Meet David** — the found items are brought to him. David says God gave him these sheep to keep safe, then speaks 1 Samuel 17:37 in his own words: the Lord kept him safe from the lion and the bear, and will keep him safe now. Wonder Light names that job as why he will go.
4. **The Word** — Joshua 1:9 (WEB) is read aloud, in two short pages: first the verse and what *Yahweh* means, then (after NEXT) the three words to say with David. Then she taps **Don't**, **Be**, and **Afraid**, in any order. Each tap says that word. Nothing is marked wrong. Only then does the breathing begin. Wonder Light also says **Yahweh is God's name** — so courage is God-with-you, not a feeling.
5. **Steady Hands** — hold **Space** to breathe that promise in and let go to breathe it out, three slow breaths (Band A; cannot be failed, see [docs/steady-hands.md](docs/steady-hands.md))
6. **Resolution** — narrated off-screen; David takes the small stone (God can use even a small thing), the camp cheers his name, then the text clearly says that David trusted God, faced Goliath with his sling, and defeated him, while no fight is shown
7. **Reflect** — “Being brave doesn't mean you're not scared. It means you go with God anyway.” Then: God had a job for David. He has one for you too. Stay close, and remember the words.
8. **Courage charm** — animated placeholder bracelet/charm ceremony, then **“God was with David. God is with you.”**, then a **Play again / Keep exploring** panel

## Current scene assets

`scenes/main.tscn` (the Wonder-Walker) and `scenes/chapters/bethlehem_valley.tscn` (the rest) load these assets;
older versions were moved to `art/archive/models/` (see its README).

| Scene role | Asset |
|------------|-------|
| Wonder-Walker | `assets/wonder_walker_v13.glb` |
| Bethlehem valley | `assets/bethlehem_valley_v7.glb` |
| David mentor | `assets/david_mentor_v13.glb` |
| Wonder Items | `assets/wonder_items_v7.glb` |
| Animated stream | `assets/bethlehem_stream_fish_alive_v7.glb` |

## Project layout

```
little-light-godot/
  project.godot
  scenes/main.tscn          # what every story shares: the Wonder-Walker, cameras, UI, menus, sound
  scenes/chapters/          # one scene per story: bethlehem_valley, kings_camp, noahs_ark
  scripts/
    wonder_walker.gd
    steady_hands_minigame.gd
    chapter_director.gd
    camera_director.gd
    tabletop_camera.gd
    charm_award.gd
    audio_director.gd       # chimes, footsteps + read-aloud (recorded clips, system speech as fallback)
    soundscape.gd           # music, wind, stream, birds; ducks under the voice
    sound_bus.gd            # Music / Ambience / Effects / Voice buses and the volume mix
    sound_library.gd        # where the synthesized sound files live
    vo_library.gd           # spoken line -> recorded voice clip (assets/audio/vo)
    input_setup.gd          # gamepad bindings, pause action, last-used-device tracking
    touch_controls.gd       # floating thumb stick + big NEXT/GRAB/BREATHE button
    game_menu.gd            # pause menu, speaker button, Play again panel
    game_settings.gd        # read-aloud + volume mix, saved to user://settings.cfg
    wonder_item_scatter.gd  # random item placement
    wonder_item_hints.gd    # idle hint arrows
    horizon_backdrop.gd     # layered hills and drifting clouds beyond the valley
    meadow_dressing.gd      # swaying grass tufts, flowers and pebbles
    stream_water_fx.gd      # applies assets/shaders/stream_water.gdshader to the brook
    play_bounds.gd          # soft edge of the valley (rubber-band push + friendly nudge)
    lamb_life.gd            # the collectible lamb turns to you and hops
    butterflies.gd          # paper butterflies that flutter away when approached
  assets/                # GLB models, textures, and shaders
  art/blender/           # Asset generators and pipeline documentation
  art/previews/          # Saved valley renders
  art/archive/models/    # earlier model versions, ignored by Godot
  tests/                 # Headless smoke test and screenshot helper
  docs/                  # Improvement backlog (what to work on next)
```

## Notes / placeholders

- Valley, WW, David mentor, and wonder-item meshes are placeholder GLBs.
- Safety floor under the diorama so the player cannot fall forever.
- Tabletop camera is a `Camera3D` sibling of the player under `Main`. It follows from above/behind without inheriting the player's rotation; `CameraDirector` switches to a separate close-up camera for dialogue and the charm ceremony.
- Courage charm uses procedural placeholder 3D meshes with a float/snap animation. The child's own colouring of the charm (see the Faith Journal below) is put on its face.
- Dialogue and narration are displayed as text **and read aloud** with recorded voice clips: Wonder Light is Juno, David is Bram (`assets/audio/vo`, see [docs/voice-over.md](docs/voice-over.md)). A line with no clip falls back to the operating system's text-to-speech voice, so its availability depends on the OS; with neither, the speaker button is hidden. The valley also has music, wind, a stream, birds, footsteps, a bleating lamb and fluttering butterflies, all synthesized by `tools/make_sounds.py` (see [docs/sound-design.md](docs/sound-design.md)).
- Touch controls and gamepad bindings are verified with injected input events and the headless smoke test, not yet on a real tablet or controller.

## What to improve next

See [docs/improvement-backlog.md](docs/improvement-backlog.md) for the full review (done and still open): game feel, visual polish, performance and repo hygiene.

Chapter 2, **The King's Camp**, is implemented and documented in
[docs/chapter-2-concept.md](docs/chapter-2-concept.md). The planned five-journey first volume is in
[docs/five-journey-roadmap.md](docs/five-journey-roadmap.md), with full concepts for
[The Beginning](docs/chapter-3-concept.md), [Noah's Ark](docs/chapter-4-concept.md), and
[Jonah and the Great Fish](docs/chapter-5-concept.md).

Releasing a public demo is only a plan so far, not done: see [docs/release-plan.md](docs/release-plan.md) (a browser build, so nobody has to download a big file).


## Band notes
- **Band A Steady Hands:** three slow breaths (hold to breathe in, let go to breathe out); it cannot be failed and cannot be rushed. This replaced the old one-tap design.
- **Who is playing and the Faith Journal:** each child on a tablet picks a name and a picture (up to 4), and has their own journal of the verses and charms they earn, read aloud when tapped (round book button, pause menu, end panel). Saved on the tablet only. A press-and-hold "For grown-ups" area can empty a journal or remove a child. A child can also colour their Courage charm (tap a paint, tap a part) from the journal or the end-of-chapter panel; it shows in the journal and on the charm in the ceremony. See [docs/faith-journal.md](docs/faith-journal.md).
- **Band B is intentionally deferred.** The age question on "Who is playing?" (8 or younger / 9 or older, see the Faith Journal above) already collects the split Band B would use, but nothing reads it for gameplay yet — every child gets Band A's Meet David (an auto line, no reply choices) and Steady Hands (three breaths, cannot be rushed or failed). Band B — reply choices at Meet David, a longer Steady Hands — stays a documented idea, not a task, until it's picked up on purpose.

- Historical Wonder-Walker **v3** introduced paper-grain material and a 12fps step walk animation; the scene now loads **v13**.

## Controls tip
WASD is **camera-relative** (W walks toward the top of the screen). Movement unlocks after the first Space on Arrive. Arrows also work.

## Lighting
Target: soft **paper-warm** diorama (not harsh studio). Lower sun, strong warm ambient, soft shadows, ACES tonemap.

## Collision
Valley + David meshes bake **trimesh StaticBody** colliders at runtime so the walker cannot pass through solids.


## Valley polish (v3)
- Paper-craft cypress + olive trees, shrubs, and rocks on the Judean hills silhouette.
- Flat matte materials + inverted-hull outlines (same paper-diorama look).
- Center play space kept mostly clear for roaming.


## Valley v6 and historical outline fixes

The scene now uses **valley v7**, which is v6 with new trees, bushes and rocks (leafy olives and cypress columns; leafy shrubs; stone-textured rocks in four
variants, one mossy) — see `art/blender/scripts/polish_valley_v7.py`. Trees stand only on grass: ten that v6 put on the bare back wall or on the lip of
the shelf are moved by `TREE_MOVES` in that script. Character and prop versions are listed above.
`bethlehem_valley_v6.glb` (now in `art/archive/models/`) is sculpted terrain
(valley floor, walls, back ridge, a cliff shelf) with the river carved into it
— an upper reach, a waterfall, a plunge pool and a lower reach — rather than
props laid on a flat slab. The character/prop `_v6` files are the v4/v5 models
with their outline hulls rebuilt: the old Solidify hulls rendered in Godot as
an opaque shell that made every character a black silhouette. Both are
generated from `art/blender/scripts/` — see that folder's README.

`SafetyFloor` sits at y=-2.5 because the riverbed is carved below y=0; at its
old y=-0.5 its top face capped the channel.

## Verification helpers

After the assets have been imported, run the existing gameplay smoke test from the project folder:

```sh
godot --headless --path . --script tests/smoke_test.gd
```

This checks chapter progression, item collection, minigame behavior, and camera/companion wiring. It does not validate rendered appearance.

### Offscreen screenshots (Linux virtual display)

`tests/screenshot_autoload.gd` saves the real Forward+ frame to
`/tmp/godot_screenshot.png`. Register it temporarily as an autoload in
`project.godot`:

```
[autoload]

ScreenshotHelper="*res://tests/screenshot_autoload.gd"
```

then run under a virtual display (`xvfb-run -a -s "-screen 0 1280x720x24" godot
--path . scenes/main.tscn`; software Vulkan via `mesa-vulkan-drivers` is
enough). `HIDE_NODE`, `CAM_POS`, `CAM_LOOK` and `SHOT_FRAME` steer the capture
— `HIDE_NODE` in particular is how you find out what is actually drawing at a
pixel. Remove the autoload again before committing.

## Alive stream pack

`assets/bethlehem_stream_fish_alive_v7.glb` is instanced as `StreamFishAlive/Art` on the west stream bank. The `StreamFishAlive` parent is positioned at `(-6.2, 0.28, -3.8)` with uniform scale `1.1`. Runtime scripts fit the waterfall, hide static valley water/fish meshes, and animate procedural fish along the stream. Water meshes skip collision via `mesh_collision_baker.gd`. The pack's own rocks are tan 20-sided lumps, so `stream_rocks.gd` replaces them with the valley's stone meshes at start-up, and `stream_placement.gd` puts any tree it nudges out of the water back on the ground.

**Import gotcha (fixed):** `bethlehem_stream_fish_alive_v6.glb.import` (archived) and
`_v7.glb.import` were missing the closing quote on their `uid=` line. A
malformed `.import` file like this sends Godot's editor filesystem scan
into a reimport-retry loop that never finishes on project open — it looks
like a hang, not an error. If a future asset's `.import` file gets
hand-edited or generated by a script that isn't careful about quoting,
this is the first thing to check.

## Historical art notes: Wonder-Walker v8

The v8 iteration used `art/archive/models/wonder_walker_v8.glb` (solid hair crown for top-down read), with `WW_Walk` at 12fps STEP and `remove_immutable_tracks=false`. It has since been superseded by v13 in the main scene.

## Wonder-Walker v13: connected body and natural proportions

The main scene uses `assets/wonder_walker_v13.glb`, generated by
`art/blender/scripts/characters/generate_wonder_walker_v5.py`. The Walker has
continuous arm/wrist/palm surfaces, integrated thumbs, a tunic with sloped
shoulders, tapered trouser legs, smaller shoes, and a shaped jaw/cheek/nose
surface. The scalp cap and facial features follow the same head bone.
Outline thickness is reduced from 10 mm to 2.8 mm.

Explicit skin weights blend elbows and knees and keep the body and outline
moving together. The existing 14-bone layout and `WW_Walk` name are preserved;
the walk holds 12 poses per second, closes on a duplicate endpoint, and adjusts
pelvis height to keep the lowest shoe near the floor. Walker v12 remains
available for comparison. See the [Blender README](art/blender/README.md#latest-character)
for regeneration and review commands.

![Walker v12 and v13 compared in Godot Forward+](art/previews/wonder_walker_v13_comparison.png)

## Historical character generation: Wonder-Walker v12 + David mentor v9

The earlier v4 Walker and v3 props generators output `wonder_walker_v12.glb`,
`david_mentor_v9.glb`, and `wonder_items_v7.glb`. The main scene now uses Walker v13, David v12, and items v7 (`wonder_walker_v12.glb` and `david_mentor_v9.glb` are archived in `art/archive/models/`). Use the newer character generators for the active Walker and David assets. These earlier generated versions replaced `wonder_walker_v10/v11.glb`
and `david_mentor_v7/v8.glb` (PR #23's original bot-generated swap, which
had no committed generator script and regressed badly — see below).

Both characters' torsos are now a tapered, beveled cylinder instead of a
beveled cube, so the body reads as a soft rounded human shape ("DOGWALK
style") rather than "blocks stacked together"; both also got a low front
hair fringe + side hair so the face reads as framed instead of a bald
dome, and a short, visibly-narrower **neck** instead of the head sitting
flush on (and slightly sunk into) the torso top. The lamb (David's
companion sheep and the collectible `WonderItem_Lamb`) was rebuilt with
an elongated body, properly-splayed legs, smoother overlapping wool, and
a tail. Generators:
`art/blender/scripts/characters/generate_wonder_walker_v4.py` and
`art/blender/scripts/props/generate_david_and_items_v3.py` — see that
folder's README for the technical gotchas found while building this
(hair detaching during animation, eyebrow/crown clearance margins, the
"Roblox rigid" elbow fix).

**Wonder-Walker's arm/leg joints now actually bend.** The elbow was
rigged (`UpperArm` + `LowerArm` bones) since v3 but the walk cycle never
animated `LowerArm`, so the whole arm swung as one rigid rod pivoting only
at the shoulder — the single biggest thing that made the character read
as stiff/"Roblox" instead of DOGWALK-smooth. `walk()` now animates the
elbow every keyframe (a resting bend that's never fully straight, plus a
fraction of the shoulder swing), and both the elbow and knee got small
volume bulges centered on the joint so they read as actual hinges. Legs
already had two animated bones (hip+knee) since v3 and just needed the
same volume treatment.

**David and the Wonder-Walker turn to face each other.** David's
orientation used to be static (whatever `main.tscn` happened to bake in),
so the close-up camera composed around whatever direction he was
originally facing rather than toward you. `chapter_director.gd`'s
`_face_player()` now smoothly turns him to face the player when
`Beat.MEET_DAVID_A` begins, **awaited before** the camera cuts to the
close-up — `CameraDirector._place_closeup()` reads the target's *current*
facing to compose the shot, so cutting mid-turn (or before it starts)
frames the wrong spot. The turn plays out on the wide tabletop shot
first, then the close-up cuts in already correctly framed. `_face_david()`
turns the Wonder-Walker toward David at the same time (fired without
awaiting it — nothing downstream reads *his* facing, unlike David's), so
it's genuinely face to face on both sides, not just David turning.

**Neck geometry fixed again — the first pass still looked stacked.** A
visibly-narrower neck cylinder wasn't enough on its own: the base radius
was only ~35-40% of the torso-top width, so there was a sharp step from a
wide flat torso top straight down to a narrow post, which reads as a
separate part stacked on top regardless of how smooth the neck's own
surface is. Now tapers from ~60% of the shoulder width instead. Both
characters also got a gentle default smile (small raised mouth corners)
instead of a flat oval that read as a blank stare — see
`art/blender/README.md` for both, including why the smile is a static
default and not a per-context expression system yet.

## David mentor v13: young shepherd

David uses `assets/david_mentor_v13.glb`, generated by
`art/blender/scripts/characters/generate_david_mentor_v4.py`. It shares Walker
v13's continuous body/limb construction, with a golden tunic, green sash,
leather sling pouch, sandals, a soft hair cap, and a closed smile. David's own
body is static; the chapter director still turns him toward the player, and
the charm ceremony supplies his nod. The companion lamb is rebuilt in the same
style, and as of v13 is no longer joined into David's own body mesh at export:
it is kept as its own pair of objects (`David_CompanionLamb` /
`David_CompanionLamb_Outline`), so it is a separate node in the exported scene
that `scripts/companion_sheep_life.gd` can move on its own — a gentle
breathing sway and a glance toward the Wonder-Walker, without ever leaving
David's side (see backlog 3.3).

V11's dark overlapping shell and boxed mouth are replaced at the asset level.
The main scene no longer attaches `FixDavidMentorVisuals`; its old node-hiding
workaround is unnecessary. Thin, single-sided outline hulls are included in
the new GLB, with no mouth-interior, teeth, or tongue surfaces. The close-up
camera has slightly more headroom for the taller model.

The smoke test (`tests/smoke_test.gd`) checks that meeting David cuts to his close-up camera. How David
looks is not tested automatically: use the screenshot helper (`tests/screenshot_autoload.gd`, described
under **Verification helpers**) for renders. (Earlier notes mentioned a `tests/david_visual_review.gd`;
it was never committed.)

![David v11 and v12 compared in Godot Forward+](art/previews/david_mentor_v12_comparison.png)

## Courage charm award

After the child has heard Joshua 1:9, breathed it with David, and watched him walk, beat `CHARM_AWARD` plays a placeholder bracelet+charm float-snap ceremony (`scripts/charm_award.gd`). Swap meshes later with authored art.

## Historical art notes: stream fish alive v2

The v2 iteration used `art/archive/models/bethlehem_stream_fish_alive_v2.glb` with a taller cascade and stronger hop/splash/fish wiggle at 12fps STEP. Its parent transform was `(-6.5, 0.05, -4.0)` with scale `1.15`. The current v7 asset and placement are documented under **Alive stream pack** above.
