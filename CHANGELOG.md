# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

Nothing is released or published yet. This section lists what milestones M0
to M7 of [docs/PLAN.md](docs/PLAN.md) delivered; it becomes the first
version when M8 (release) is done.

### Added

* **Project foundation** (M0): Connect IQ watch app for 80 Garmin watch
  models, the shared theme with colors that survive the 64 color displays,
  texts in six languages (English, Portuguese, Spanish, French, German and
  Italian), the launcher icon, the quality gates of `make check` and CI.
* **Scoring engine** (M1): five match formats (best of 3 sets, 2 sets plus
  a 10 point match tie break, 1 set, pro set to 8 games, tie break only),
  with or without advantage, serve rotation, serve side, change of ends,
  game, break, set and match point flags, statistics and undo. The point
  log is the only source of the score.
* **Match setup, screen and controls** (M2): setup that remembers the last
  choices, live score with the match clock, serve ball and mini court,
  scoring with the keys or by touch, a notice and a vibration at each
  change of ends, the match menu (pause, resume, fix the score, end) and
  the final score screen.
* **Detailed mode** (M3): how each point ended (winner, ace, error in the
  net, error out), serve faults and double faults.
* **Activity recording** (M4): a Tennis activity with heart rate, calories,
  steps, distance, optional GPS and one lap per set; save or discard at the
  end; a match interrupted when the app closes can be resumed.
* **Match report** (M5): statistics pages on the watch for both players
  (score, serve, point endings, pressure, time, body), summary fields in
  Garmin Connect and match tags (surface and kind of match) when saving.
* **Export** (M6): the `tennis-export` converter, which reads the activity
  file and writes `match.json`, `points.csv` when the file carries a point
  log and, with a GPS track, an approximate court heat map. It joins the
  activity files of a resumed match into one export. The data format is
  documented in [docs/DATA_FORMAT.md](docs/DATA_FORMAT.md). The watch does
  not write the point log to the activity file yet, so today an export has
  the summary and the laps but no point by point data.
* **Practice mode** (M7): hit and miss counters by block, one lap per block
  with its counters, a summary on the watch, save or discard, and the
  export of a practice as `blocks.csv` and `practice.json`.
* **Documentation**: user guide, store listing draft in six languages,
  recording notes, testing strategy and quality bar.
* `make build-all`: compiles the app for every device in `manifest.xml` and
  reports each device on its own.

### Changed

* The string tables are JSON resources, one for each language, and only the
  table of the watch language is loaded (about 14 kB less memory on the
  Forerunner 55).
* A match and a practice each write only their own developer fields to the
  activity file.
