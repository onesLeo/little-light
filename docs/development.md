# Development guide

Everything you need to work on the game, in one place.

## Setup

- **Godot 4.7.2** (Forward+). The project is tested against that exact version, and so is CI.
- **Python 3** for the sound tool (`tools/make_sounds.py`, standard library only). Blender 5.2 is only
  needed to regenerate models (see `art/blender/README.md`).
- Open the project in Godot once, or import from the command line:

```bash
godot --headless --path . --import
```

Run the import again after pulling changes that add or change assets. If the exit is a crash
right after "DONE", run it a second time; Godot sometimes crashes when it quits after an import.

## Running the tests

```bash
godot --headless --path . --script tests/smoke_test.gd
```

It starts the real main scene without a window and checks the story beats, input devices, the play
area, the living world, where trees and rocks stand, a triangle budget, who is playing, the Faith Journal and colouring the charm, the voice-over, the soundscape and Steady Hands. It prints `SMOKE TEST PASSED`
when every check is OK and exits with code 1 otherwise. It takes about a minute.

For a repeatable visual pass with the real Forward+ renderer, run this without `--headless`:

```bash
godot --path . --script tests/chapter_visual_review.gd --resolution 1280x720
```

It captures every major Chapter 1 beat to `.godot/chapter-visual-review/`, including the item
handoff, Steady Hands, the clarified resolution, the verse, and the charm. It uses a scratch child
profile, so it does not change the profiles or journals saved on the device.

**On GitHub** the same test runs on every pull request and on every push to `main`
(`.github/workflows/smoke-test.yml`). It downloads Godot 4.7.2 for Linux, so it also catches
problems that Windows hides, such as a file referenced with the wrong letter case. The log is kept
as a build artifact.

A few things learned the hard way when writing tests:

- `await process_frame` resumes *before* nodes' `_process` runs, so call the update method
  directly (or wait a second frame).
- Input injected with `Input.parse_input_event` is applied at the end of the frame; wait a frame
  before checking `Input.is_action_pressed`.
- Use explicit types in test scripts (`var x: bool = ...`); `:=` fails on values Godot cannot infer.

## Running on an Android tablet

The project is set up for it: landscape orientation, ETC2/ASTC texture compression on, and the Mobile
renderer (Godot's default on Android). The export preset (`export_presets.cfg`) is not committed, because
Godot's `.gitignore` template excludes it. Recreate it in *Project > Export > Add > Android* (arm64 only,
Gradle build off, package `com.oneleo.littlelight`, name it "Android tablet (debug)"), or copy it from
another computer.

### Step 1: install the export templates (once per computer)

1. Open the project in the Godot editor.
2. Choose *Editor > Manage Export Templates* and click *Download and Install*. It is about 1 GB; wait until it
   says it is installed.
3. Check *Editor Settings > Export > Android*: it needs the Android SDK, the JDK (17) and a debug keystore. On
   the main development computer these are already set.

### Step 2: prepare the tablet (once per tablet)

1. Open *Settings > About tablet* and tap *Build number* 7 times. It says "You are now a developer".
2. Open *Settings > System > Developer options* (on some tablets *Additional settings*) and turn on
   *USB debugging*.
3. Connect the tablet to the computer with a USB cable that carries data (some charging-only cables do not
   work).
4. A prompt appears on the tablet: "Allow USB debugging?". Tick "Always allow" and tap *Allow*.

### Step 3: check that the computer sees the tablet

```bash
adb devices
```

(`adb` is in `<Android SDK>\platform-tools`; on the main development computer that is
`C:\Users\onesa\AppData\Local\Android\Sdk\platform-tools\adb.exe`.)

- The tablet is listed as `device`: it is connected.
- It says `unauthorized`: tap *Allow* on the tablet.
- The list is empty: try another cable or USB port, and set the tablet's USB mode to *File transfer* (in the
  notification that appears when it is plugged in).

### Step 4: run the game

In the Godot editor click the small Android icon at the top right, next to the play button. It lists the
tablet; click it. Godot builds the game, installs it and starts it. The first build takes a few minutes.
Or from a terminal:

```bash
godot --headless --path . --export-debug "Android tablet (debug)" build/little-light-debug.apk
adb install -r build/little-light-debug.apk
```

Godot's *Debugger > Monitors* shows FPS and draw calls while it runs. For the same table as on a computer,
see `tools/profile_frame.gd` and `docs/performance.md`. `build/` is ignored by git.

### If something goes wrong

- **"No export template found"**: step 1 was not finished for this Godot version (4.7.2).
- **The tablet is not listed in the editor**: run `adb devices` (step 3) and fix that first.
- **Nine `wonder_walker_v13_Tint_WW_*.png.import` files show up as changed in `git status`**: the editor was
  open before the ETC2/ASTC setting was committed and wrote them without the tablet format. Close and reopen
  the editor, then `git checkout -- assets/wonder_walker_v13_Tint_WW_*.png.import`.

## Files Godot generates

- **`.import` and `.uid` files are committed, exactly as Godot writes them.** A clean checkout should
  produce no changes when you import and run the tests, so `git status` staying clean after that is
  a check in itself. If Godot rewrites a tracked `.import` file, something is wrong with it (before
  this was fixed, 18 files had hand-typed identifiers that Godot replaced on every import).
- The import cache (`.godot/`) is not committed.
- Never hand-edit a `.import` file.

## Line endings

`.gitattributes` stores and checks out all text files with LF on every platform and marks images,
models, audio and fonts as binary. On Windows with `core.autocrlf=true` this means no more
"LF will be replaced by CRLF" warnings. If your editor insists on CRLF, turn it off for this
repository.

## Where things live

| Folder | What is in it |
|--------|---------------|
| `scenes/`, `scripts/` | the game |
| `assets/` | only the models and sounds the game loads (five models, `audio/`, `shaders/`) |
| `art/blender/` | generators for the models and the environment |
| `art/archive/models/` | 34 earlier model versions, ignored by Godot (see its README) |
| `art/previews/` | saved renders |
| `tools/` | `make_sounds.py` and `source/` (the CC0 recordings it starts from), `profile_frame.gd` (frame cost, see `docs/performance.md`) |
| `tests/` | the smoke test and review helpers |
| `docs/` | design notes: `improvement-backlog.md`, `voice-over.md`, `sound-design.md`, `steady-hands.md`, `performance.md`, `faith-journal.md` |

## Making a change

1. Branch from the latest `main` (or from the last feature branch if it is not merged yet).
2. Make the change, import, and run the smoke test.
3. Commit only what the change touches, then open a pull request. CI runs the smoke test on it.
4. Update the docs and `docs/improvement-backlog.md` in the same pull request.

## Adding sound

Synthesized sounds are rendered by `tools/make_sounds.py`; recorded voice clips live in
`assets/audio/vo` and are listed in `scripts/vo_library.gd`. See `docs/sound-design.md`,
`docs/voice-over.md` and `assets/audio/CREDITS.md` (which also records where the CC0 recordings
came from).
