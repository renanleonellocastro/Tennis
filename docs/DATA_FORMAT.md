# Data format

This document is the contract between the watch app and anything that reads
its activity files. It has two halves:

1. What the watch writes into the FIT activity file (developer fields).
2. What the converter in `tools/tennis_export` produces from that file
   (`points.csv`, `match.json` and `heatmap.png` for a match, `blocks.csv`
   and `practice.json` for a practice).

## Status: proven on the simulator

Both halves are built and tested. The watch writes all twelve fields: the
point log (`point_log`, `log_size`), the summary of the match
(`match_setup`, `final_score`, `statistics`, `set_score`), the movement
totals (`steps`, `distance`, `set_steps`, `set_distance`) and the two
practice fields. Scripted matches played on the simulator (fr55) were
converted with this tool and compared with the script entry by entry: see
[Checked on the simulator](#checked-on-the-simulator). A practice saved by
the simulator was converted too: one lap for each block, with its hits and
misses. Nothing has run on a real watch. Every item that still needs
confirmation is listed in
[Still to be confirmed on the watch](#still-to-be-confirmed-on-the-watch).

The tests of the converter build FIT files with the encoder of the official
Garmin FIT SDK and read them back with its decoder. That proves the reader
against real FIT bytes. It does not prove that a watch produces the same
bytes.

## Part 1: what the watch writes

### Overview

The watch records a normal tennis activity (sport `tennis`) with heart rate
and, when enabled, GPS. On top of that it adds twelve developer fields: ten
for a match and two for a practice. The limit agreed for the app is twelve,
so no id stays free.

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
| 10 | `block_hits` | lap (19) | UINT32 | 1 | shots | Practice only: hits counted in the block the lap covers |
| 11 | `block_misses` | lap (19) | UINT32 | 1 | shots | Practice only: misses counted in the block the lap covers |

> **Considered, not built: a match identifier.** A match that is closed and
> resumed is saved as several activity files, and nothing in them says
> "these belong together". A dedicated `match_id` field would make that
> check exact, but the budget of 12 developer fields is already taken
> (ids 10 and 11 are reserved for the practice block laps), so it would
> have to travel inside `match_setup`. The converter works without it: it
> tells the files of one match apart with the rules in
> [Several files of one match](#several-files-of-one-match).

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

A record written before the watch set the field for the first time holds
the FIT "no value" marker (`0xFFFFFFFF`) in every word. A reader skips such
a record. The app sets the field before it starts the timer, so its files
should not have one.

#### How the watch writes the log

These rules were found by test on the simulator and the watch code follows
them.

* **When the field is set.** After every point, fault and correction, and
  once when the match screen opens (also on resume), the app sets the
  field to the newest three entries. A field value stays: the watch copies
  it to every record until the app sets it again.
* **When records are written.** The watch writes one record a second while
  the timer runs, and one more at every timer start and stop. Saving the
  activity writes **no** record. So the app always sets the field
  **before** it starts or stops the timer: the record of that start or
  stop then carries the newest entries.
* **Entries between two records.** A record holds three entries, so up to
  three entries marked within one second all reach the file. Two entries a
  second, kept up for a whole match, lost nothing.
* **Undo.** An undo sets the field again with a lower newest sequence
  number, and the numbers above it are used again by the next entries.
  An entry that was written and then undone stays in older records and is
  dropped by reader rule 2.
* **The last entry.** The entry that ends the match stops the timer, and
  the record of that stop carries it. An entry marked in the last second
  before the app closes may miss the file that is being closed: `log_size`
  of that file shows it, and the file of the resumed match repeats the
  entry (see below).
* **Two corners that lose entries.** A correction made while the match is
  paused, when it ends the match and the player saves without resuming,
  reaches no record. And a finished match that is reopened and finished
  again within about a second may miss its last entry: the stop record
  was written in most runs on the simulator, but not in all. In both
  cases `log_size` is larger than the entries found and the converter
  reports them as missing.

#### A match that is closed and resumed

A resumed match records a new activity file. The rules, which the
converter relies on to join the files:

* Sequence numbers go on where the file before stopped. They never start
  again at 1.
* The match clock inside the entries goes on from the clock of the last
  entry.
* The first record of the new file carries the newest three entries of the
  match as they were when the app closed, so it repeats entries of the
  file before it (and heals an entry that missed that file).
* `log_size`, `statistics` and `final_score` of each file describe the
  whole match up to the moment that file was saved, never only the part
  played in it. The last file therefore speaks for the whole match.
* `match_setup` of a file saved because the app closed has both tags at
  zero: the tags are chosen when the player saves. All other bits are the
  same in every file of the match.
* `steps`, `distance` and the laps count from the start of each file.

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
* `final_score`: the score as text, built the same way as `score.text` of
  `match.json`: the closed sets as on a scoreboard, then the games of a set
  that was still open (`7-6(7-5) 6-3`, `6-4 2-1`). A match that stops
  right after a set has no open set: the text is `6-1`, not `6-1 0-0`. A
  new set counts as open from its first point (`6-1 0-0` then means a
  first game in progress), and a match with no closed set always shows its
  games (`0-0`). Kept for people who open the file in other tools. The watch cuts the text at 31 characters, which
  only a match with three long tie breaks can reach.
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

The watch closes a lap when a set ends. A match that is stopped during a
set ends with a lap for the part that was played.

Lap `n` is not always set `n`, so a reader must not count laps:

* A lap cannot be removed. A set that is undone and played again leaves
  two laps: the one closed before the undo and the one closed when the set
  ended again.
* A match that was closed and resumed is saved as two activity files. The
  set that was open has one lap at the end of the first file and one at the
  start of the second.
* Files from the simulator also repeat laps that lasted no time at all.

The converter places laps by time instead, see
[Laps and sets](#laps-and-sets).

* `set_score`: four UINT8 values: games for me, games for the opponent, tie
  break points for me, tie break points for the opponent. The tie break
  points are 0 and 0 when the set had no tie break. The last lap of a match
  stopped during a set holds the games played of that set, and the points
  of a tie break that was under way.
* `set_steps` and `set_distance`: steps and meters during the set.

The native lap fields (start time, elapsed time, timer time) give the
duration of the set.

### When the watch writes the summary

The session fields are written when the match opens (so a file always
carries `match_setup`), again when the app closes with a match in progress,
and a last time when the player saves. The tags are chosen on the save
screen, so a match saved by the app closing has both tags at 0 (not set).

### Practice: one lap for each block (lap message)

A practice is the same tennis activity with free counters instead of a
score. It has no point log and none of the match session fields (ids 0 to 4
and 7); it writes `steps`, `distance`, `set_steps` and `set_distance` like a
match, where the "set" of the two lap fields is the block.

* The watch closes a lap when a block is closed, so lap `n` covers block
  `n`. Saving closes the lap of the block that was open.
* `block_hits` and `block_misses`: the hits and misses counted in the block.
  The success rate is not stored: it is `hits / (hits + misses)`.
* A block with no entries cannot be closed on the watch, so only the last
  lap can have 0 and 0. It is the time after the last closed block and is
  not a block.
* A closed block is final: undo on the watch only reaches the entries of
  the open block, so the values of a closed lap never change.

A practice file carries only the developer fields of a practice: `steps`,
`distance`, `set_steps`, `set_distance`, `block_hits` and `block_misses`. A
match file carries none of the two block fields. What the converter makes
of a practice is in [A practice](#a-practice).

### Checked on the simulator

Scripted matches were played on the simulator (fr55) by a test build that
drives the real controller, saved, and converted with `tennis-export`. The
rows of `points.csv` were compared with the script entry by entry.

| Match | Entries | Result |
|---|---|---|
| One file: faults, double faults, aces, a tie break, an undo | 162 | Every row equal, all integrity checks true, score `7-6(7-5) 0-6 6-1` |
| Closed and resumed twice, three files | 166 | Every row equal, all integrity checks true, score `6-7(6-8) 5-4`; one entry missing from the first file came back with the second |
| Long match | 303 | Every row equal, all integrity checks true, score `7-6(7-0) 6-7(1-7) 7-5` equal to `final_score` |

A first run of the long match reopened the finished match and finished it
again within a second. Its file had 302 of the 303 entries: the last one
was missing and the converter said so (`missing_sequences` 303,
`statistics_match` false). This is the second corner listed in
[How the watch writes the log](#how-the-watch-writes-the-log).

An ace by the receiver is refused by the watch, so such a step of a script
is not an entry.

### Still to be confirmed on the watch

The summary fields ran on the simulator only. The watch side must check
each point on a real watch and this document must be corrected where
reality differs.

1. **Everything, on a real watch.** All twelve fields are written and were
   read back from simulator files. No file of a real watch was read yet.
2. **Record fields under Smart Recording.** The simulator writes a record
   every second. A real watch set to Smart Recording may write records
   less often, and how often cannot be tested on the simulator. Three
   entries per record cover up to three entries between two records. It
   must be measured on a watch: mark points quickly, save, and check that
   `missing_sequences` is empty.
3. **The last entries before saving.** Settled on the simulator: saving
   writes no record, a timer start or stop does. The app sets the field
   before each start and stop, so the last entry reaches the file. The
   corners that remain are listed in
   [How the watch writes the log](#how-the-watch-writes-the-log).
4. **Array fields.** Confirmed on the simulator for the record
   (`point_log`, 9 values), the session (`statistics`, 30 values, and the
   `final_score` text) and the lap (`set_score`, 4 values).
5. **Size limits.** A message may hold at most 256 bytes of developer data.
   The session uses about 110 and a record 36, by design. Both were
   confirmed with simulator files.
6. **Number of fields.** A match file declares ten fields and a practice
   file six, against a working limit of twelve. The real limit of each
   target watch must be checked.
7. **Garmin Connect display.** Array fields and packed words are not meant
   to be shown in Garmin Connect, so the app declares no label for them
   (`match_setup`, `final_score`, `statistics`, `set_score` are absent from
   `resources/fit/fitcontributions.xml`). How Connect treats a field
   without a label is unknown.
8. **Undo.** Confirmed on the simulator: the watch lowers the newest
   sequence number after an undo and reuses the numbers, and reader rule 2
   gave the log as played.
9. **Laps.** That the watch can close one lap for each set, and that steps
   and distance per set are available on every target watch.
10. **Field names.** The reader matches fields by name only. It does not
    check the application id of the developer data.
11. **The point log after a resume.** Confirmed on the simulator with a
    match saved in three files: the sequence numbers and the match clock
    went on, and the first record of each later file repeated the newest
    three entries.
12. **The summary after a resume.** Confirmed on the simulator: `log_size`,
    `final_score` and `statistics` of the last file covered the whole
    match, and `steps` and `distance` of each file counted from the start
    of that file only.
13. **The lap that closes a set.** The converter compares the score of a
    set with the `set_score` of the last lap of that set. It assumes the
    lap closed when the set ended carries the final score of the set.
14. **Lap times.** Placing laps needs the native `start_time` and
    `total_timer_time` of every lap. Simulator files carry both. It also
    assumes that a lap lasts longer than twice the time between two
    records. Simulator files had a record only every ten seconds or so,
    which is fine for a real set and too coarse for a set of a few
    seconds.

## Part 2: what the converter produces

```bash
uv run tennis-export activity.fit --out some-directory
uv run tennis-export first-half.fit second-half.fit --out some-directory
```

The command takes one file, or every file of one match (see
[Several files of one match](#several-files-of-one-match)). For a match it
writes one `points.csv`, one `match.json` and at most one `heatmap.png`.
For a practice it writes one `blocks.csv` and one `practice.json` instead
(see [A practice](#a-practice)).

Without `--out` the files go to a directory named after the file, next to
it (`activity-export`). With several files it is named after the one that
was recorded first. The command prints the path of every file it wrote.
It exits with status 2 and a one line message when a file cannot be read,
is not a FIT file, carries a format version or match format it does not
know, or when the files given are not parts of one match. Nothing is
written in that case.

The converter rebuilds the point log, then replays it with a Python port of
the watch scoring rules (formats, tie breaks, no advantage, serve
rotation). Scores and statistics in the output come from that replay, not
from the summary fields of the watch. The summary fields are only used to
cross check (see `integrity`).

A FIT file that was not recorded by this app still converts when it is
given alone: `match.json` then holds the activity data only and
`points.csv` holds only its header line.

### Several files of one match

A match that was closed and resumed is saved as two activity files (more
when it was resumed more than once). Give all of them to get one export.

* **Order.** The files are put in order by the start time of their
  session. The order on the command line does not matter. A file without a
  start time cannot be ordered and is refused.
* **Point log.** The records of all files are read one after the other and
  the log is rebuilt by sequence number with the usual rules, so entries
  repeated at the start of a later file count once.
* **Track and heart rate.** The positions and the heart rate readings of
  all files are used, in recording order.
* **Totals.** Elapsed time, timer time, calories, steps and distance are
  added up. The time between two files is not counted. A total that only
  some of the files carry is `null`: a partial sum is never shown as the
  total.
* **Summary.** The start time comes from the first file. Everything else
  that describes the whole match (setup, `log_size`, `final_score`,
  `statistics`) comes from the last file.
* **Per file details.** `source_files` in `match.json` lists each file
  with its own start time and duration.

The watch writes no match identifier today, so "the same match" is decided
from what the files do carry. Files are refused when any of these is true:

1. A file has no `match_setup` (it is not a match of this app).
2. Two files have a different `match_setup` word. The two tags are left out
   of this comparison: a part saved when the app closed has none.
3. A file starts before the file ahead of it ends.
4. The files ahead of a file hold point log entries, and the first
   `point_log` of that file repeats none of them unchanged. A resumed match
   goes on writing the newest three entries, so it always repeats some. A
   new match starts again at sequence number 1 with an entry of its own.

Two limits of these rules, stated plainly. A later file with no
`point_log` at all (resumed and saved at once) is accepted on rules 1 to 3
alone. A match resumed after exactly one entry, where that entry is undone
and marked again before the first record, is refused although it is the
same match; each file can still be converted alone.

### Laps and sets

Which lap belongs to which set is taken from the point log, not from the
position of the lap in the file:

1. The end of each closed set is the time of the first record that carried
   the entry that closed it, as that entry is in the final log. An entry
   that was undone has no time, and one marked again gets the later time.
2. Each lap is placed at the middle of the time it recorded: its
   `start_time` plus half its `total_timer_time`. Laps that lasted no time
   are ignored.
3. A lap belongs to the first set that ended at or after that moment. A lap
   after the last closed set belongs to the set that was still open and is
   not reported.

So a set that was undone and played again, or one split by a resume, has
two laps and still counts as one set. Its `steps` and `distance_m` are the
sums over its laps, and `laps` says how many there were.

The export never guesses. When any lap lacks its start or timer time, or
the end of any set has no time, no lap is placed: `steps`, `distance_m`
and `laps` are `null` for every set. A set with no lap, or with a lap that
lacks the value, has `null` for that value.

### `points.csv`

One row for each replayed entry of the point log, in the order played. The
first line names the columns. Empty cells mean "does not apply" or "not
known"; a cell is never filled with 0 to stand for a missing value.

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
  "source": "activity.fit",            file name that was converted (the first recorded one)
  "source_files": [ ... ],              every file that was converted, in recording order
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

Each object of `source_files`: `file` (file name), `start_time` (text or
null, ISO 8601 in UTC) and `elapsed_seconds` (number or null) of that file
alone. With one file the list has one object.

`activity` (with several files: the first start time and the totals over
all files, see [Several files of one match](#several-files-of-one-match)):

| Key | Type | Meaning |
|-----|------|---------|
| `start_time` | text or null | Start of the activity, ISO 8601 in UTC |
| `sport` | text or null | Sport of the session, `tennis` for this app |
| `elapsed_seconds` | number or null | Time from start to save, without the time between two files |
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
match clock of the log), `steps` and `distance_m` (added up over the laps
of the set, null when not known) and `laps` (how many laps the set has,
null when the laps could not be placed). See
[Laps and sets](#laps-and-sets).

Each object of `games`: `set`, `game` (number inside the set), `server`,
`winner`, `tie_break` (true or false) and `duration_seconds`.

Durations come from the match clock stored with each entry: a game or set
lasts from the entry that closed the one before it (or from zero) to the
entry that closed it.

`statistics` has one object for `me` and one for `opponent`, each with the
fifteen counts named in Part 1 plus these derived values:

| Key | Meaning |
|-----|---------|
| `first_serve_percent` | First serves in, as a whole percent of service points. `null` with no service points |
| `second_serve_points` | Service points played on a second serve |
| `return_games_played` | Service games of the other player |
| `return_games_won` | Breaks of serve |
| `break_points_faced` | Break point chances of the other player |
| `break_points_saved` | Those the other player did not win |

and two values for the match as a whole:

| Key | Meaning |
|-----|---------|
| `average_seconds_between_points` | Time from the first point to the last, divided by the number of points minus one, one decimal. `null` with fewer than two points |
| `average_deciding_heart_rate` | Mean heart rate on break and set points that carried a reading, or null |

A ratio or an average with nothing to divide is `null`, never 0: a first
serve percent of 0 means every first serve was a fault, and `null` means the
player did not serve. The watch screen shows 0 in both cases; the export
does not. The same rule holds for the CSV, where the value would be an
empty cell (`points.csv` has no ratio column today).

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
| `set_scores_match` | Whether the `set_score` of the last lap of each closed set equals the replayed set, null without the field or when the laps could not be placed |

`watch_summary` holds what the watch stored, untouched, and does not depend
on the point log:

| Key | Meaning |
|-----|---------|
| `final_score` | The text of the `final_score` field, null without it |
| `statistics` | `me` and `opponent`, each with the fifteen counts of the `statistics` field by name; null when the field is missing or does not hold thirty values |
| `set_scores` | One item for each lap, in file order: `games` and `tie_break_points` of its `set_score`, or null for a lap without the field |

### What a file without a point log gives

A match file with no `point_log` (a later part of a resumed match that was
saved at once, converted alone) has an empty
`points.csv` and a `match` section replayed from nothing: `finished` false,
`score.text` `0-0`, no sets, every statistic zero. `match.config` and
`match.tags` are right, because they come from `match_setup`. The result of
the match is then only in `watch_summary`. In `integrity`,
`statistics_match` is false (stored counts against an empty replay) and
`set_scores_match` is null (no replayed set to compare).

`heat_map`: `file` (`heatmap.png`), `method` (`principal_axis`),
`approximate` (always true), `track_points` (positions in the file),
`points_drawn` (positions that fall inside the picture) and
`rotation_degrees` (direction taken as the court length, counted
counterclockwise from east, from 0 to 180).

### A practice

A file is a practice when it has no `match_setup` and at least one lap
carries `block_hits`. The command then writes `blocks.csv` and
`practice.json`, and no `points.csv` or `match.json`. A practice is one
file: several practice files in one command are refused, like any files
that are not parts of one match.

Which laps are blocks:

* Only the last `num_laps` laps of the session are read, so laps left in
  the file by something else are ignored.
* A last lap with 0 hits and 0 misses is dropped: it is the time after the
  last closed block (see
  [Practice: one lap for each block](#practice-one-lap-for-each-block-lap-message)).

`blocks.csv` has one row for each block and a last row named `total`:

| Column | Meaning |
|--------|---------|
| `block` | Number of the block, from 1, or `total` |
| `hits`, `misses` | The two counts of the block |
| `shots` | Hits plus misses |
| `success_percent` | Hits out of shots, rounded half up to a whole number; empty when there were no shots |
| `duration_seconds` | Timer time of the lap; empty on the total row |
| `steps`, `distance_m` | `set_steps` and `set_distance` of the lap; empty on the total row and when the lap lacks the field |

`practice.json`:

```
{
  "format_version": 1,
  "source": "activity.fit",
  "source_files": [ ... ],
  "activity": { ... },                  same section as in match.json
  "practice": {
    "blocks": [ { "block": 1, "hits": 8, "misses": 2, "shots": 10,
                  "success_percent": 80, "duration_seconds": 312.4,
                  "steps": 140, "distance_m": 96 }, ... ],
    "totals": { "blocks": 3, "hits": 20, "misses": 9, "shots": 29,
                "success_percent": 69 }
  },
  "heat_map": { ... } or null           null today: a practice records no GPS
}
```

Unknown values are `null`.

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
