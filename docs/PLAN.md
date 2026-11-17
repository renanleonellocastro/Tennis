# Tennis: product plan

Status: requirements agreed on 2026-11-17. Implementation has not started.

## 1. Goal

A Garmin watch app that records a full tennis match or practice: live score,
how every point ended, heart rate, calories, steps and distance, with a
statistics report at the end and open data export. Same developer identity
as [Stretches](https://github.com/renanleonellocastro/Stretches), MIT
licensed and open to the community.

## 2. Decisions

### Scope
* Singles in version 1. The point log and the serve rotation are modeled so
  doubles can be added next without rework.
* Same reach as Stretches: the same 80 watch models (Forerunner 55 is the
  reference device) and 6 languages (English, Portuguese, Spanish, French,
  German, Italian).

### Match formats
* Presets chosen at start: best of 3 sets, best of 3 with a 10 point match
  tie break in place of the third set, 1 set, 8 game pro set, tie break only.
* Setting for no advantage scoring (deciding point at 40 all).
* The last format used becomes the default.
* The player picks who serves first. Serve rotation in tie breaks and the
  change of ends are handled by the app.

### Logging a point
* Detail level chosen at start:
  * Simple: one press, who won the point.
  * Detailed: two presses, who won and then how it ended.
* Detailed list when I win: Winner, Ace (only on my serve), Opponent error
  in the net, Opponent error out.
* Detailed list when the opponent wins: Opponent winner, Opponent ace (only
  on their serve), My error in the net, My error out.
* Serve faults are logged for both players with one button. First press is
  a missed first serve and shows a small second serve mark. Second press is
  a double fault and the point goes to the receiver automatically.

### Match screen
* Side by side layout: me on the left, opponent on the right, game points
  in large digits on one line.
* Set score in small digits at the top.
* Ball colored dot next to the player who serves.
* Mini court that shows the side to serve from (deuce or ad) and the end of
  the court each player is on.
* Heart rate and match clock at the bottom.
* Discreet labels for break point, set point and match point.

### Controls
* UP: point for me. DOWN: point for the opponent.
* START: serve fault.
* BACK: undo the last entry.
* Hold UP (standard Garmin menu): pause, end, fix the score.
* On touch screens, a tap on the left or right half also scores the point.
* A subtle hint on the edge of the screen reminds which button belongs to
  which player.

### Practice mode
* Records time, heart rate, calories, steps and distance.
* Free counters: UP is a hit, DOWN is a miss, one button closes the block
  (for example serves, then forehands).
* The summary shows the success rate per block.

### Report and data
* On the watch, after the match: scrollable pages with the final score per
  set, serve numbers, point types, pressure numbers, times, heart rate and
  calories.
* In Garmin Connect: a Tennis activity with heart rate, calories, steps,
  distance, one lap per set and the main statistics as extra fields.
* No match history is kept on the watch. History lives in Garmin Connect
  and in the export.
* Export: every point is stored inside the activity file (FIT, the open
  Garmin format): server, fault, winner, how it ended, score and time. The
  repository ships a free converter that turns the file into CSV and JSON,
  with the format documented so other systems, such as a club system, can
  read it.

### Statistics
* Serve: aces, double faults, first serve percentage, points won on first
  and on second serve, service games won.
* Return: return games won, break points won.
* Points: winners, errors in the net, errors out, total points won.
* Pressure: break points won and saved, longest run of points, average
  heart rate on deciding points.
* Times: duration of each set and game, average time between points.
* Everything is computed for both players where the log allows it.

### Sensors
* Steps and distance are always recorded.
* GPS is an optional switch (it costs battery and needs an open court).
  Watches without GPS do not show the switch.
* The converter draws a heat map of the court from the GPS track, labeled
  as approximate, because watch GPS is off by 3 to 5 meters on a court of
  24 by 11 meters.

### Extras in version 1
* Vibration and notice when it is time to change ends.
* Match tags when saving: surface (clay, hard, grass) and match or friendly.
* An interrupted match can be resumed.

### Visual identity
* Reused from Stretches: black background, fonts, menus, pill buttons,
  brand arc and the colors that render cleanly on 64 color displays.
* Orange stays the brand color. Tennis ball yellow is a detail color only:
  serve dot, mini court and icon.

## 3. Technical approach

* Monkey C, Connect IQ watch app, same project layout, Makefile, quality
  gates and CI as Stretches.
* A pure scoring engine (points, games, sets, tie breaks, serve rotation,
  ends, undo) with no user interface code, fully covered by unit tests.
* The point log is the single source of truth. Score and statistics are
  derived from it, which makes undo and resume simple and safe.
* Activity recording with FIT developer fields for the summary and for the
  point log.
* Converter in Python under `tools/`, with tests and a documented data
  format in `docs/DATA_FORMAT.md`.

## 4. Open technical checks

To confirm before the design is frozen:

* Tennis sport type and step data availability on all 80 devices.
* Limits of FIT developer fields for a point log of 300 or more points, and
  the best message type to carry it.
* Memory use on the Forerunner 55 with the full point log in memory.
* Touch input and long press behavior across button and touch watches.
* GPS availability flag per device, to hide the switch where there is none.

## 5. Milestones

* M0 Foundation: project skeleton copied from the Stretches pattern, shared
  theme, CI green, empty app runs on the simulator.
* M1 Scoring engine: all formats, serve rotation, ends, undo, with tests.
* M2 Match screen and controls: simple mode playable from start to end.
* M3 Detailed mode: point endings and serve faults.
* M4 Recording: Tennis activity, heart rate, calories, steps, distance,
  optional GPS, laps per set, resume after interruption.
* M5 Report: summary pages on the watch, summary fields in Garmin Connect,
  match tags.
* M6 Export: point log in the FIT file, converter to CSV and JSON, data
  format document, heat map.
* M7 Practice mode with counters.
* M8 Release: 6 languages, device audit, on device test pass, store assets
  and listing.

## 6. Later versions

* Doubles.
* Stroke per point (forehand, backhand, volley, smash, return).
* Forced and unforced errors.
* Automatic upload of a match to a configured address.
* Guided practice drills.
* Court calibration for a more precise heat map.
