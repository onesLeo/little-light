# Who is playing, and the Faith Journal

Backlog item 3.5. Each child on a tablet has their own name, picture and journal.

## What a child sees

1. **Who is playing?** The first screen on a fresh start. One big button per child (picture and first name)
   and a dashed **New** button. A new child types a name (up to 12 letters), picks one of six paper pictures
   (lamb, star, sun, cloud, heart, olive branch) and taps **Let's go**. Up to **4 children** fit on one tablet.
2. **The story** starts once a child is chosen. *Play again* keeps the same child; the pause menu's
   **Change player** brings the first screen back.
3. **The Faith Journal** opens from the round book button (top right, next to the speaker and pause), from the
   pause menu, and from the end-of-chapter panel (**My journal**). It shows:
   - **Verses** the child has earned, each with a **Hear it** button that reads it aloud in the recorded voice
     (the same clips as the story).
   - **Charms** the child has earned. Tapping one reads its line and shows why it was earned. The charms not
     earned yet are dashed circles with a "?" and "Not yet". There are two spare slots for chapters to come.
4. **What is earned:** the verse (Joshua 1:9) when the story reaches it, the Courage charm when its ceremony
   starts, and a finished-chapter count when the chapter ends.

## For grown-ups

A small **For grown-ups** button at the bottom of the journal asks for a press and hold of 3 seconds (a
young child tapping around does not get through). Then:

- **Empty the journal**: clears the child's verses, charms and chapter count, and keeps the child.
- **Remove the child from this tablet**: deletes their name, journal and settings and goes back to the first screen.

Both ask *"This cannot be undone"* first, with **Keep it** as the first choice.

## Where it is saved

`user://profiles.cfg` on the tablet (on Windows,
`%APPDATA%\Godot\app_userdata\Little Light — David & Goliath Slice\`). Nothing leaves the tablet: no account,
no network. Each child's read-aloud choice and volumes are kept with them (`settings.cfg` still holds the
tablet's last values and is used until a child is chosen).

## How it is built

| File | What it does |
|---|---|
| `scripts/profiles.gd` | The saved children and what they earned (static functions, like `game_settings.gd`). |
| `scripts/journal_content.gd` | The verses and charms the journal can hold, and their read-aloud text. |
| `scripts/profile_screen.gd` | "Who is playing?" and the name and picture form. Pauses the game while open. |
| `scripts/journal_screen.gd` | The journal and the grown-ups' area. Pauses the game and keeps the audio director running so clips can play. |
| `scripts/avatar_icon.gd` | The little pictures (children, charm, "?", "+"), drawn in code. |
| `scripts/paper_ui.gd` | The paper-and-ink look shared with the pause menu. |
| `scripts/chapter_director.gd` | Waits for a child at the start, and awards the verse, charm and finished chapter. |
| `scripts/game_menu.gd` | The book button, the pause menu's Faith Journal and Change player, and My journal on the end panel. |

**Adding a verse or a charm:** add it to `journal_content.gd`, record its lines (for a verse: the spoken
reference and the verse) and list them in `vo_library.gd`, and unlock it from `chapter_director.gd`. The smoke
test fails if a journal line has no recorded clip.

## Things to know

- **`Profiles.use_file()`, not `Profiles.path = ...`.** Godot re-runs a script's static variable initialisers on
  the first call of any static function, which put the default path back and made an early version of the smoke
  test write into the real profile file. The test now uses `use_file()` and a scratch file.
- The journal works for a child who has earned nothing yet ("Your first verse is waiting in the story.").
- If read-aloud is off, **Hear it** says so instead of staying silent.

## Not done, and not tested

- **Drawing.** There is no drawing or colouring yet. Four ideas were sketched (colour your charm, colour a
  lamb, stickers, free drawing); colouring the charm would be the smallest first step.
- **On a real tablet.** The touch targets are large (at least 60 px) and there is a visible focus style for a
  gamepad or keyboard, but the on-screen keyboard for typing a name has not been tried, nor how it covers the
  form on a small screen.
- **Names are not checked** for words a family would not want. They are typed by the child or a grown-up and
  stay on the tablet.
- **The picker is not read aloud.** Its words are short, but a child who cannot read yet will rely on the pictures.
