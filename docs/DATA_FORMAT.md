# Data format

This document is the contract between the watch app and anything that reads
its activity files. It has two halves:

1. What the watch writes into the FIT activity file (developer fields).
2. What the converter in `tools/tennis_export` produces from that file
   (`points.csv`, `match.json` and `heatmap.png`).

## Status: a proposal, not yet proven on a watch

The converter half is built and tested. The watch half is **not built yet**:
the app does not write any of the fields below today. Version 1 of the format
is a proposal that the watch side must implement and then confirm on the
simulator and on a real watch. Every item that still needs that confirmation
is listed in [Still to be confirmed on the watch](#still-to-be-confirmed-on-the-watch).

The tests of the converter build FIT files with the encoder of the official
Garmin FIT SDK and read them back with its decoder. That proves the reader
against real FIT bytes. It does not prove that a watch produces the same
bytes.

## Part 1: what the watch writes

### Overview

The watch records a normal tennis activity (sport `tennis`) with heart rate
and, when enabled, GPS. On top of that it adds ten developer fields. The
limit agreed for the app is twelve, so two ids stay free.

| Id | Name | FIT message | Type | Count | Units | Meaning |
|---:|------|-------------|------|------:|-------|---------|
| 0 | `point_log` | record (20) | UINT32 | 9 | none | The newest three point log entries, three words each |
| 1 | `log_size` | session (18) | UINT16 | 1 | entries | Number of entries in the point log at save time |
| 2 | `match_setup` | session (18) | UINT32 | 1 | none | Format version, match configuration and tags, packed |
| 3 | `final_score` | session (18) | STRING | up to 32 bytes | none | Final score as text, for example `7-6(7-5) 6-3` |
| 4 | `statistics` | session (18) | UINT16 | 30 | counts | Fifteen statistics for each of the two players |
| 5 | `steps` | session (18) | UINT32 | 1 | steps | Steps taken during the activity |
| 6 | `distance` | session (18) | UINT32 | 1 | m | Distance covered during the activity |
| 7 | `set_score` | lap (19) | UINT8 | 4 | none | Games and tie break points of the set the lap covers |
| 8 | `set_steps` | lap (19) | UINT32 | 1 | steps | Steps taken during the set |
| 9 | `set_distance` | lap (19) | UINT32 | 1 | m | Distance covered during the set |

Ids 10 and 11 are not used.

Rules that hold for every field:

* Readers find a field by its **name**, taken from the field description
  messages of the file. The ids are listed so the watch side has one place
  to look them up.
* Player 0 is the watch owner ("me") and player 1 is the opponent, in every
  pair of values and every bit that names a player.
* The top bit of every packed UINT32 word is always zero. A word can then
  never equal the FIT "no value" marker (`0xFFFFFFFF`).
* A field that the watch cannot fill is left out of the message. Readers
  treat a missing field as "not known", never as zero.

### The point log (`point_log`, record message)

The watch keeps a log with one entry for each thing the player marked: a
point won by either player or a first serve fault. Entries are numbered from
1 in the order they were marked. This number is the **sequence number**.

Record messages are written about once a second. Each record carries the
newest entry and the two entries before it, so every entry is written many
times. Losing a few records therefore loses nothing, and a reader removes
the repeats by sequence number.

The field holds nine UINT32 words: three slots of three words. Slot 0 is the
newest entry, slot 1 the one before it, slot 2 the one before that. A slot
with sequence number 0 is empty.

Word 0 of a slot, the header:

| Bits | Meaning |
|------|---------|
| 0 to 15 | Sequence number, starting at 1. Zero means the slot is empty |
| 16 | Server of this point: 0 me, 1 opponent |
| 17 | 1 when the point was played on a second serve |
| 18 | 1 when the point was part of a tie break |
| 19 to 31 | Zero |

Word 1 of a slot, the entry itself. It is the packed point entry of the
watch engine, copied as is:

| Bits | Meaning |
|------|---------|
| 0 to 1 | Result: 0 first serve fault, 1 point for me, 2 point for the opponent |
| 2 to 4 | How it ended: 0 not marked, 1 winner, 2 ace, 3 error into the net, 4 error out |
| 5 to 12 | Heart rate in beats per minute when the entry was marked. Zero means no reading |
| 13 to 30 | Match clock in seconds when the entry was marked |
| 31 | Zero |

A fault (result 0) marked on a second serve is a double fault and gives the
point to the receiver.

Word 2 of a slot, the score right after the entry:

| Bits | Meaning |
|------|---------|
| 0 to 6 | Points of the current game for me, as a plain count (0, 1, 2, 3, ...), at most 127 |
| 7 to 13 | Points of the current game for the opponent, same rule |
| 14 to 17 | Games of the current set for me |
| 18 to 21 | Games of the current set for the opponent |
| 22 to 23 | Sets won by me |
| 24 to 25 | Sets won by the opponent |
| 26 to 31 | Zero |

Points are counts, not tennis words: 15 is 1, 30 is 2, 40 is 3 and so on
past deuce. A count above 127 (only possible in a very long tie break) is
stored as 127. When an entry closes a game the points are 0 and 0, and when
it closes a set the games are 0 and 0.

Small example. After the third entry of a match where I served and won three
points, with heart rates 120, 121 and 122 at clock times 20, 40 and 60:

```
slot 0: header 0x00000003, entry 0x00078F41, score 0x00000003
slot 1: header 0x00000002, entry 0x00050F21, score 0x00000002
slot 2: header 0x00000001, entry 0x00028F01, score 0x00000001
```

#### How a reader rebuilds the log

1. Walk the record messages in file order. For each filled slot, keep the
   entry under its sequence number. A later copy replaces an earlier one.
2. Undo: when the newest sequence number of a record is lower than sequence
   numbers already kept, the player undid those entries. Forget every kept
   entry above the newest sequence number of that record.
3. The expected length of the log is `log_size` when the session has it,
   otherwise the newest sequence number of the last record.
4. Every sequence number from 1 to the expected length that was not found is
   reported as missing.
5. Only the entries before the first missing one are replayed, because the
   score after a gap cannot be trusted.

The header and score words are not needed to replay the match. They exist so
a reader can check its own replay against what the watch saw, and so a
single record is still readable on its own.

### Match configuration and tags (`match_setup`, session message)

One UINT32 word:

| Bits | Meaning |
|------|---------|
| 0 to 3 | Format version. This document describes version 1 |
| 4 to 6 | Match format, see the table below |
| 7 | 1 when games are played with no advantage (deciding point at deuce) |
| 8 | Detail level: 0 simple (score only), 1 detailed (how points ended) |
| 9 | First server of the match: 0 me, 1 opponent |
| 10 to 11 | Surface tag: 0 not set, 1 clay, 2 hard, 3 grass |
| 12 to 13 | Kind tag: 0 not set, 1 match, 2 friendly |
| 14 to 31 | Zero |

Match formats:

| Code | Name | Rules |
|-----:|------|-------|
| 0 | `best_of_3` | Best of three sets to 6 games, tie break to 7 at 6 games all |
| 1 | `best_of_3_match_tie_break` | As above, but a third set is replaced by a tie break to 10 |
| 2 | `one_set` | One set to 6 games, tie break to 7 at 6 games all |
| 3 | `pro_set` | One set to 8 games, tie break to 7 at 8 games all |
| 4 | `tie_break_only` | One tie break to 10 |

Every set and tie break is won by a margin of two. The codes are the ones
the watch engine already uses for its formats.

A session without `match_setup` is not a match recorded by this app. A
reader must refuse a version it does not know instead of guessing.

### Session summary (session message)

* `log_size`: number of entries in the log when the activity was saved.
* `final_score`: the score as the watch shows it, as text. Kept for people
  who open the file in other tools.
* `statistics`: thirty UINT16 counts. The value for statistic `s` and
  player `p` is at index `s * 2 + p`.

| Index of the statistic | Name |
|-----:|------|
| 0 | `service_points` |
| 1 | `first_serves_in` |
| 2 | `first_serve_points_won` |
| 3 | `second_serve_points_won` |
| 4 | `double_faults` |
| 5 | `service_games_played` |
| 6 | `service_games_won` |
| 7 | `break_point_chances` |
| 8 | `break_points_won` |
| 9 | `points_won` |
| 10 | `longest_run` |
| 11 | `winners` |
| 12 | `aces` |
| 13 | `errors_net` |
| 14 | `errors_out` |

  The order is the order of the statistics in the watch engine.
* `steps` and `distance`: totals for the activity. They are developer
  fields because a tennis activity does not always fill the native ones.

### One lap for each set (lap message)

The watch closes a lap when a set ends, so lap `n` covers set `n`. A match
that is stopped during a set ends with a lap for the part that was played.

* `set_score`: four UINT8 values: games for me, games for the opponent, tie
  break points for me, tie break points for the opponent. The tie break
  points are 0 and 0 when the set had no tie break.
* `set_steps` and `set_distance`: steps and meters during the set.

The native lap fields (start time, elapsed time, timer time) give the
duration of the set.

### Still to be confirmed on the watch

None of this has run on a simulator or a watch. The watch side must check
each point and this document must be corrected where reality differs.

1. **Nothing is written yet.** The fields, ids, names and packing above are
   a proposal until the watch code exists.
2. **Record fields under Smart Recording.** Smart Recording may write
   records less often than once a second. Three entries per record should
   cover that, but it must be measured: mark points quickly, save, and
   check that no sequence number is missing.
3. **The last entries before saving.** An entry marked just before the
   activity is saved may never reach a record. `log_size` lets a reader see
   that. The watch side should make sure a record is written after the last
   entry, or accept the loss and say so.
4. **Array fields.** `point_log` (9 values in a record), `statistics`
   (30 values) and `set_score` (4 values) rely on array developer fields.
   Whether the Connect IQ FIT contributor writes them as designed, in
   records, laps and sessions, must be confirmed.
5. **Size limits.** A message may hold at most 256 bytes of developer data.
   The session uses about 110 and a record 36, by design. To be confirmed
   with a real file.
6. **Number of fields.** Ten fields against a working limit of twelve. The
   real limit of each target watch must be checked.
7. **Garmin Connect display.** Array fields and packed words are not meant
   to be shown in Garmin Connect. How Connect treats them is unknown.
8. **Undo.** The reader rule for undo (rule 2 above) assumes the watch
   lowers the newest sequence number after an undo and reuses the numbers.
9. **Laps.** That the watch can close one lap for each set, and that steps
   and distance per set are available on every target watch.
10. **Field names.** The reader matches fields by name only. It does not
    check the application id of the developer data.

## Part 2: what the converter produces

```bash
uv run tennis-export activity.fit --out some-directory
```

Without `--out` the files go to a directory named after the file, next to
it (`activity-export`). The command prints the path of every file it wrote.
It exits with status 2 and a one line message when the file cannot be read,
is not a FIT file, or carries a format version or match format it does not
know.

The converter rebuilds the point log, then replays it with a Python port of
the watch scoring rules (formats, tie breaks, no advantage, serve
rotation). Scores and statistics in the output come from that replay, not
from the summary fields of the watch. The summary fields are only used to
cross check (see `integrity`).

A FIT file that was not recorded by this app still converts: `match.json`
then holds the activity data only and `points.csv` holds only its header
line.

### `points.csv`

One row for each replayed entry of the point log, in the order played. The
first line names the columns. Empty cells mean "does not apply".

| Column | Meaning |
|--------|---------|
| `sequence` | Sequence number of the entry |
| `time_s` | Match clock in seconds when the entry was marked |
| `heart_rate` | Beats per minute at that moment, empty when there was no reading |
| `set` | Set number, starting at 1 |
| `game` | Game number inside the set, starting at 1 |
| `point` | Point number inside the game, starting at 1 |
| `server` | `me` or `opponent` |
| `serve` | `1` for a first serve, `2` for a second serve |
| `kind` | `point`, `fault` (first serve fault, no point played) or `double_fault` |
| `winner` | `me` or `opponent`, empty for a fault |
| `ending` | `none`, `winner`, `ace`, `error_net` or `error_out` |
| `tie_break` | `1` when the entry is part of a tie break, else `0` |
| `break_point` | `1` when the receiver could win the game with this point |
| `set_point` | `1` when a player could win the set with this point |
| `match_point` | `1` when a player could win the match with this point |
| `score_me` | My points in the game after the entry: `0`, `15`, `30`, `40`, `AD`, or a count in a tie break |
| `score_opponent` | Same for the opponent |
| `games_me` | My games in the set after the entry |
| `games_opponent` | Same for the opponent |
| `sets_me` | Sets I have won after the entry |
| `sets_opponent` | Same for the opponent |
| `closes` | `game`, `set` or `match` when the entry ended one, else empty |

After an entry that closes a game the point columns read `0`, and after one
that closes a set the game columns read `0`.

### `match.json`

```
{
  "format_version": 1,
  "source": "activity.fit",            file name that was converted
  "activity": { ... },                  always present
  "match": { ... } or null,             null when the file is not from this app
  "point_log": { ... } or null,
  "integrity": { ... } or null,
  "watch_summary": { ... } or null,
  "heat_map": { ... } or null           null without a usable GPS track
}
```

In every pair written as `[a, b]`, `a` is for me and `b` for the opponent.
A value the file does not carry is `null`.

`activity`:

| Key | Type | Meaning |
|-----|------|---------|
| `start_time` | text or null | Start of the activity, ISO 8601 in UTC |
| `sport` | text or null | Sport of the session, `tennis` for this app |
| `elapsed_seconds` | number or null | Time from start to save |
| `timer_seconds` | number or null | Time with the timer running |
| `calories` | number or null | Total calories |
| `heart_rate` | object or null | `average`, `max`, `min` (beats per minute) and `samples` (records with a reading) |
| `steps` | number or null | The `steps` developer field |
| `distance_m` | number or null | The `distance` developer field, else the native total distance |
| `has_gps` | true or false | Whether any record has a position |

`match`:

| Key | Type | Meaning |
|-----|------|---------|
| `config.format` | text | One of the format names of Part 1 |
| `config.no_advantage` | true or false | Deciding point at deuce |
| `config.detail_level` | text | `simple` or `detailed` |
| `config.first_server` | text | `me` or `opponent` |
| `tags.surface` | text or null | `clay`, `hard`, `grass` |
| `tags.kind` | text or null | `match` or `friendly` |
| `finished` | true or false | Whether the replayed log reaches the end of the match |
| `winner` | text or null | `me`, `opponent`, or null when not finished |
| `score.sets` | list of pairs | Games of each closed set |
| `score.current_games` | pair | Games of the set in progress |
| `score.current_points` | pair of text | Points of the game in progress, as in the CSV |
| `score.text` | text | For example `7-6(7-5) 6-3`. A set in progress is added at the end |
| `sets` | list | One object for each closed set, see below |
| `games` | list | One object for each closed game, see below |
| `statistics` | object | See below |

Each object of `sets`: `set` (number from 1), `games` (pair),
`tie_break_points` (pair or null), `winner`, `duration_seconds` (from the
match clock of the log), `steps` and `distance_m` (from the lap of the set,
null without one).

Each object of `games`: `set`, `game` (number inside the set), `server`,
`winner`, `tie_break` (true or false) and `duration_seconds`.

Durations come from the match clock stored with each entry: a game or set
lasts from the entry that closed the one before it (or from zero) to the
entry that closed it.

`statistics` has one object for `me` and one for `opponent`, each with the
fifteen counts named in Part 1 plus these derived values:

| Key | Meaning |
|-----|---------|
| `first_serve_percent` | First serves in, as a whole percent of service points, 0 with no service points |
| `second_serve_points` | Service points played on a second serve |
| `return_games_played` | Service games of the other player |
| `return_games_won` | Breaks of serve |
| `break_points_faced` | Break point chances of the other player |
| `break_points_saved` | Those the other player did not win |

and two values for the match as a whole:

| Key | Meaning |
|-----|---------|
| `average_seconds_between_points` | Time from the first point to the last, divided by the number of points minus one, one decimal. 0 with fewer than two points |
| `average_deciding_heart_rate` | Mean heart rate on break and set points that carried a reading, or null |

`point_log`:

| Key | Meaning |
|-----|---------|
| `entries_expected` | Length of the log according to the watch |
| `entries_recovered` | Entries found in the records |
| `entries_replayed` | Entries used for the score and statistics |
| `missing_sequences` | Sequence numbers that were expected and not found |

`integrity` compares the replay with what the watch stored:

| Key | Meaning |
|-----|---------|
| `score_mismatches` | Sequence numbers whose stored header or score differs from the replay |
| `statistics_match` | Whether the `statistics` field equals the replayed counts, null without the field |
| `set_scores_match` | Whether the `set_score` of the laps equals the replayed closed sets, null without the field |

`watch_summary` holds `final_score`, the text the watch stored, untouched.

`heat_map`: `file` (`heatmap.png`), `method` (`principal_axis`),
`approximate` (always true), `track_points` (positions in the file),
`points_drawn` (positions that fall inside the picture) and
`rotation_degrees` (direction taken as the court length, counted
counterclockwise from east, from 0 to 180).

### `heatmap.png`

Written only when the activity has at least ten GPS positions. It shows
where the player spent time, drawn over the outline of a tennis court, with
the title "Approximate court heat map".

The watch has no calibration step, so the file does not say where the court
is or which way it points. The converter estimates both from the track
alone:

1. **Meters.** Positions are turned into meters east and north of their
   mean, with a flat earth approximation. Over the size of a court the
   error of that step is far below GPS noise.
2. **Direction.** A player moves mostly along the length of the court
   (baseline to net, and to the other end after a change of ends). The
   direction in which the track is spread the most (the principal axis of
   the positions) is taken as the court length. The track is rotated so
   that direction points up. It is only rotated, never stretched.
3. **Center.** Across the court, the middle is the median of the
   positions. Along the court, the middle (the net) is halfway between the
   5th and 95th percentile, which ignores a walk to the bench or the gate.
4. **Which end is up.** The principal axis has no front or back. The
   picture is turned so the end where the track starts is at the bottom.
5. **Shading.** Positions are counted in squares of one meter. A square is
   shaded by the square root of its count, so places visited rarely still
   show. The court lines (doubles and singles lines, service lines, net)
   are drawn on top at the official size, 23.77 by 10.97 meters.

Limits, and why the picture is labeled approximate:

* GPS on a watch is off by several meters, which is a large share of a
  court that is 11 meters wide. The picture shows tendencies (behind the
  baseline, at the net, forehand side), not exact footprints.
* The court is placed by where the player moved, not by where the lines
  are. A player who stays on one side of the court, or who only plays at
  one end, shifts the estimate.
* A session with little movement along the court (for example serving
  practice from one spot, or a track that is mostly a walk around the
  court) can give the wrong direction.
* Which end is drawn at the bottom is a guess. When the first position of
  the track is not at the end where the player started, the picture is
  turned half a turn relative to what the player expects.
* Positions outside the drawn area (more than 11 meters across or 20
  meters along from the center) are left out and counted in
  `track_points` but not in `points_drawn`.

A calibration step on the watch (for example marking two corners) would
remove most of these limits. It is not part of version 1.

## Libraries used by the converter

* **FIT reading: `garmin-fit-sdk` 21.221.0**, pinned exactly. It is the
  official Garmin SDK for Python. It decodes developer fields and array
  values (checked by the tests, which read every field above back from real
  bytes), and its encoder writes them too, so the tests build their FIT
  files with the same library and no hand written encoder is needed.
* **Drawing: Pillow** (version 13). The heat map is rectangles, lines and
  three short labels. Pillow does that with one small dependency and no
  numeric stack. matplotlib would add numpy and several other packages for
  no gain here.
