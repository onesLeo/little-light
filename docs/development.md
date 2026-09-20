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
area, the living world, the voice-over, the soundscape and Steady Hands. It prints `SMOKE TEST PASSED`
when every check is OK and exits with code 1 otherwise. It takes about a minute.

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
| `tools/` | `make_sounds.py` and `source/` (the CC0 recordings it starts from) |
| `tests/` | the smoke test and review helpers |
| `docs/` | design notes: `improvement-backlog.md`, `voice-over.md`, `sound-design.md`, `steady-hands.md` |

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
