# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

* The bottom row of the match screen sits three percent of the height
  higher on a round screen with no touch controls, and its parts stand
  closer together on every watch. On the
  Forerunner 55 a clock over one hour next to a heart rate of three digits
  came within a pixel or two of the frame ring.
* Shorter texts for menu rows that touched the edge of the Forerunner 55
  screen on the row under the chosen one: Portuguese ("Quem saca",
  "Voltar game", "Game p/ mim", "Game p/ adv."), Spanish ("Anular juego"),
  French ("Lancer match", "1er service"), German ("Beenden", "Netzfehler",
  "Ausfehler") and Italian ("No vantaggi", "Dettaglio", "Fine partita").
* The longest game label of the report reads "Longest" in English and
  "Maior" in Portuguese: on the Venu Sq 2 the longer labels touched a
  game time of ten minutes or more on the same line.
* The format rules, the empty point log field and the report tables take
  about 0.4 kB less memory, so the debug build stays under 108 kB on the
  Forerunner 55 with the paced point log (`docs/TESTING.md`, Memory).
* Spanish: the change of ends notice reads "Cambio lado", so "Juego.
  Cambio lado" fits the banner row of the Forerunner 55.

### Fixed

* A game given by "Fix the score" logs four points or more at once, but
  the activity file takes three entries per record: the oldest of them
  never reached the file, and the converter stopped the replay there. The
  point log field is now paced, so those entries reach the file three at
  a time.
* Converter: when the app closed within the second a set ended, the short
  lap that followed was taken for the lap that closed the set and
  `set_scores_match` came out false for a file that was right. A lap with
  no game is no longer compared.

## [1.0.0] - not released yet

The first version. It is built and checked on the simulator, but it has no
tag, no GitHub release and no store entry yet: the date goes here on the day
it is tagged. What is left is in
[docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md).

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
  documented in [docs/DATA_FORMAT.md](docs/DATA_FORMAT.md).
* **Point log in the activity file** (M6): the watch writes every point and
  fault into the activity file, so an export has the match point by point.
  Proven with files recorded by the simulator.
* **Practice mode** (M7): hit and miss counters by block, one lap per block
  with its counters, a summary on the watch, save or discard, and the
  export of a practice as `blocks.csv` and `practice.json`.
* **Documentation**: user guide, store listing in six languages, release
  checklist, recording notes, testing strategy and quality bar.
* **Store assets** (M8): simulator screenshots of the real screens under
  `docs/images/screenshots/`.
* `make build-all`: compiles the app for every device in `manifest.xml` and
  reports each device on its own.
* `make build BUILD_OPTIONS=-r`: the release build for a watch plugged in
  by cable. On the simulator it takes about 15 kB less memory than the
  default debug build (`docs/TESTING.md`, Memory).

### Changed

* The string tables are JSON resources, one for each language, and only the
  table of the watch language is loaded (about 14 kB less memory on the
  Forerunner 55).
* A match and a practice each write only their own developer fields to the
  activity file.
* Every menu carries the app name as its title. The longer titles wrapped
  and were cut on the small round screens.
* Shorter texts for menu rows and report labels in the six languages, so
  none is cut on the Forerunner 55. The match tie break format reads
  "2 sets + tie break".
* Shorter report labels in German, Spanish, Italian and Portuguese (game
  times, key points heart rate, service games held, break points saved,
  first serve in): on the Venu Sq 2 the longer ones touched or ran into
  the number on the same line.
* On a screen that is not round, the labels, the touch buttons and the clock
  of the match and practice screens sit further apart, and the title of the
  practice summary sits below the brand arc.
* A message screen breaks its text one character earlier, so the about
  text takes two lines and stays inside the frame ring of a rectangular
  screen.
* The release workflow compiles every device on its own before packaging.

### Fixed

* A finished match that was reopened with BACK and finished again within
  about a second lost its last entry in the activity file. The watch now
  waits for the last record before it stops and saves.
