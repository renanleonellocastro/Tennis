# Recording

How a match or a practice becomes a Garmin activity, what the app keeps in storage while
a match is open, and what happens when the app closes in the middle of one.
The code lives in `source/recording/`; a practice reuses it through
`source/practice/PracticeRecorder.mc`.

## The activity

* Sport `Activity.SPORT_TENNIS`, sub sport `Activity.SUB_SPORT_GENERIC`.
* The session starts when the match screen opens, stops while the match is
  paused or shows its final score, and starts again on resume or reopen.
* One lap per set. A lap is opened when a set closes and the match goes on;
  saving closes the lap of the last set. A lap cannot be taken back: a set
  that is undone and played again keeps the lap it already opened.
* Heart rate, calories and (with the GPS switch on) the track are recorded
  by the watch itself. The app reads the current heart rate from
  `Activity.getActivityInfo()` to show it next to the clock and to stamp
  each point in the log.
* Steps and distance come from `ActivityMonitor.getInfo()`. The app counts
  only the change while the session runs (a pause is left out, a reset at
  midnight is handled) and writes the totals once a second.
* The GPS switch of the match setup is shown only on watches with
  `Toybox.Position`. It is off by default and remembered with the other
  setup choices.

## Developer fields

A Connect IQ app may add a limited number of developer fields to an
activity. The app plans for 12 at most. Ids are shared with the export tool
(`docs/DATA_FORMAT.md`), so they must not change once released.

| Id | Name | Message | Type | Unit | Written by |
|---|---|---|---|---|---|
| 0 | point_log | record | UINT32 array of 9 | | M6 |
| 1 | log_size | session | UINT16 | entries | M6 |
| 2 | match_setup | session | UINT32 | | M5 |
| 3 | final_score | session | STRING, 32 bytes | | M5 |
| 4 | statistics | session | UINT16 array of 30 | counts | M5 |
| 5 | steps | session | UINT32 | steps | M4 |
| 6 | distance | session | UINT32 | m | M4 |
| 7 | set_score | lap | UINT8 array of 4 | | M5 |
| 8 | set_steps | lap | UINT32 | steps | M4 |
| 9 | set_distance | lap | UINT32 | m | M4 |
| 10 | block_hits | lap | UINT32 | shots | M7 (practice) |
| 11 | block_misses | lap | UINT32 | shots | M7 (practice) |

Used: 12. Free: 0.

The summary fields (`log_size` and the four above) are built by
`source/match/MatchSummary.mc` and written by `MatchRecorder.writeSummary`: when the match opens, when the app
closes with a match in progress and when the player saves. `set_score` is
written right before each lap closes, so every lap carries the score of its
set. Only the fields with a unit have a label for Garmin Connect; a label
needs a unit, and the packed and text fields have none.

Checked on the simulator (fr55): a scripted one set match saved with the
tags clay and friendly gave a file with `match_setup` 9505, `final_score`
`6-1`, the thirty counts and one lap with `set_score` 6, 1, 0, 0;
`tennis-export` read all of them back.

## The point log in the file

`point_log` holds the newest three entries of the log, three words each
(`source/engine/PointSlot.mc`; layout in `docs/DATA_FORMAT.md`). The engine
keeps the nine words ready, so writing them costs no replay.

What the simulator showed, and what the code does about it:

* An array field is accepted on a record. A field value stays: every record
  written after `setData` carries it until the next `setData`.
* Records are written once a second while the timer runs, plus one at each
  timer start and stop. Saving writes no record. A value set right before
  `save()` is lost; a value set right before `start()` or `stop()` is in
  the record of that start or stop.
* So `MatchController` writes the point log **before** it starts or stops
  the session, after every point, fault and correction, and once when the
  match screen opens.
* Two entries a second for a whole match lost nothing (three entries fit
  between two records).
* The simulator looks at the session about once a second. A `save()` that
  came before the look that follows a `stop()` closed the file without the
  record of that stop (about half of the runs with a save 50 to 800 ms
  after the stop, none from 1200 ms on). A `start()` and a `stop()` inside
  the same second left no record at all.
* So the session of a match is wrapped in `PacedSession`: a stop waits
  until the last start is 1.5 seconds old and a save until the last stop
  is. A start that comes while a stop still waits drops that stop. The
  wait runs on one timer (`WatchAlarm`, owned by the app). The goodbye
  screen stays up while a save waits, and when the app closes anyway
  whatever waits is done at once.
* The point log field is paced by the same wait. It holds three entries,
  and a game given by "Fix the score" logs four points or more at once.
  `ScoreFixer` hands each point to the recorder, and `PacedSession` keeps
  every value of the field for 1.5 seconds before the next one replaces
  it. Values that wait are merged, so the file gets the entries three at
  a time. A stop waits for the last value and follows it at once.
* An undo writes the field again with a lower newest sequence number; the
  converter drops the undone entries.

Accepted for version 1:

* An entry marked in the last second before the app closes may be missing
  from the file being closed. The resumed file repeats the newest three
  entries in its first record, which brings it back.
* A correction made while paused that ends the match, saved without a
  resume, reaches no record. `log_size` shows the gap.
* A match whose last point is marked and the app is closed (not saved
  from the menu) within the next second and a half is saved at once, so
  its last entry may miss the file. `log_size` shows the gap.
* Smart Recording on a real watch (records less often than once a second)
  cannot be tested on the simulator.

Checked on the simulator (fr55) with scripted matches converted by
`tennis-export` and compared entry by entry with the script: see
"Checked on the simulator" in `docs/DATA_FORMAT.md`.

The ids and names in code are in `source/recording/RecordingFields.mc`; the
labels shown by Garmin Connect are in `resources/fit/fitcontributions.xml`.
The table of fields is built only while a session is created, so it does
not stay in memory during the match.

## Practice

A practice records the same kind of activity as a match, through the same
session, sensors and step counting. `PracticeRecorder` wraps `MatchRecorder`
and adds only the two block fields.

* The session starts when the practice screen opens, stops on pause and on
  the summary, and starts again on resume or when the summary is left with
  BACK.
* One lap per block. Closing a block writes its hits and misses on the lap,
  opens the next lap and starts both fields from zero. Every hit, miss and
  undo rewrites the two fields, so the lap that is open always carries the
  current counts.
* A block with no entries does not close, and a closed block cannot be
  reopened (a lap cannot be taken back).
* No GPS and no setup screen: a practice starts straight from the menu.
* A practice is not kept in storage and cannot be resumed. When the app
  closes with a practice open, or on its summary without a choice, the
  activity recorded so far is saved.
* Each kind of activity creates only its own fields: a practice has the
  movement fields and the two block fields, a match has the movement
  fields and the match fields. A simulator practice file was read back and
  carries no match field.

## Storage keys

`Application.Storage` holds the match in progress, so it survives the app
closing. Every value is a small array, far below the 8 KB that every watch
accepts for one value.

| Key | Value |
|---|---|
| `setup` | The remembered setup choices (written by `SetupStore`) |
| `tags` | The surface and the kind of the last saved match (written by `TagStore`) |
| `match` | `[version, setup values]` of the match in progress. Version is 1 |
| `set0`, `set1`, ... | The point log entries of each set, one key per set |
| `marks` | The marks of the engine (see below), one small array per mark |

Rules:

* Starting a match writes `match` and removes the keys of any older match.
* After each point, fault or correction only the key of the set in progress
  is written again. A correction that goes back over a set removes the keys
  of the sets after it.
* `marks` is written only when the number of marks changes (about once
  every 48 entries, or when a correction goes back over a mark).
* Save and Discard remove every key of the match.
* A `match` value with another version or shape is ignored.

## Marks: why a long match stays fast

The watch stops an app whose code runs too long in one go (the simulator
reports "Watchdog Tripped Error - Code Executed Too Long"). Replaying a
whole log did that: on the fr55 simulator a full replay of state and
statistics passed with 140 entries and was stopped with 160, and a real
match has 300 or more.

So the engine never replays the whole log:

* The statistics are counted as the match goes (`StatisticsCollector`),
  not by a replay when the report opens.
* When a game closes and 48 or more entries were added since the last
  mark, the engine takes a **mark**: the size of the log, where the game
  before started, the statistics so far and the state of the match.
* An undo, a correction or a resume restores the newest mark that is at
  least three entries behind the end of the log and replays only the
  entries after it: about 48 entries plus one game at most.
* A correction that goes back over a mark drops it.
* The marks are stored with the match, so a resume is as fast.

Checked on the simulator: a match of 300 entries and more was played,
corrected, saved and its report opened without the watchdog.

## Resuming a match

* When the home screen shows and a stored match exists, the app offers
  Resume or Discard. BACK leaves the stored match for later. Starting a new
  match replaces it.
* Resume restores the newest stored mark and replays the entries after it,
  so score, server, sides and statistics come back exactly. The match clock
  goes on from the time of the last entry, and the sequence numbers of the
  point log go on too.
* The first record of the new activity file repeats the newest three
  entries of the log.
* A fault that was waiting for its second serve is in the log and comes
  back too. A point whose ending was still being chosen is lost.

## What happens to the activity when the app closes

* When the app closes with a match open, the app saves the activity recorded
  so far and keeps the stored match. A resumed match records a **new**
  activity: the match then has two activity files, each with its own time,
  steps, distance and laps. `log_size`, `statistics` and `final_score` of
  each file cover the whole match up to that moment, so the last file
  speaks for the match. `tennis-export` joins the files when all of them
  are given. The second file opens laps only for the sets
  that close after the resume.
* When the app closes on the final score screen without a choice, the
  activity is saved and the stored match is removed.
* The app never leaves a running session unsaved. On the simulator, an app
  that exits with a session still recording leaves a broken file and brings
  the simulator down.
* If the watch itself restarts or the battery dies, `onStop` does not run:
  the activity file of that part is most likely lost, but the stored match
  is still there and can be resumed.
