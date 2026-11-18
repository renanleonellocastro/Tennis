<div align="center">

# 🎾 Tennis

**A tennis match and practice tracker for Garmin watches.**

Keep the score on your wrist, log how every point ended, record heart rate
and calories, and finish with a full statistics report of your game.

[![License: MIT](https://img.shields.io/badge/License-MIT-ffaa00.svg)](LICENSE)
[![Connect IQ](https://img.shields.io/badge/Connect%20IQ-watch%20app-ff8800)](https://developer.garmin.com/connect-iq/)
[![Status](https://img.shields.io/badge/status-release%20candidate-ff5500)](#-status)

</div>

## 🚧 Status

Version 1.0.0 is built and ready for its release steps. It is not published
yet: no version tag, no GitHub release and no store entry exist.

* **Built and tested on the simulator**: everything in the feature list
  below, in six languages, compiled for the 80 watch models of
  `manifest.xml`.
* **Still to do, by the owner**: the test pass on a real watch, the store
  entry and the release itself. The steps are in
  [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md).
* **Not verified yet**: anything that needs a real watch, such as the real
  buttons and touch, the vibration, the heart rate, steps and GPS values,
  and how Garmin Connect shows the activity.

## ✨ Features of version 1

* 🎾 **Match and practice modes**: record a full singles match or a
  training session with hit and miss counters.
* 🏆 **Five match formats**: best of 3 sets, 2 sets plus a 10 point match
  tie break, 1 set, pro set to 8 games, or a tie break only, with a switch
  for no advantage scoring.
* 🔢 **Live score**: game points in large digits, set score above them,
  heart rate and match clock below.
* 🧭 **Serve guidance**: a ball next to the player who serves and a mini
  court with the side to serve from (deuce or ad) and the end each player
  is on.
* 🔄 **Change of ends**: a vibration and a notice when it is time.
* 📝 **Point by point log**: one press for who won the point (simple) or a
  second press for how it ended (detailed): winner, ace, error in the net
  or error out. Serve faults and double faults take one button.
* ↩️ **Undo and fix**: take back the last entry, or correct the score from
  the menu.
* ⏯ **Pause, end and resume**: a match interrupted when the app closes can
  be resumed.
* ❤️ **Activity recording**: a Tennis activity in Garmin Connect with heart
  rate, calories, steps, distance, optional GPS and one lap per set.
* 📊 **End of match report**: score, serve, point endings, pressure, time
  and body pages for both players on the watch. The same numbers are stored
  in the activity file for the export.
* 🏷 **Match tags**: surface (clay, hard, grass) and type (match or
  friendly), chosen when you save.
* 📤 **Open data**: every point stored in the activity file, with a free
  converter to CSV and JSON and an approximate court heat map.
* ⌚ **80 watch models** and 🌍 **6 languages** (English, Portuguese,
  Spanish, French, German, Italian), the same reach as Stretches.

## 📖 Documentation

* [User guide](docs/USER_GUIDE.md): how to record a match, the controls on
  each kind of watch, the report and the export.
* [Store listing](docs/STORE_LISTING.md): the Connect IQ store texts in the
  six languages, ready for the day the app is published.
* [Release checklist](docs/RELEASE_CHECKLIST.md): what is left for the
  owner before and during publishing.
* [Plan](docs/PLAN.md): the agreed requirements, decisions and milestones.

## 👨‍👩‍👧 Same family as Stretches

Tennis is built by the same developer as
[Stretches](https://github.com/renanleonellocastro/Stretches) and shares its
look and feel: black background, one warm accent color, large readable
numbers and simple button controls that work on every supported watch.

## 🛠 Getting started (developers)

You need the Connect IQ SDK, a signing key and
[`uv`](https://docs.astral.sh/uv/). The one time setup is described in
[CONTRIBUTING.md](CONTRIBUTING.md).

```bash
make build    # compile for the Forerunner 55 (DEVICE=venu2 picks another watch)
make sim      # start the simulator
make test     # run the unit tests on the simulator
make check    # run every local quality gate
```

Project layout:

* `source/`: the app (entry point, `model/`, `engine/`, `match/`,
  `recording/`, `ui/`, `i18n/`, generated string table and `tests/`)
* `resources*/`: launcher icon and the strings of the six languages
* `scripts/`: string table and icon generators, resources check and device
  API audit
* `tools/`: function length checker, the `tennis_export` converter and
  their tests
* `docs/`: [plan](docs/PLAN.md), [user guide](docs/USER_GUIDE.md),
  [store listing](docs/STORE_LISTING.md), [quality bar](docs/QUALITY.md),
  [testing strategy](docs/TESTING.md), [recording](docs/RECORDING.md) and
  [data format](docs/DATA_FORMAT.md)

## 📤 Export your data

The converter turns the FIT file of an activity into files you can open in
a spreadsheet or feed to your own scripts:

```bash
uv run tennis-export activity.fit --out my-match
```

A match that was closed and resumed is saved as more than one activity.
Give all its files, in any order, and they are joined into one export:

```bash
uv run tennis-export first-half.fit second-half.fit --out my-match
```

It writes into the chosen directory:

* `points.csv`: one row for each point, with the score after it.
* `match.json`: configuration, final score, statistics of both players,
  duration of every set and game, tags, heart rate, steps and distance.
* `heatmap.png`: only when the activity has a GPS track. An approximate
  picture of where you moved on the court.

A practice gives `blocks.csv` (one row for each block) and `practice.json`
instead.

The watch writes every point into the activity file. This was proven with
files recorded by the Connect IQ simulator, not yet with a file from a real
watch. The fields, the columns and the limits of the heat map are described
in [docs/DATA_FORMAT.md](docs/DATA_FORMAT.md).

## 🤝 Contributing

Ideas and feedback are welcome. Open an issue to suggest a statistic, a
scoring format or a device you would like to see supported. To change the
code, read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## 📄 License

[MIT](LICENSE). Free to use, modify and distribute.
