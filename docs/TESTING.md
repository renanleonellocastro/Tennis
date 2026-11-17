# Testing strategy

Connect IQ has no code coverage tooling and no UI automation on the watch, so
the strategy is: automated tests for everything testable, a mechanical device
API audit, and a manual pass on a real watch for hardware behavior.

| Layer | What | Runs where | Gate |
|---|---|---|---|
| Unit tests | Run No Evil suite (`source/tests/`) on the simulator | `make test` | Local before every commit; best effort on CI |
| Resources check | XML validity, string catalogs in sync, generated string tables up to date | `make resources-check` | `make check` and CI |
| Device API audit | Every Toybox symbol used against the API database of every target device | `make audit` | `make check` and CI |
| Compile matrix | Type check level 2 for one device per screen shape; all 80 devices when packaging | `make build-shapes`, `make package` | `make check` and CI |
| All devices build | Type check level 2 for each of the 80 devices on its own, one result per device (about a minute and a half) | `make build-all` | Manual, before each release |
| Tool tests | The Python tools at 100% line and branch coverage | `make test-tools` | `make check` and CI |
| Watch pass | Hardware behavior that cannot be simulated | Real watch | Manual, before each release |

## Running the automated suite

```bash
make sim                 # start the simulator once
make test                # build with --unit-test and run on fr55
make test DEVICE=venu2   # same suite on a touch AMOLED device
```

The result line printed by the simulator decides the outcome: `make test`
passes only when it reads `PASSED` and no test failed or errored.

## What the suite covers today

* `ThemeTest`: every palette color keeps each channel a multiple of `0x55`,
  so it survives the 64 color MIP palette; the text splitting helpers.
* `I18nTest`: all six languages have every string key with a value.
* `MenuKitTest`: the main menu rows and the action each one maps to.
* `PointLogTest`: packing of a point into one number (result, ending, heart
  rate, time, with clamping) and the log operations.
* `MatchScoringTest`: points, games, sets and the end of the match in every
  format, with and without advantage, including both kinds of tie break.
* `MatchServeTest`: server rotation, serve side, second serve, ends and when
  a change of ends is due, inside and outside a tie break.
* `MatchPressureTest`: game, break, set and match point flags for both
  players and the deciding point.
* `MatchEngineTest`: faults and double faults, ace validity, a finished match
  rejecting entries, undo at every boundary and resume from a stored log.
* `MatchStatisticsTest`: every statistic for both players, durations and
  averages.
* `MatchSetupTest`: the setup choices, their cycling, labels, stored form
  and the match configuration they produce.
* `MatchClockTest`: the match clock with pause and resume, and how long a
  notice stays visible.
* `MatchInputTest`: which action each key and each tap maps to, and which
  watches can score with keys, with touch or not at all.
* `MatchLayoutTest`: rows and columns do not overlap on the three screen
  shapes, the serve ball stays inside a round screen, the font choice, the
  mini court and the touch control band.
* `MatchPresenterTest`: every text of the match and final screens.
* `MatchControllerTest`: scoring in simple and detailed mode, faults, undo,
  pause, notices, change of ends, ending and reopening a match.
* `ScoreFixerTest`: undo of a whole game and awarding a game.
* `EndingChoicesTest`: the point ending list for each winner and server.
* `MatchFlowTest`: the rows of the match, final and resume menus and the
  methods they run, the setup menu with and without the GPS row, the save
  menu with its tags, saving with tags, the report pages of a match and the
  keys that turn them, the discard confirmation, and a short real activity
  recorded and discarded.
* `MatchTagsTest`: the surface and kind choices, their codes, texts in
  every language and how they are remembered.
* `MatchSummaryTest`: the setup word with its tags, the score of a closed
  and of an open set, the score text and its cut to the room of the field.
* `ReportTest`: every page of the report for both players (score, serve,
  point endings, pressure, time, body), the missing value mark, the pager,
  the layout on the three screen shapes and the length of the row labels in
  every language.
* `RecordingTest`: steps and distance counted from the first reading, over
  a pause, a missing reading and midnight, per lap; the recorder starting,
  pausing, opening laps with the score of their set, writing the summary
  fields, saving and discarding; the field ids and which fields a match and a
  practice each create; the real
  sensors, GPS and storage of the watch the suite runs on.
* `MatchStoreTest`: the stored match, one value per set, corrections that
  go back over a set, loading and going on, clearing, unknown headers.
* `MatchRecordingTest`: the controller recording a match: heart rate in the
  entries, pause, laps per set, the summary written when the match opens,
  when it is saved with tags and when the app closes, discard, and a
  resumed match with its score, clock and laps.
* `PracticeLogTest`: hits, misses, undo inside the open block only, closing
  blocks, empty blocks that do not close, totals.
* `PracticePresenterTest`: success rate rounding, the texts of the practice
  screen and of the summary rows, and the summary pages.
* `PracticeControllerTest`: the practice actions behind the match keys and
  taps, counting, one lap per block with its hits and misses, pause, end,
  reopen, save, discard, the app closing, and the practice recorder.
* `PracticeFlowTest`: the rows of the practice and save menus and the
  methods they run, the confirmations, the summary paging keys, every
  practice text in every language, and a short real activity recorded and
  discarded.

The practice suites run with the rest in `make test` (388 tests on the
Forerunner 55 at the end of M7).

The recording tests use fakes for the session, sensors, GPS and storage
(`source/tests/RecordingFakes.mc`), so they need no sensor data.

The engine tests reach every function and both outcomes of every condition
in `source/model/` and `source/engine/`. This was measured once with a
throwaway probe over a copy of the sources, since the SDK has no coverage
report; nothing enforces it, so keep it true when the engine changes.

## What is not automated

| Not automatable | Reason | Covered by |
|---|---|---|
| Drawing that needs a `Dc` (layout, fonts) | No graphics context in unit tests | Looking at the simulator on fr55, venu2 and venusq2 |
| Functions that push, switch or pop views (`MatchFlow`, the delegates) | A view stack exists only in a running app | Watch pass; they hold no decision of their own |
| Touch against button input | Simulator input differs from a real digitizer | Watch pass |
| Vibration, tones and backlight | Hardware | Watch pass |
| Real heart rate, calories, steps and GPS in the saved activity | The simulator gives no sensor data without its menus | Watch pass |
| The activity file itself (sport, laps, fields) | The suite cannot read files | A scripted match on the simulator, see below; watch pass |

### Checking the activity file by hand

A saved match appears as a FIT file in the simulator folder
`$TMPDIR/com.garmin.connectiq/GARMIN/Activities/`. Any FIT reader shows the
sport (tennis), one lap per set and the developer fields of
`docs/RECORDING.md`. This was done once for M4 with a throwaway copy of the
app that played a scripted match by itself, and again for M5, when the
saved file was also converted with `uv run tennis-export` to check the
summary fields; the results are in `docs/RECORDING.md`. A session
discarded by the test suite can leave empty or stale laps in the next file
the simulator saves; that is a simulator effect, so save the file to check
in a run that follows another run of the app, not the test suite.

## Watch pass (before each release)

First run `make build-all`: every device in `manifest.xml` must compile.

Sideload: `make build DEVICE=fr55`, then copy `bin/Tennis-fr55.prg` to
`GARMIN/APPS/` over USB.

* [ ] The app opens on the home screen: frame ring, brand arc, app name and
      MENU pill, nothing clipped.
* [ ] START opens the menu with Start match, Practice, Settings and About.
* [ ] Settings shows the coming soon message and returns to the menu by
      itself.
* [ ] Practice opens the practice screen: block 1, 0 and 0, clock running.
      UP adds a hit, DOWN a miss, BACK takes the last entry back, START
      closes the block with a vibration and opens block 2. An empty block
      does not close.
* [ ] Practice on a touch watch: left half is a hit, right half a miss,
      the two pills at the bottom open the menu and close the block.
* [ ] Practice menu: pause stops the clock and the counters, resume starts
      them again; End asks first, then shows the summary with one row per
      block, the total and the time. More than four blocks turn pages.
* [ ] Practice summary: START offers Save and Discard, BACK goes on with
      the practice. A saved practice shows in Garmin Connect with one lap
      per block and its hits and misses.
* [ ] Start match opens the setup with the last choices and the start row
      selected; each row cycles its value.
* [ ] Five button watch: UP scores for me, DOWN for the opponent, START logs
      a serve fault, BACK undoes, holding UP opens the match menu and does
      not also score a point.
* [ ] Touch watch: a tap on the left half scores for me, on the right half
      for the opponent; the MENU and FAULT pills work on a two button watch.
* [ ] Two button watch with touch turned off shows the message asking to
      turn touch on.
* [ ] Detailed mode asks how the point ended; BACK on that list cancels the
      point.
* [ ] A change of ends vibrates and shows its notice.
* [ ] Match menu: pause and resume stop and restart the clock, fix the score
      undoes or awards a game, end match asks first.
* [ ] The final score screen shows after the last point; BACK reopens the
      match, START returns to the menu.
* [ ] The heart rate shows after the red dot next to the clock, and the row
      holds only the clock while there is no reading.
* [ ] On the final score screen START offers Save, Statistics and Discard;
      Discard asks first; Save and Discard end on a short message and
      return to the menu.
* [ ] Statistics, DOWN or a swipe up on the final score screen opens the
      report; UP and DOWN or a swipe turn its pages, BACK returns to the
      final score. Every page fits the screen, with heart rate and calories
      on the last one.
* [ ] Save asks for the surface and the kind of match, opens on the Save
      row, and the next match offers the same choices again.
* [ ] A saved match is in Garmin Connect as Tennis with one lap per set,
      heart rate, calories, and the Steps and Distance fields in the summary
      and in each lap. Compare the steps with the daily step count before
      and after.
* [ ] With the GPS switch on, the saved activity has a track; a watch
      without GPS shows no GPS row.
* [ ] Leaving the app in the middle of a match saves an activity; opening
      the app again offers Resume or Discard; Resume brings back the score
      and the clock, and the rest is saved as a second activity.
* [ ] About shows the version text.
* [ ] BACK leaves the menu and then the app.

This list grows with each milestone.
