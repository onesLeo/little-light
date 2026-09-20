# Improvement backlog

A review of the David & Goliath slice (2026-09-20): what to fix, what is done, and what to do next.
It came from playing the whole story in a window, reading the code, and measuring performance.
Status is one of **Done**, **Partly done** or **Open**.

Screenshots and measurements were taken at 1152x648 / 1280x720 on Windows with Godot 4.7.2 (Forward+).

## 1. Bugs and leftover developer text

| # | Problem | Status | Notes |
|---|---------|--------|-------|
| 1.1 | The breath circle in Steady Hands sat on David's face, hiding the thing to watch | **Done** | Moved to the right side of the screen (`BreathIndicator` anchors in `main.tscn`). It now says **In... / Out...** so a child who cannot read still knows what to do (`steady_hands_minigame.gd`). |
| 1.2 | Developer text shown to players | **Done** | Removed "Steady Hands - always succeeds", the "giant stays a distant silhouette" note (there is no giant in the scene), and "Thanks for playing this P0.2 slice" / "David remains David" (`chapter_director.gd`). The end prompt now reads "Well done, Wonder-Walker!". |
| 1.3 | Wonder Light turned into a big flat orange disc when celebrating | **Done** | Cause: a 2.4x emission boost fed the scene's bloom. Now a small core with a soft additive halo that flickers like a firefly, a modest 1.5x pulse, and a burst of sparkles (`wonder_light.gd`). |
| 1.4 | Charm-ceremony confetti looked like large paper rectangles in the close-up camera | **Done** | Smaller pieces for that camera (`charm_award.gd`). |

## 2. Gaps for the target audience (6-12 year olds)

| # | Problem | Status | Notes |
|---|---------|--------|-------|
| 2.1 | Keyboard only: tablets and gamepads could not play | **Done** | Gamepad: left stick / D-pad, A to continue and collect, X also collects, Start to pause (`input_setup.gd`). Touch: floating thumb stick on the left half plus one big gold button whose label follows the story (**NEXT / GRAB / BREATHE**) and which sends both "continue" and "interact" (`touch_controls.gd`). Prompts reword themselves per device. Verified with injected touch events and the smoke test; **still needs a check on a real tablet**. |
| 2.2 | "No-reading mode" for ages 6-8 was promised, but everything was read text | **Partly done** | All dialogue, the Joshua verse and item descriptions are now read aloud with the system's text-to-speech; Wonder Light and David use different voices/pitch when two English voices exist (`audio_director.gd`). Dialogue text is larger (18 to 22 pt). **Open:** recorded voiceover (drop clips into `AudioDirector.vo_clips`, keyed by beat name; they take priority over TTS), and shorter, simpler wording for Band A. System voices vary by OS and may be absent (the speaker button is then hidden). |
| 2.3 | Dead-end ending: no replay, menu, pause or volume | **Done** | After the confetti a **Play again / Keep exploring** panel appears. Pause menu (Esc / P / Start / round button): Resume, read-aloud on/off, volume, Play again from the start. Settings persist (`game_menu.gd`, `game_settings.gd`). |

## 3. Game feel

| # | Idea | Status | Why |
|---|------|--------|-----|
| 3.1 | Make Steady Hands a real (still fail-free) activity | Open | It is one Space press. A hold-to-breathe with a growing ring that Wonder Light and David breathe along with would be more engaging. Band B could raise `taps_required`. |
| 3.2 | Sound design | Open | Only synthesized beeps today. Add gentle background music, stream and bird ambience, footsteps, item and sheep sounds. |
| 3.3 | A world that reacts | **Mostly done** | Grass and flowers lean away from the Wonder-Walker as they walk through (`meadow_sway.gdshader`, driven by `meadow_dressing.gd`). Fish get shy: within ~2.3 m they speed up, dive slightly and turn away (`stream_fish_swim.gd`). The collectible lamb breathes, then turns to face the player and hops when they come near, never leaving its spot (`lamb_life.gd`). Eight paper butterflies drift over the meadow and flutter off when approached (`butterflies.gd`). **Open:** a bleat sound for the lamb (audio not tested yet), and David's companion sheep, which is baked into David's model and cannot move on its own. |
| 3.4 | Keep the player in the play area | **Done** | A soft boundary (`play_bounds.gd`): near the edge of a rounded-rectangle play area the walker meets a gentle push back that grows toward the edge, and cannot go past it; the first time it is felt, Wonder Light says a friendly line ("That's the edge of our little valley. Let's stay close!"). Also recovers a player who is placed far outside. Fixed a related bug: the stream pack's hidden `Bank_*` meshes still had collision, which made an invisible wall near x = -4 (`mesh_collision_baker.gd`). |
| 3.5 | Restart hygiene | Partly done | "Play again" reloads the scene. A persistent Faith Journal / progress save is still not implemented. |

## 4. Visual polish

| # | Idea | Status | Notes |
|---|------|--------|-------|
| 4.1 | Sky and horizon | **Done** | Gradient sky, soft distance fog, four layers of paper-cut hills fading into haze, and slow-drifting paper clouds (`horizon_backdrop.gd`, `Environment` in `main.tscn`). The beige void is gone. |
| 4.2 | Ground edges | **Done** | The ground is now one painted 1024 px map (`paint_ground()` in `polish_valley_v7.py`) instead of one material per triangle, so the path, riverbank and cliff foot have smooth, wavy borders instead of sawtooth steps. |
| 4.3 | Trees on the cliff wall | Open | Several cypresses and olives still stand on the bare cliff at the back. Move them onto grass in the Blender scatter lists, or add vegetation to the wall. |
| 4.4 | Cliffs | **Partly done** | The painted map gives the walls subtle strata, hairline cracks and a grassy rim. Still no real ledges or geometry detail. |
| 4.5 | Water | **Done** | New water shader (`stream_water.gdshader`, applied by `stream_water_fx.gd`): depth tint, ripples that flow downstream, a foam rim where water meets the bank, streaks pouring down the waterfall, and sparkle. |
| 4.6 | Meadow | **Done** | About 700 swaying grass tufts, 120 tiny flowers and 60 pebbles on open ground only (`meadow_dressing.gd`), as three MultiMeshes, so three draw calls. Different every run. |
| 4.7 | Dialogue box | **Done** | Paper-style panel (cream, ink border, rounded) with dark text, matching the pause menu. |
| 4.8 | Stone by the stream | Open | The flat tan rocks by the water come from the separate stream pack and were not retextured with the v7 stone. |

## 5. Technical and repository health (open)

| # | Item | Details |
|---|------|---------|
| 5.1 | Performance | About **375k triangles and 254 draw calls per frame** in the game view on the v7 valley. The v6 valley measured 316k / 172, so the leafy trees, bushes and rocks added roughly 60k triangles (+19%). The visual-polish pass (sky, water, meadow) added about 10k triangles and 5 draw calls on top (386k / 259). The baseline was already heavy for tablets: profile what dominates (terrain, shadows, stream pack, characters) and add LODs / fewer leaves before a mobile release. |
| 5.2 | `.import` churn | Godot keeps rewriting every tracked `.import` file, so the working tree is always dirty. The committed files use placeholder cache hashes that differ from what the editor generates. Regenerate and commit them once, or stop tracking them. |
| 5.3 | Line endings | No `.gitattributes`, so every edit produces CRLF/LF warnings. Add one (`* text=auto eol=lf`, keeping binaries as binary). |
| 5.4 | Repository size | `assets/` is about 73 MB, mostly old model versions (Wonder-Walker v2-v13, valley v2-v7, David v2-v12, items v2-v7). Keep the current ones, archive the rest. The v7 valley alone is about 11.7 MB because leaves are real geometry. |
| 5.5 | Stale docs | Keep the README asset table in step with `main.tscn` (it listed valley v6 after v7 landed). |
| 5.6 | Tests | One headless smoke test (now also covering input devices, touch controls, pause, the end panel, the play-area boundary, the lamb, fish, butterflies and the invisible-wall fix) and no CI. Run it on every pull request. Nothing verifies appearance, so keep the screenshot helper in mind for visual checks. |

## Suggested order

1. Try touch and gamepad on real hardware, and get recorded voiceover for the Band A lines (2.1, 2.2).
2. Move the trees off the cliff wall and retexture the stream-pack rocks (4.3, 4.8); add cliff ledges (4.4).
3. Steady Hands depth and sound (3.1, 3.2).
4. Performance profile before any tablet build (5.1), and the repo housekeeping in 5.2 to 5.4.
