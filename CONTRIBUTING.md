# Contributing to Tennis

Thanks for your interest! This project welcomes people who are new to
Connect IQ. If anything in this guide does not work for you, open an issue:
fixing the developer experience is a contribution too.

## Getting set up

1. **Install the Connect IQ SDK** (pick one):
   * The [official SDK Manager](https://developer.garmin.com/connect-iq/sdk/), or
   * [`connect-iq-sdk-manager-cli`](https://github.com/lindell/connect-iq-sdk-manager-cli):

     ```bash
     connect-iq-sdk-manager agreement view   # read it and note the hash
     connect-iq-sdk-manager agreement accept --agreement-hash <HASH>
     connect-iq-sdk-manager login            # your Garmin account
     connect-iq-sdk-manager sdk set 9.2.0
     connect-iq-sdk-manager device download --include-fonts --manifest manifest.xml
     export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"
     ```

2. **Install [`uv`](https://docs.astral.sh/uv/)**. It runs the Python tools
   and installs their dependencies on first use.
3. **Create a signing key** (once): `make key`
4. **Build**: `make build` (defaults to `DEVICE=fr55`)
5. **Run the tests**: `make sim` (starts the simulator), then `make test`
6. **Try the app**: `make sim`, then `monkeydo bin/Tennis-fr55.prg fr55`

## Project layout

| Path | What lives there |
|---|---|
| `source/TennisApp.mc` | App entry point |
| `source/model/` | Match format, players, court sides and the packed point log |
| `source/engine/` | Scoring engine: state and statistics derived by replaying the point log (no UI code) |
| `source/match/` | Match screen decisions with no drawing: setup store, clock, input map, layout numbers, controller, texts, score fixes |
| `source/practice/` | Practice mode: counters by block, controller, texts, recorder over the match recorder, and its screens and menus (inside the `PracticeFlow` module) |
| `source/recording/` | The activity: session, laps, steps and distance fields, the stored match, and the small interfaces over the watch sensors, GPS and storage (see `docs/RECORDING.md`) |
| `source/ui/` | Views, delegates, menus and the theme (drawing and navigation only) |
| `source/i18n/` | Text lookup by language |
| `source/generated/` | Generated index of the string tables (do not edit) |
| `resources/texts/` | Generated string tables, one JSON resource for each language (do not edit) |
| `source/tests/` | Unit tests (`(:test)` functions, Run No Evil). New test files go inside a module, because the global scope holds at most 253 members |
| `resources*/` | Launcher icon and the strings of each language |
| `scripts/` | String table and icon generators, resources check, device API audit, all devices build |
| `tools/` | Function length checker and its tests |

## Changing text

1. Edit `resources/strings/strings.xml` and the same id in **every**
   `resources-<code>/strings/strings.xml` (por, spa, fre, deu, ita).
2. Run `make strings` to regenerate `source/generated/Strings.mc` and the
   tables in `resources/texts/`.
3. `make resources-check` confirms that nothing is missing or stale.

## Adding a new language

1. Create `resources-<code>/strings/strings.xml` (ISO 639-2 code, for example
   `resources-jpn`) with every id from `resources/strings/strings.xml`.
2. Add `<iq:language><code></iq:language>` to `manifest.xml`.
3. Add the code to `LANGUAGES` in `scripts/generate_strings.py`, then run
   `make strings`.

## Quality bar

All production code follows [docs/QUALITY.md](docs/QUALITY.md): function
bodies of at most 12 lines, all of SOLID and meaningful names. Run
`make check` before every commit (it needs the SDK, a signing key and `uv`),
plus `make sim` and `make test` for the simulator suite.

## Quality gates

Every PR must pass:

* XML validity, string catalogs in sync across languages and an up to date
  generated string table (`make resources-check`)
* Device API audit: every Toybox symbol used must exist on all target
  devices (`make audit`)
* A clean compile at type check level 2 with warnings on, for one device per
  screen shape (`make build-shapes`)
* Lint, type check and tests of the tools (`make lint-tools`,
  `make test-tools`)
* The strict function length gate (`make function-length-gate`)
* All unit tests green on the simulator (`make test`)

Before a release, and after any change to the device list in
`manifest.xml`, also run `make build-all`: it compiles the app for every
supported device and reports each one on its own. It takes about a minute
and a half, so it is not part of `make check`.

See [docs/TESTING.md](docs/TESTING.md) for the full strategy, including the
manual pass on a real watch before releases.

## Conventions

* **English everywhere**: code, comments, commits, PRs and docs.
* Text the user sees always comes from the string resources, never literals.
* Colors must survive the 64 color MIP palette (every channel a multiple of
  `0x55`); see `source/ui/Theme.mc`.
* Commit messages: short imperative subject, for example
  `Add tie break scoring`.

## Releasing (maintainers)

1. Update `VERSION` in `source/ui/MenuKit.mc`, move the Unreleased
   section of `CHANGELOG.md` under the new version and run `make build-all`.
2. Tag: `git tag v1.x.y && git push --tags`. CI attaches `Tennis.iq` to the
   GitHub release.
3. Upload the `.iq` to the
   [Connect IQ developer dashboard](https://apps.garmin.com/developer/dashboard).
