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

## 3. Game feel (open)

| # | Idea | Status | Why |
|---|------|--------|-----|
| 3.1 | Make Steady Hands a real (still fail-free) activity | Open | It is one Space press. A hold-to-breathe with a growing ring that Wonder Light and David breathe along with would be more engaging. Band B could raise `taps_required`. |
| 3.2 | Sound design | Open | Only synthesized beeps today. Add gentle background music, stream and bird ambience, footsteps, item and sheep sounds. |
| 3.3 | A world that reacts | Open | The sheep and fish ignore the player. Let the lamb follow or bleat, fish scatter near the player, grass sway. |
| 3.4 | Keep the player in the play area | Open | Nothing stops walking up the ridge or wandering far from the diorama. Add a soft boundary (invisible wall, or the Wonder Light gently turning the player back). |
| 3.5 | Restart hygiene | Partly done | "Play again" reloads the scene. A persistent Faith Journal / progress save is still not implemented. |

## 4. Visual polish (open)

| # | Idea | Why |
|---|------|-----|
| 4.1 | Sky and horizon | The far edge of the terrain shows a flat beige void. Add a sky gradient, distant hills and clouds. |
| 4.2 | Ground edges | Boundaries between grass, path and cliff have sawtooth steps, and the path is a hard zigzag. Blend ground materials smoothly (vertex colours) instead of assigning one per face. |
| 4.3 | Trees on the cliff wall | Several cypresses and olives stand on the bare grey cliff at the back. Move them onto grass or add vegetation to the wall. |
| 4.4 | Cliffs | The walls are one flat beige-grey. Add rock texture, ledges and a few bushes. |
| 4.5 | Water | The stream and waterfall are flat cyan. Add shimmer, foam at the banks and a visible falling-water effect. |
| 4.6 | Meadow | Empty pale green. Add grass tufts, small flowers and pebbles. |
| 4.7 | Dialogue box | A big dark box covers the bottom of the screen and hides what is behind it. A lighter paper-style panel, with speaker names in colour, would suit the storybook look. |
| 4.8 | Stone by the stream | The flat tan rocks by the water come from the separate stream pack and were not retextured with the v7 stone. |

## 5. Technical and repository health (open)

| # | Item | Details |
|---|------|---------|
| 5.1 | Performance | About **375k triangles and 254 draw calls per frame** in the game view on the v7 valley. The v6 valley measured 316k / 172, so the leafy trees, bushes and rocks added roughly 60k triangles (+19%). The baseline was already heavy for tablets: profile what dominates (terrain, shadows, stream pack, characters) and add LODs / fewer leaves before a mobile release. |
| 5.2 | `.import` churn | Godot keeps rewriting every tracked `.import` file, so the working tree is always dirty. The committed files use placeholder cache hashes that differ from what the editor generates. Regenerate and commit them once, or stop tracking them. |
| 5.3 | Line endings | No `.gitattributes`, so every edit produces CRLF/LF warnings. Add one (`* text=auto eol=lf`, keeping binaries as binary). |
| 5.4 | Repository size | `assets/` is about 73 MB, mostly old model versions (Wonder-Walker v2-v13, valley v2-v7, David v2-v12, items v2-v7). Keep the current ones, archive the rest. The v7 valley alone is about 11.7 MB because leaves are real geometry. |
| 5.5 | Stale docs | Keep the README asset table in step with `main.tscn` (it listed valley v6 after v7 landed). |
| 5.6 | Tests | One headless smoke test (now also covering input devices, touch controls, pause and the end panel) and no CI. Run it on every pull request. Nothing verifies appearance, so keep the screenshot helper in mind for visual checks. |

## Suggested order

1. Try touch and gamepad on real hardware, and get recorded voiceover for the Band A lines (2.1, 2.2).
2. Sky/horizon, ground blending and water (4.1, 4.2, 4.5): the biggest visual gains for the least work.
3. Steady Hands depth and sound (3.1, 3.2).
4. Performance profile before any tablet build (5.1), and the repo housekeeping in 5.2 to 5.4.
