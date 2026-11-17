<div align="center">

# 🎾 Tennis

**A tennis match and practice tracker for Garmin watches.**

Keep the score on your wrist, log how every point ended, record heart rate
and calories, and finish with a full statistics report of your game.

[![License: MIT](https://img.shields.io/badge/License-MIT-ffaa00.svg)](LICENSE)
[![Connect IQ](https://img.shields.io/badge/Connect%20IQ-watch%20app-ff8800)](https://developer.garmin.com/connect-iq/)
[![Status](https://img.shields.io/badge/status-in%20development-ff5500)](#status)

</div>

## 🚧 Status

This project is in development. Nothing is released yet. Milestone M0
(foundation) is done: the app builds, opens on a home screen and shows a
menu whose entries are not built yet. The list below is the vision that
guides the first version and it may change while the plan is refined.

## ✨ Planned features

* 🎾 **Match and practice modes**: record a full match or a training session.
* 🔢 **Live score**: the current game score in large digits, with the set
  score in small digits above it.
* 🧭 **Serve guidance**: a subtle hint of who serves the next point and from
  which side of the court (deuce or ad).
* 🔄 **Court ends**: shows which end each player is on and when to change.
* 📝 **Point by point log**: mark how each point ended, such as winner, ace,
  double fault, ball in the net, ball out or opponent error.
* ❤️ **Activity recording**: heart rate, calories and time saved to
  Garmin Connect.
* 📊 **End of match report**: winners, errors, net balls, double faults,
  first serves missed, points won on serve and more, so you can follow your
  progress over time.

## 👨‍👩‍👧 Same family as Stretches

Tennis is built by the same developer as
[Stretches](https://github.com/renanleonellocastro/Stretches) and shares its
look and feel: black background, one warm accent color, large readable
numbers and simple button controls that work on every supported watch.

## 🗺 Plan

The agreed requirements, decisions and milestones live in
[docs/PLAN.md](docs/PLAN.md).

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

* `source/`: the app (entry point, `ui/`, `i18n/`, generated string table
  and `tests/`)
* `resources*/`: launcher icon and the strings of the six languages
* `scripts/`: string table and icon generators, resources check and device
  API audit
* `tools/`: function length checker, the `tennis_export` converter and
  their tests
* `docs/`: [plan](docs/PLAN.md), [quality bar](docs/QUALITY.md),
  [testing strategy](docs/TESTING.md) and [data format](docs/DATA_FORMAT.md)

## 📤 Export your data

The converter turns the FIT file of an activity into files you can open in
a spreadsheet or feed to your own scripts:

```bash
uv run tennis-export activity.fit --out my-match
```

It writes into the chosen directory:

* `points.csv`: one row for each point, with the score after it.
* `match.json`: configuration, final score, statistics of both players,
  duration of every set and game, tags, heart rate, steps and distance.
* `heatmap.png`: only when the activity has a GPS track. An approximate
  picture of where you moved on the court.

The watch app does not write the match data into the activity file yet, so
for now the converter is proven only against files built by its own tests.
The fields, the columns and the limits of the heat map are described in
[docs/DATA_FORMAT.md](docs/DATA_FORMAT.md).

## 🤝 Contributing

Ideas and feedback are welcome. Open an issue to suggest a statistic, a
scoring format or a device you would like to see supported. To change the
code, read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## 📄 License

[MIT](LICENSE). Free to use, modify and distribute.
