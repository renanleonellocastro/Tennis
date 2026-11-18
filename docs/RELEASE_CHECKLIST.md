# Release checklist for 1.0.0

What only the owner can do before Tennis 1.0.0 is published. Everything
else is done and checked on the simulator; the results are in
[TESTING.md](TESTING.md) and [RECORDING.md](RECORDING.md).

## 1. Repository secrets

Add these in GitHub, under Settings, Secrets and variables, Actions. Until
they exist, CI skips the watch build and the release workflow attaches
nothing.

* [ ] `GARMIN_USERNAME` and `GARMIN_PASSWORD`: the Garmin login that
      downloads the SDK and the device files.
* [ ] `CIQ_SIGNING_KEY_B64`: the developer key in base64
      (`base64 -i developer_key.der`). Every later version must be signed
      with this same key, or the store treats it as another app.

## 2. Test on a real watch

Sideload with `make build DEVICE=<your watch> BUILD_OPTIONS=-r` and copy
`bin/Tennis-<your watch>.prg` to `GARMIN/APPS/` over USB. `-r` makes the
release build, the one the store package holds. The full list is
the watch pass in [TESTING.md](TESTING.md). These are the points that the
simulator could not show:

* [ ] **Buttons**: UP and DOWN score, START logs a fault, BACK undoes.
      Holding UP opens the match menu and does not also score a point.
* [ ] **Touch** (touch watch): a tap on the left or right half scores, a
      swipe up on the final score opens the statistics, the **MENU**,
      **FAULT** and **NEXT** buttons work on a watch without UP and DOWN.
* [ ] **Vibration**: at each change of ends, and when a practice block
      closes.
* [ ] **Heart rate**: shown next to the clock during the match and on the
      **BODY** page of the statistics, with calories.
* [ ] **Steps and distance**: the **Steps** field of a saved match is close
      to the change of the daily step count.
* [ ] **GPS**: with the switch on, the saved activity has a track, and
      `uv run tennis-export` draws `heatmap.png` from its file.
* [ ] **Smart Recording**: set the watch to Smart Recording, play a short
      detailed match, save it, export the `.fit` file from Garmin Connect
      and run `uv run tennis-export`. `points.csv` must have every point
      you logged, in order.
* [ ] **Quick save**: finish a match and save it right after the last
      point; then reopen a finished match with BACK, log another point and
      save at once. Both exports must have their last point. The goodbye
      message stays up to a second and a half longer while the watch
      writes; that is expected.
* [ ] **Resume**: leave the app in the middle of a match, open it again,
      choose **Resume**, finish and save. Give both `.fit` files to
      `tennis-export`: one result with all the points.
* [ ] **Garmin Connect view**: the activity is Tennis, with one lap per
      set, heart rate, calories, and **Steps** and **Distance** in the
      summary and in each lap. A practice shows one lap per block with
      **Hits** and **Misses**. Note the exact name of the export action for
      the user guide.
* [ ] **Text**: nothing cut on your watch in your language.

Correct [USER_GUIDE.md](USER_GUIDE.md) and
[STORE_LISTING.md](STORE_LISTING.md) wherever the watch behaves
differently.

## 3. Store decisions

* [ ] **Name**: the listing proposes "Tennis: Score and Match Stats". The
      watch itself shows "Tennis". Check the length limit on the dashboard.
* [ ] **Category**: the listing proposes Health & Fitness, as Stretches.
* [ ] **Support contact**: the email shown in the store, and whether the
      listing links to the GitHub repository.
* [ ] **Translations**: the app texts and the store texts in Portuguese,
      Spanish, French, German and Italian were not reviewed by native
      speakers.
* [ ] **Hero image**: optional. None was made; the screenshots are in
      `docs/images/screenshots/`.

## 4. Tag and publish

* [ ] Set the date of the 1.0.0 entry in `CHANGELOG.md`.
* [ ] Run `make check`, `make test`, `make build-all` and `make package`.
* [ ] `git tag v1.0.0 && git push --tags`. With the secrets in place the
      release workflow builds every device and attaches `Tennis.iq` to the
      GitHub release. Without them, attach `dist/Tennis.iq` from
      `make package` by hand.
* [ ] Upload `Tennis.iq` on the
      [Connect IQ developer dashboard](https://apps.garmin.com/developer/dashboard)
      with the texts of [STORE_LISTING.md](STORE_LISTING.md) and the
      screenshots.
