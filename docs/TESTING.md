# Testing strategy

Connect IQ has no code coverage tooling and no UI automation on the watch, so
the strategy is: automated tests for everything testable, a mechanical device
API audit, and a manual pass on a real watch for hardware behavior.

| Layer | What | Runs where | Gate |
|---|---|---|---|
| Unit tests | Run No Evil suite (`source/tests/`) on the simulator | `make test` | Local before every commit; best effort on CI |
| Resources check | XML validity, string catalogs in sync, generated string table up to date | `make resources-check` | `make check` and CI |
| Device API audit | Every Toybox symbol used against the API database of every target device | `make audit` | `make check` and CI |
| Compile matrix | Type check level 2 for one device per screen shape; all 80 devices when packaging | `make build-shapes`, `make package` | `make check` and CI |
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

The engine tests reach every function and both outcomes of every condition
in `source/model/` and `source/engine/`. This was measured once with a
throwaway probe over a copy of the sources, since the SDK has no coverage
report; nothing enforces it, so keep it true when the engine changes.

## What is not automated

| Not automatable | Reason | Covered by |
|---|---|---|
| Drawing that needs a `Dc` (layout, fonts) | No graphics context in unit tests | Looking at the simulator on fr55, venu2 and venusq2 |
| Touch against button input | Simulator input differs from a real digitizer | Watch pass |
| Vibration, tones and backlight | Hardware | Watch pass |

## Watch pass (before each release)

Sideload: `make build DEVICE=fr55`, then copy `bin/Tennis-fr55.prg` to
`GARMIN/APPS/` over USB.

* [ ] The app opens on the home screen: frame ring, brand arc, app name and
      MENU pill, nothing clipped.
* [ ] START opens the menu with Start match, Practice, Settings and About.
* [ ] Each of the first three rows shows the coming soon message and returns
      to the menu by itself.
* [ ] About shows the version text.
* [ ] BACK leaves the menu and then the app.

This list grows with each milestone.
