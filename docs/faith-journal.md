# Who is playing, and the Faith Journal

Backlog item 3.5. Each child on a tablet has their own name, picture and journal.

## What a child sees

1. **Who is playing?** The first screen on a fresh start, read aloud in Wonder Light's voice for a child who cannot read yet.
   One big button per child (picture and first name)
   and a dashed **New** button. A new child types a name (up to 12 letters), picks one of six paper pictures
   (lamb, star, sun, cloud, heart, olive branch) and taps **Let's go**. Up to **4 children** fit on one tablet.
   A child also says **How old they are**: "8 or younger" turns on Easy words, twelve lines of the story shown
   and read aloud in simpler wording (`scripts/easy_words.gd`); "9 or older" keeps the story exactly as
   written. It can be switched later in the pause menu, and is kept with the child.
2. **The Faith Journey map** comes next, before any story (see below). The child taps where their story
   starts; a bouncing **Start here** tag shows them where. *Play again* keeps the same child and replays
   the chapter just played (chapter 2's Play again goes back to the camp, not to the valley); a different
   chapter is chosen on the map. The pause menu's **Start this chapter again** does the same, and
   **Change player** brings the first screen back.
3. **The Faith Journal** opens from the round book button (top right, next to the speaker and pause), from the
   pause menu, and from the end-of-chapter panel (**My journal**). It shows:
   - **Verses** the child has earned, each with a **Hear it** button that reads it aloud in the recorded voice
     (the same clips as the story). Under Joshua 1:9 a short note tells a parent why that verse lives in
     David's story: the same God who was with Joshua was with David — the Lord who kept him safe from
     the lion and the bear.
   - **Charms** the child has earned. Tapping one reads its line and shows why it was earned. The charms not
     earned yet are dashed circles with a "?" and "Not yet". There are two spare slots for chapters to come.
4. **Colour my charm.** A charm can be coloured: **Colour my charm** in the journal (next to the note under the charms)
   or on the end-of-chapter panel opens a paper page with the charm drawn in ink. The child taps one of eight
   paints, then taps a part of the charm (the two ribbons, the ring, the inner disc, the star, the middle) to fill it.
   **Undo** takes the last colour off and **Start again** clears the page (Undo brings it back). Nothing is lost by a
   wrong tap, and there is no freehand drawing, so a finger on a tablet cannot make a mess. Each colour is saved at
   once. The coloured charm then shows in the journal, and on the face of the 3D charm when the ceremony plays again.
5. **What is earned:** the verse (Joshua 1:9) when the story reaches it, the Courage charm when its ceremony
   starts, and, when the chapter ends, a finished-chapter count and which chapter it was (`finished` in the
   profile; saves from before that count as having finished the valley).

## Faith Journey

The map is the hub of the game. It opens straight after **Who is playing?**, and later from the journal, the pause menu (**Faith Journey map**) and the end-of-chapter card. The journal keeps what she earned. The journey shows where she can go next (`scripts/faith_journey_screen.gd`).

The page is an old paper map, `assets/ui/faith_journey_map.jpg`, not a blank sheet with icons on it. Mountains run across the top, a river comes down into the green valley, and the path climbs to the tents of The King's Camp, then fades toward a paler hill. The sketch with the markers is [faith-journey-sketch.jpg](faith-journey-sketch.jpg), and the moving version is [faith-journey-sketch.mp4](faith-journey-sketch.mp4).

Each story is a numbered paper label under its place on the map, so the tents and trees stay in view:

- **1 The Valley**, on the river and the sheep. Always open.
- **2 The King's Camp**, on the tents and the fire. Opens once the valley is finished.
- **3 The Beginning**, in Bethlehem's warm courtyard. Opens once The King's Camp is finished.
- **4 Noah's Ark**, shown as a locked preview until Chapter 4 is implemented.
- **5 Jonah**, shown as a locked preview until Chapter 5 is implemented.

Markers, so she can see where she is and what comes after:

- The next story she has not finished has a gold **Start here** tag (**Next story** once she has finished one) bobbing over it, with gold rings spreading out from its spot.
- A finished story has a gold seal with a tick.
- A story that is not open yet is a paler label with a small padlock. Tapping it gives the label a little shake and brings up a paper card: **Not yet!** "Finish Chapter 1, The valley, first. Then The King's Camp will open for you." Its gold button goes straight to that story (**Play Chapter 1**, or **Back to my story** when she is already playing it); **OK** closes the card. Wonder Light reads the card aloud. Nothing is marked wrong.

When the map is the first stop, Wonder Light greets the child by name ("Hello, Maya! Your journey starts in the valley.") and there is no **Back**, because no story has started behind it yet; **Change player** sits in the corner instead. Opened later, Wonder Light reads "One story at a time" and **Back** closes it. Each child has their own path, because it follows that child's finished chapters. Emptying the journal folds it back.

## For grown-ups

A small **For grown-ups** button at the bottom of the journal asks for a press and hold of 3 seconds (a
young child tapping around does not get through). Then:

- **Empty the journal**: clears the child's verses, charms and chapter count, and keeps the child.
- **Remove the child from this tablet**: deletes their name, journal and settings and goes back to the first screen.

Both ask *"This cannot be undone"* first, with **Keep it** as the first choice.

## Where it is saved

`user://profiles.cfg` on the tablet (on Windows,
`%APPDATA%\Godot\app_userdata\Little Light — David & Goliath Slice\`). Nothing leaves the tablet: no account,
no network. Each child's charm colours are kept with them, and so are their read-aloud choice and volumes (`settings.cfg` still holds the
tablet's last values and is used until a child is chosen).

## How it is built

| File | What it does |
|---|---|
| `scripts/profiles.gd` | The saved children and what they earned (static functions, like `game_settings.gd`). |
| `scripts/journal_content.gd` | The verses and charms the journal can hold, and their read-aloud text. |
| `scripts/profile_screen.gd` | "Who is playing?" and the name and picture form. Pauses the game while open. |
| `scripts/journal_screen.gd` | The journal and the grown-ups' area. Pauses the game and keeps the audio director running so clips can play. |
| `scripts/avatar_icon.gd` | The little pictures (children, charm, "?", "+"), drawn in code. A charm shows the child's colours when it has them. |
| `scripts/charm_art.gd` | The charm's parts (polygons), the eight paints, drawing, and turning the picture into an image for the 3D charm. |
| `scripts/colour_screen.gd` | The colouring page: paints, tap-to-fill, Undo, Start again. Pauses the game while open. |
| `scripts/paper_ui.gd` | The paper-and-ink look shared with the pause menu. |
| `scripts/chapter_director.gd` | Waits for a child at the start, and awards the verse, charm and finished chapter. |
| `scripts/game_menu.gd` | The book button, the pause menu's Faith Journal and Change player, and My journal on the end panel. |

**Adding a verse or a charm:** add it to `journal_content.gd` (a new charm also needs its own regions in `charm_art.gd`; until then it shows the Courage picture), record its lines (for a verse: the spoken
reference and the verse) and list them in `vo_library.gd`, and unlock it from `chapter_director.gd`. The smoke
test fails if a journal line has no recorded clip.

## Things to know

- **`Profiles.use_file()`, not `Profiles.path = ...`.** Godot re-runs a script's static variable initialisers on
  the first call of any static function, which put the default path back and made an early version of the smoke
  test write into the real profile file. The test now uses `use_file()` and a scratch file.
- The journal works for a child who has earned nothing yet ("Your first verse is waiting in the story.").
- If read-aloud is off, **Hear it** says so instead of staying silent.

## Not done, and not tested

- **More than tap-to-fill.** Four ideas were sketched (colour your charm, colour a lamb, stickers, free drawing);
  only colouring the charm is built. Colouring works with a finger, a mouse, a gamepad or a keyboard (left and right move between the parts of the charm, accept fills the one with the blue ring).
- **On a real tablet.** The touch targets are large (at least 60 px) and there is a visible focus style for a
  gamepad or keyboard, but the on-screen keyboard for typing a name has not been tried. The form lifts itself above the
  keyboard's height (`_fit_to_keyboard` in `profile_screen.gd`) and drops its headings to fit, but that is
  written from the API, not seen on a device.
- **Names are only lightly checked.** A short list of rude words (`Profiles.BLOCKED_INSIDE` and `BLOCKED_EXACT`) is
  turned away with "Please pick a different name"; capitals, spaces and look-alike digits ("sh1t") do not get round
  it. The list is short on purpose, because a long one turns away real names. A grown-up can still remove a child.
