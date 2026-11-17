# Recording

How a match becomes a Garmin activity, what the app keeps in storage while
a match is open, and what happens when the app closes in the middle of one.
The code lives in `source/recording/`.

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
| 0 | point_log | record | UINT32 array | | M6 (planned) |
| 1 | log_size | session | | | M6 (planned) |
| 2 | match_setup | session | UINT32 | | M5 |
| 3 | final_score | session | STRING, 32 bytes | | M5 |
| 4 | statistics | session | UINT16 array of 30 | counts | M5 |
| 5 | steps | session | UINT32 | steps | M4 |
| 6 | distance | session | UINT32 | m | M4 |
| 7 | set_score | lap | UINT8 array of 4 | | M5 |
| 8 | set_steps | lap | UINT32 | steps | M4 |
| 9 | set_distance | lap | UINT32 | m | M4 |

Used: 8. Planned in total: 10. Free: 2.

The four summary fields are built by `source/match/MatchSummary.mc` and
written by `MatchRecorder.writeSummary`: when the match opens, when the app
closes with a match in progress and when the player saves. `set_score` is
written right before each lap closes, so every lap carries the score of its
set. Only the fields with a unit have a label for Garmin Connect; a label
needs a unit, and the packed and text fields have none.

Checked on the simulator (fr55): a scripted one set match saved with the
tags clay and friendly gave a file with `match_setup` 9505, `final_score`
`6-1`, the thirty counts and one lap with `set_score` 6, 1, 0, 0;
`tennis-export` read all of them back.

The ids and names in code are in `source/recording/RecordingFields.mc`; the
labels shown by Garmin Connect are in `resources/fit/fitcontributions.xml`.

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

Rules:

* Starting a match writes `match` and removes the keys of any older match.
* After each point, fault or correction only the key of the set in progress
  is written again. A correction that goes back over a set removes the keys
  of the sets after it.
* Save and Discard remove every key of the match.
* A `match` value with another version or shape is ignored.

## Resuming a match

* When the home screen shows and a stored match exists, the app offers
  Resume or Discard. BACK leaves the stored match for later. Starting a new
  match replaces it.
* Resume replays the stored log, so score, server, sides and statistics come
  back exactly. The match clock goes on from the time of the last entry.
* A fault that was waiting for its second serve is in the log and comes
  back too. A point whose ending was still being chosen is lost.

## What happens to the activity when the app closes

* When the app closes with a match open, the app saves the activity recorded
  so far and keeps the stored match. A resumed match records a **new**
  activity: the match then has two activity files, each with its own time,
  steps, distance and laps. The second file opens laps only for the sets
  that close after the resume.
* When the app closes on the final score screen without a choice, the
  activity is saved and the stored match is removed.
* The app never leaves a running session unsaved. On the simulator, an app
  that exits with a session still recording leaves a broken file and brings
  the simulator down.
* If the watch itself restarts or the battery dies, `onStop` does not run:
  the activity file of that part is most likely lost, but the stored match
  is still there and can be resumed.
