# Little Light — promotional asset production checklist

This is the game-side checklist for producing trailers, Reels, Shorts, store previews and still
posts. The first target is one honest 15-second video made mainly from real Chapters 1–2 gameplay.
The same source files can then be cut into other formats.

## What is ready now

| Asset | Current source | Use |
|---|---|---|
| Chapter 1 story frames | `.godot/chapter-visual-review/*.png` | Storyboard, posts and trailer shot selection |
| Chapter 2 character/activity frames | `.godot/camp-jonathan.png`, `camp-jonathan-arc.png`, `camp-checklist.png`, `camp-cord.png` | Jonathan, night camp, checklist and friendship activity |
| Character models | `assets/david_mentor_v13.glb`, `assets/jonathan_v1.glb` and the player model used by `scenes/main.tscn` | Clean character reference renders |
| Environment references | `art/previews/valley_preview_v6.png`, `valley_preview_v6_river.png` | Valley mood and wide establishing views |
| Current map | `assets/ui/faith_journey_map.jpg` | Progress/five-journey promise, after confirming its text is current |
| Concept references | `docs/jonathan-look.jpg`, `docs/faith-journey-sketch.jpg` and `.mp4` | Internal storyboard reference; use publicly only when it matches the game |
| Voice, music and sound effects | `assets/audio/vo`, `assets/audio/music`, `assets/audio/ambience`, `assets/audio/sfx` | Trailer dialogue and natural game sound |
| App icon | `icon.svg` | App/store identity; it is not yet a complete promotional wordmark |

Chapters 3–5 currently have concepts rather than playable footage. Promotion may name the stories
and show their map stops. Do not show generated scenes as gameplay. A generated teaser must say
**Story concept** or **Coming in the five-journey volume**.

## Minimum campaign package

Produce these from one approved master:

1. **15-second vertical preview, 1080 × 1920** — Reels, Shorts and paid-social test.
2. **30-second landscape trailer, 1920 × 1080** — website, YouTube and family presentations.
3. **Three 6–10 second vertical cutdowns** — calm exploration, read-aloud story and friendship
   activity.
4. **Six clean stills** — store/social carousel: valley, Wonder Item, David, Jonathan, activity and
   Faith Journey.
5. **One silent-friendly version** — burned-in captions and no information communicated only by
   speech.

## Game footage required

Record each shot for 6–10 seconds even when the edit will use only 1–3 seconds. This leaves room for
transitions and different crops.

| ID | Chapter | Required shot | UI | Audio | Status |
|---|---:|---|---|---|---|
| G01 | 1 | Slow valley establishing view with stream, trees and player entering | clean plate and normal UI | ambience | capture needed |
| G02 | 1 | Player walks toward a Wonder Item and collects it | checklist visible | ambience + footsteps + chime | capture needed |
| G03 | 1 | David close-up while a short recorded line plays | dialogue visible | David voice | capture needed |
| G04 | 1 | Steady Hands ring moving through one inhale/release | activity UI | breath + ambience | capture needed |
| G05 | 1 | Courage charm ceremony | normal UI | charm sound | capture needed |
| G06 | 1 | Faith Journal showing the earned verse/charm | normal UI | one short read-aloud line | capture needed |
| G07 | 2 | Wide camp at blue hour with fire, banners and moving characters | clean plate | breeze + fire + owl | capture needed |
| G08 | 2 | Jonathan and David face each other, blink, nod and gesture | dialogue visible | Dylan line | capture needed |
| G09 | 2 | Find and collect one gift; checklist row checks off | checklist visible | footsteps + chime | capture needed |
| G10 | 2 | Draw and release one friendship-cord loop | activity UI | activity sound | capture needed |
| G11 | 2 | Friendship charm/verse completion | normal UI | voice + charm sound | capture needed |
| G12 | shared | Five-stop Faith Journey map | normal UI | soft music | capture needed after map text review |

For every important shot, capture two versions where practical:

- **proof version:** real player controls, prompts and dialogue, proving this is gameplay;
- **clean version:** menus and dialogue hidden, useful behind a title or for a Higgsfield transition.

The clean version must come from the same game scene. It is not a replacement cinematic.

## Character reference pack

Higgsfield works more consistently when the same locked reference images are attached to every shot.
Prepare one sheet per recurring character:

| Character | Required views | Expression/action |
|---|---|---|
| Wonder-Walker | front, three-quarter, side, full body | neutral, walking, small smile |
| Wonder Light | front/three-quarter and in-world scale reference | neutral glow and speaking state |
| David | front, three-quarter, side, full body | neutral, speaking, listening/nod |
| Jonathan | front, three-quarter, side, full body | neutral, friendly smile, speaking gesture, blink |

Use a flat light and the same plain warm background for all four sheets. Keep costume, proportions,
paper outline, hair and skin colors identical to the shipping models. Include one in-game screenshot
beside the clean views so the reference cannot drift away from the actual game.

The existing Chapter 2 comparison capture is a useful identity check:
`.godot/camp-character-comparison.png`.

## Environment reference pack

Capture these without dialogue panels:

- valley wide view in daylight;
- path and waterfall;
- David's meeting place;
- King's Camp wide view at blue hour;
- king's tent and campfire;
- lookout toward the valley;
- Faith Journey book/map background;
- a neutral paper-texture background for title cards.

For an AI-assisted transition, use these real locations as the first and last reference frames. Do
not ask the model to redesign the world.

## Brand and text assets still needed

The project has an app icon but no complete trailer identity pack. Create:

- a transparent **Little Light** wordmark at least 2400 px wide;
- light and dark versions;
- a 9:16 end card, a 16:9 end card and a square end card;
- an approved one-line promise: **A gentle, ad-free Bible adventure for children**;
- beta CTA: **Play the free family preview**;
- launch CTA: **Five Bible journeys. One gentle, ad-free game.**;
- a small trust strip: **No ads · Read aloud · Progress stays on this device**;
- store/web URL or QR code once the destination exists.

Do not put a QR code or external link inside a child-facing game screen. It belongs on the
parent-facing page, video end card or grown-ups area.

## Audio package

Export or record four clean groups:

1. music;
2. ambience such as stream, breeze, fire, birds, owl and crickets;
3. effects such as footsteps, pickup chime and activity/charm sounds;
4. voice lines.

The game already separates these into Music, Ambience, Effects and Voice buses. Record several
passes with the other pause-menu volume sliders muted if separate stems are needed. Keep one
untouched full-mix gameplay recording as evidence of how the game actually sounds.

Select short lines that finish comfortably inside the edit. Recommended first choices:

- one Wonder Light invitation from Chapter 1;
- one short David line;
- Jonathan's Dylan line: “I am Jonathan. David was brave today, because God was with him.”;
- the trust statement as new parent-facing narration, recorded separately from character dialogue.

Before public use, confirm every included recording and generated asset has commercial promotional
rights. Preserve `assets/audio/CREDITS.md` attribution where required.

## How to capture the existing screenshots

Chapter 1 already has a repeatable visual-review capture:

```powershell
godot --path . --script tests/chapter_visual_review.gd --resolution 1280x720
```

It writes the major beats to `.godot/chapter-visual-review/` without changing the real player
profiles.

Chapter 2 already has a repeatable visual capture:

```powershell
godot --path . --script tests/camp_review.gd --resolution 1280x720 -- --visual
```

It writes `.godot/camp-*.png`. For final promotional stills, add a 1920 × 1080 capture option after
checking that the UI and camera compose correctly at that resolution. Keep the 1280 × 720 review
captures for regression comparison.

## How to record moving gameplay

1. Create a scratch promotional profile with read-aloud on and all volumes at their intended mix.
2. Run the game at 1920 × 1080 in a borderless or clean window.
3. Record at 30 or 60 fps with the mouse pointer hidden. Capture the game audio directly rather
   than through a room microphone.
4. Perform each G01–G12 shot separately and leave two seconds of stillness before and after the
   action.
5. Repeat G01, G07 and character dialogue as clean plates with promotional overlays disabled.
6. Name files by shot ID, for example `G08_jonathan_dylan_take01.mp4`.
7. Review every take for stutter, clipped speech, accidental debug text, cursor, notification sounds
   and UI cropping before sending it to editing or Higgsfield.

An automated promotional capture script would make these takes repeatable. It should create a
scratch profile, jump to the correct beat, hold a stable camera, trigger one action, and exit. Build
that only after the shot list is approved so it does not encode discarded shots.

## Higgsfield production steps

1. **Lock the brief:** classic warm storybook motion, gentle pacing, parent audience, 15 seconds,
   9:16 master.
2. **Build one storyboard sheet:** use the real G01/G02/G04/G08/G10/G12 frames plus the end card.
3. **Review the storyboard before spending credits:** confirm character identity, Scripture wording,
   claims, UI readability and what is real gameplay.
4. **Prepare clean inputs:** individual full-resolution frames, never the storyboard grid itself.
5. **Generate only the support shots:** book opening, logo motion, gentle page transition or a small
   camera continuation from a real frame.
6. **Edit in real gameplay:** generated motion should connect gameplay shots, not replace them.
7. **Add captions and final game audio:** keep dialogue understandable on a phone speaker.
8. **Export the vertical master:** then create 16:9 and 1:1 versions with manual crop review.
9. **Make variants from the approved master:** change only the opening hook and CTA first.

## Rough generation budget

Pricing checked on 24 September 2026. Higgsfield changes plans, model prices and unlimited-model
coverage, so confirm the amount displayed on the Generate button before every paid run.

| Production approach | Likely generation spend | What it covers |
|---|---:|---|
| Lean hybrid test | **US$15–30** | Mostly real gameplay, a few still/reference iterations, and roughly two attempts at a short generated opening or Marketing Studio master |
| Recommended first campaign | **US$30–50** | Storyboard references, 2–3 attempts for the 15-second master/support motion, plus a few hook/end-card variants |
| Polished 15 s + 30 s package | **US$60–100** | Several master attempts, support transitions for both formats and selected variants |
| Mostly AI-generated trailer | **US$100–200+** | Multiple character/location shots with retries; not recommended because it costs more and proves less about the actual game |

Useful current reference points from Higgsfield's own published examples:

- Starter is listed at **US$15/month with 200 credits**.
- A 15-second Marketing Studio video is listed at **89.2 credits, about US$4.50 per attempt**;
  three attempts are about **US$13.40**.
- A 15-second 1080p Seedance 2.5 video generated through a connected agent is listed at **270
  credits**; at the stated standard conversion that example is about **US$13.50 per attempt**.
- A 30-second connected-agent cinematic take is listed at **540 credits, about US$27 per attempt**.
- API pricing is separate and can be cheaper for small support shots; Higgsfield currently lists
  Seedance 2.5 from **US$0.0738 per generated second**, with price varying by configuration.

For Little Light, do not generate a full 30 seconds three times. Record the real 30-second gameplay
edit locally, then generate only the 2–5 second book opening, logo motion or transition that the edit
actually needs. Set a **US$50 first-video ceiling**, require the displayed credit cost before each
run, and stop after three unsuccessful versions to revise the storyboard instead of spending through
prompt changes.

These figures exclude paid advertising, app-store fees and outside editing labor. Editing from the
game captures and repository assets does not itself consume Higgsfield credits.

Pricing references:

- [Higgsfield credits and plan examples](https://higgsfield.ai/blog/credits-vs-unlimited-ai-video-generation)
- [Higgsfield Marketing Studio production example](https://higgsfield.ai/blog/how-studios-scale-ai-video-production)
- [Higgsfield connected-agent generation examples](https://higgsfield.ai/blog/generate-ai-videos-from-chatgpt)
- [Higgsfield API rates](https://higgsfield.ai/blog/higgsfield-api)

## First 15-second edit

| Time | Source | Concrete action |
|---|---|---|
| 0.0–2.0 | G01 + optional Higgsfield page opening | Reveal the real valley; title: “A Bible story you can explore” |
| 2.0–4.5 | G02 | Show walking and one satisfying item pickup |
| 4.5–7.0 | G04 | Show the breathing interaction; text: “Calm, fail-free activities” |
| 7.0–10.0 | G08 | Let Jonathan's friendly motion and one short voice phrase play |
| 10.0–12.5 | G10 or G11 | Show the friendship activity/reward |
| 12.5–15.0 | G12 + end card | “No ads · Read aloud” and “Play the free family preview” |

## Definition of ready

The first video can be produced when all of these are true:

- [ ] G01, G02, G04, G08, G10/G11 and G12 have approved moving takes.
- [ ] Six matching full-resolution still frames exist for the storyboard.
- [ ] The four character identity sheets are approved.
- [ ] The wordmark, end card and CTA are approved.
- [ ] One parent-facing destination URL exists.
- [ ] Dialogue and music choices are final and rights are documented.
- [ ] The video does not imply Chapters 3–5 are already playable.
- [ ] The storyboard is approved before Higgsfield generation.
- [ ] The final export is watched once with sound and once muted on a phone-sized screen.

## Responsibility split

Work that can be completed from this repository:

- regenerate and review the Chapter 1 and Chapter 2 screenshots;
- add the repeatable promotional capture script after the shot list is approved;
- prepare character/environment reference sheets from the shipping models;
- write the storyboard, voiceover, captions, Higgsfield prompts and edit decisions;
- assemble and review the master video and its aspect-ratio variants once moving footage exists;
- verify that every visual claim matches the playable build.

Inputs that require the product owner's decision or account:

- approve the wordmark, final promise, CTA and destination URL;
- provide or connect the Higgsfield account and generation credits when the approved storyboard is
  ready;
- approve any marketing spend and publishing account;
- provide written parent/guardian permission before using a child's face, voice, name, testimonial
  or filmed play session. Screen-only game capture does not need a child to appear.
