# Release plan — public demo, not yet done

A plan, not a done thing: nothing here is built. The goal, as decided, is a **free demo / portfolio
piece** — enough to show people the idea and Chapter 1, with a note that more is coming. It is not
a paid app-store release, so it doesn't need several chapters first (see
[docs/improvement-backlog.md](improvement-backlog.md) section 6 for the two real gates: a real
tablet test and a real child playing it).

## The goal: no download, just a link

The plan is to publish it as a **browser build (Web export)**, so playing it is "open a link," not
"download and install a file." This is the best fit for "I hope they don't have to download big
files":

- Nothing to install, no app-store account, no APK a phone will warn about ("unknown source").
- The browser downloads the game's assets once in the background (a normal web page load, cached
  after that), rather than the child/parent choosing to "download a game."
- It works on a laptop, a tablet or a phone with the same link — useful for a demo you're sharing
  around, since you don't know what device the other person has.

An installable **Android APK is kept as a secondary option**, not the main path — for anyone who'd
rather have it as a real app. A preset for it already exists (`export_presets.cfg`,
"Android tablet (debug)"), unrelated to this plan.

## What has to change first — the renderer

This is the one real technical catch, worth knowing before starting: the project currently uses
Godot's default **Forward+** renderer (see `docs/improvement-backlog.md` 5.1, which measures both
Forward+ and Mobile renderer draw calls). Godot's Web export does not support Forward+ in a stable
way yet — it needs the **Compatibility** renderer (GL Compatibility / GLES3-style), which is also
the renderer most likely to run smoothly on an older phone or tablet's browser, keeping in the
spirit of "no big files, runs anywhere."

Switching renderer is a real, visible change, not just a checkbox:

- `scripts/performance_tuning.gd` already turns glow off on handhelds (`glow_on_handhelds`),
  because it barely mattered visually and costs less — the Compatibility renderer is the same
  trade, one step further, and the game's look was designed flat-colour/no-gradient from the start
  (see `docs/chapter-2-concept.md`'s "How it would look" section), which is a forgiving style for a
  simpler renderer.
- Every screenshot in the backlog and docs was taken under Forward+, so the look needs a fresh
  check once switched, the same way glow-off was checked by screenshot before being shipped.

## Steps

1. **Clear the two gates first** (`docs/improvement-backlog.md` section 6): real tablet test, real
   child playtest. No point tuning a web build before the game itself is confirmed to work and feel
   right.
2. **Add a Web export preset** in Godot (Project > Export > Add > Web), set the renderer to
   Compatibility for that preset (this can be a per-preset setting, so the tablet/Android build and
   the editor can stay as they are), and export a first build to a local folder.
3. **Look at the export size before publishing anything.** `assets/` is already trimmed (5.4: 34
   unused model versions moved out to `art/archive/models`, a `.gdignore` keeps them out of every
   export). Godot's export filter (see `export_filter`/`exclude_filter` in `export_presets.cfg` for
   the existing Android preset) should exclude `art/*`, `tools/*`, `tests/*`, `docs/*` the same way,
   so none of that ships. If the build is still large, the next lever is texture compression
   (Web/VRAM compression settings in the export preset) — a step to try if needed, not something to
   pre-guess.
4. **Test the exported build in an actual browser** — not just Godot's "run in browser" preview —
   on at least a phone and a tablet browser if possible (Chrome and Safari behave differently for
   WebGL). This is section 6.3 in the backlog.
5. **Host it somewhere free, as a static file** — no server needed for a Web export:
   - **itch.io** (recommended to start): free, made for exactly this (indie/hobby game demos),
     drag-and-drop the exported `.zip`, mark it "This file will be played in the browser," write a
     short page (screenshots, "Chapter 1 of a growing story," age range, that it's offline/no
     accounts). Itch.io also lets you keep the page unlisted (link-only) instead of publicly
     listed, which fits a portfolio piece you're sharing selectively rather than promoting widely.
   - **GitHub Pages** (alternative): free static hosting straight from this repository, good if you
     want it under your own GitHub account with no third-party site involved at all; a bit more
     manual to set up (a `docs/` or `gh-pages` branch serving the exported files) and has no
     built-in game listing/page the way itch.io does.
6. **Say plainly, on whatever page hosts it, that it's a demo/work in progress** — sets the right
   expectation, and matches how `docs/chapter-2-concept.md` is already framed ("a concept, not yet
   approved").

## Why this is comfortable for a kids' game specifically

The game already collects nothing and calls nowhere (`docs/faith-journal.md`: "Nothing leaves the
tablet: no account, no network"). A browser build keeps that true — no login, no data collection,
no ads, nothing a parent needs to worry about beyond the browser itself. Worth saying so on the
page, since parents specifically look for that.

## Not part of this plan

- A paid app-store listing (Google Play / Apple App Store) — a different, heavier process
  (accounts, review, signing, store assets) that only makes sense once there's more than one
  chapter and a decision to actually sell or list it.
- Chapter 2, or any more story content — per the earlier decision, not required for a demo release.
