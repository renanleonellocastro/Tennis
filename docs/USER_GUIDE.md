# Tennis user guide

How to record a tennis match or a practice with the Tennis app on a Garmin
watch, and how to read the result afterwards.

The app is in development and is not published yet. This guide describes
version 1.0.0 as agreed in [PLAN.md](PLAN.md). The parts that are not built
or not yet tested on a real watch are marked **(planned)** and listed in
[To confirm before release](#to-confirm-before-release).

Names in **bold** are what the watch shows in English. The app follows the
language of the watch: English, Portuguese, Spanish, French, German or
Italian.

## Contents

* [The three kinds of watch](#the-three-kinds-of-watch)
* [Starting a match](#starting-a-match)
* [Match formats](#match-formats)
* [The match screen](#the-match-screen)
* [Logging a point](#logging-a-point)
* [Serve faults](#serve-faults)
* [Undo and fixing the score](#undo-and-fixing-the-score)
* [Pause and end](#pause-and-end)
* [Resuming an interrupted match](#resuming-an-interrupted-match)
* [The report](#the-report)
* [Exporting your data](#exporting-your-data)
* [GPS and the heat map](#gps-and-the-heat-map)
* [Practice mode](#practice-mode)
* [To confirm before release](#to-confirm-before-release)

## The three kinds of watch

The controls depend on the buttons of your watch.

| What you want | Five buttons | Five buttons and touch | Two buttons and touch |
|---|---|---|---|
| Point for me | UP | UP, or tap the left half | Tap the left half |
| Point for the opponent | DOWN | DOWN, or tap the right half | Tap the right half |
| Serve fault | START | START | Tap **FAULT** |
| Undo the last entry | BACK | BACK | BACK button or back swipe |
| Match menu | Hold UP | Hold UP | Tap **MENU** |

* **Five buttons** (for example the Forerunner 55): everything is done with
  the buttons. On round watches two short colored marks on the edge of the
  screen, next to UP and DOWN, remind you which button belongs to which
  player.
* **Five buttons and touch**: the buttons work the same way and a tap on the
  left or right half of the screen also scores the point.
* **Two buttons and touch** (watches with no UP and DOWN buttons, for
  example the Venu 2): you score by touch, and the screen shows two extra
  buttons near the bottom, **MENU** on the left and **FAULT** on the right.
  If touch is turned off in the watch settings, the app cannot score and
  shows **Turn touch on to score**.

In the menus, use the watch as usual: UP and DOWN move, START selects, BACK
goes back. On a touch watch you can also tap a row.

## Starting a match

1. Open the app. The home screen shows the app name and a **MENU** button.
2. Press START (or tap) to open the menu and choose **Start match**.
3. Check the setup. Selecting a row moves it to its next option:
   * **Format**: one of the five [match formats](#match-formats).
   * **No advantage**: **Off** or **On**. When on, the game is decided by
     one point at 40 all.
   * **Point detail**: **Simple** or **Detailed**, see
     [Logging a point](#logging-a-point).
   * **First serve**: **Me** or **Opponent**, the player who serves the
     first game.
   * **GPS**: **Off** or **On**, see
     [GPS and the heat map](#gps-and-the-heat-map). Watches without GPS do
     not show this row.
4. Choose **Start**. The match screen opens and the activity starts
   recording.

The setup remembers your last choices and opens with **Start** already
selected, so the next match with the same setup is one press away.

## Match formats

| Format | How it is played |
|---|---|
| **Best of 3 sets** | Sets to 6 games, with a tie break to 7 points at 6 games all |
| **2 sets + 10 point tie break** | The same, but a tie break to 10 points replaces the third set |
| **1 set** | One set to 6 games, with a tie break to 7 points at 6 games all |
| **Pro set to 8** | One set to 8 games, with a tie break to 7 points at 8 games all |
| **Tie break only** | One tie break to 10 points |

Every set and every tie break is won by two clear games or points. The app
handles the serve rotation, including inside a tie break, and the changes
of ends. Version 1 is for singles.

## The match screen

* **Top**: the set score in small digits, finished sets first and then the
  games of the current set.
* **Below it**: one short line for what matters now. It shows **BREAK
  POINT**, **SET POINT** or **MATCH POINT** in the color of the player who
  holds it, a notice (**Game**, **Set**, **Change ends**) for a few seconds,
  or **Paused**.
* **Middle**: your game points on the left under **ME** and the opponent's
  on the right under **OPP**, in large digits. **AD** marks the advantage.
* **Serve ball**: a yellow ball next to the label of the player who serves.
  It carries a **2** on a second serve.
* **Mini court**: between the two scores, seen from above with your end at
  the bottom. The highlighted quarter is where the server stands (deuce or
  ad side), and a small dot behind each baseline shows the end each player
  is on.
* **Bottom**: the match clock and, when the watch has a reading, your heart
  rate after a red dot.

When it is time to change ends, the watch vibrates and shows **Change
ends**.

## Logging a point

Give every point to the player who won it: UP or a tap on the left half for
you, DOWN or a tap on the right half for the opponent.

**Simple** needs nothing else. One press and the score moves.

**Detailed** asks one more question. After you say who won, a short list
named **Point** asks how the point ended:

* **Winner**: a ball the other player could not reach.
* **Ace**: offered only when the player who won the point was serving.
* **Error in the net**
* **Error out**

Under each choice the list shows who hit that last ball, **Me** or
**Opponent**. For example, if you won the point, **Error out** is the
opponent's error. The list opens on **Error out**, the most common ending,
so that case is two presses. BACK on the list cancels the point and nothing
is logged.

You can choose the detail level only when the match starts.

## Serve faults

One button logs the serve faults of both players: START, or **FAULT** on a
two button watch. The app knows who is serving.

* First press: a missed first serve. A **2** appears on the serve ball.
* Second press: a double fault. The point goes to the receiver
  automatically.

If the second serve goes in, just log the point as usual. The app records
that it was played on a second serve.

## Undo and fixing the score

* **Undo**: BACK removes the last entry, a point or a fault. Press it again
  to go further back, one entry at a time.
* **Fix the score**: open the match menu and choose **Fix the score** when
  the score went wrong some time ago:
  * **Undo game** removes the game in progress, or the game before it when
    the current game has no point yet.
  * **Game for me** and **Game for opponent** give the game in progress to
    that player.

The score, the server, the sides and the statistics are always worked out
again from the list of points, so they stay right after any correction.

## Pause and end

Open the match menu: hold UP, or tap **MENU** on a two button watch.

* **Pause** stops the clock and the activity. The screen shows **Paused**
  and no point can be logged or undone. To go on, press START (**FAULT** on
  a two button watch) or choose **Resume** in the menu.
* **End match** stops a match before it is decided. The watch asks **End
  the match?** first.

When the last point of the match is played, or after **End match**, the
final score screen shows **You won**, **You lost** or **Match ended**, with
the sets and the time played.

* Press START (or tap) and choose **Save** or **Discard**. Discard asks
  **Discard the activity?** first. The watch confirms with **Saved!** or
  **Discarded**.
* Press BACK to return to the match, for example when the last point was
  entered by mistake. If the match was decided, that last point is removed.

**(planned)** When you save, the app also asks for two tags: the surface
(clay, hard or grass) and whether it was a match or a friendly.

The watch keeps no history of matches. Saved matches live in Garmin Connect
and in the export.

## Resuming an interrupted match

The match in progress is stored on the watch after every entry, so it
survives the app closing.

* If the app closes during a match, what was recorded so far is saved as an
  activity.
* The next time you open the app, a menu named **Open match** offers
  **Resume** or **Discard**. BACK keeps the match for later. Starting a new
  match replaces it.
* **Resume** brings back the score, the server, the sides and the
  statistics exactly. The clock goes on from the time of the last entry.
* A resumed match is recorded as a **new** activity, so that match has two
  activities in Garmin Connect, each with its own time, steps and distance.
* A first serve fault that was waiting for its second serve comes back. A
  point whose ending you were still choosing in the list is lost.
* If the watch itself restarts or runs out of battery, the activity of that
  part is most likely lost, but the stored match can still be resumed.
* If the app closes on the final score screen before you choose, the
  activity is saved.

## The report

### On the watch (planned)

After the match the watch shows pages you can scroll through:

* The final score, set by set.
* Serve: aces, double faults, first serve percentage, points won on first
  and on second serve, service games won.
* Return: return games won, break points won.
* Points: winners, errors in the net, errors out, total points won.
* Pressure: break points won and saved, longest run of points, average
  heart rate on deciding points.
* Times: the duration of each set and game, and the average time between
  points.
* Heart rate and calories.

The numbers are shown for both players where the log allows it. Winners,
aces and the two kinds of error need the **Detailed** point detail. With
**Simple** the app knows only who won each point.

### In Garmin Connect

A saved match is a Tennis activity with:

* Heart rate, calories and time.
* One lap per set.
* **Steps** and **Distance** as extra fields, for the whole match and for
  each set.
* **(planned)** The main statistics as extra fields.
* The GPS track, when the GPS switch was on.

## Exporting your data

**(planned on the watch side)** Every point is stored inside the activity
file, in FIT, the open Garmin format: who served, the faults, who won, how
it ended, the score and the time. A free converter named `tennis-export`,
shipped in the repository of the app, turns that file into files any
spreadsheet or script can read. It runs on your own computer.

1. Export the original file of the activity from Garmin Connect. It is a
   file that ends in `.fit`.
2. Get the repository of the app and install
   [`uv`](https://docs.astral.sh/uv/), which runs the converter and
   installs what it needs on first use.
3. In the folder of the repository, run:

   ```bash
   uv run tennis-export activity.fit --out my-match
   ```

The converter prints the files it wrote in the chosen folder. Without
`--out` they go to a folder named after the file, next to it (for
`activity.fit`, the folder `activity-export`).

* `points.csv`: one row for each point or fault, in the order played, with
  the server, the result, how it ended and the score after it.
* `match.json`: the setup, the final score, the statistics of both players,
  the duration of every set and game, the tags, heart rate, steps and
  distance.
* `heatmap.png`: only when the activity has a GPS track, see below.

An activity that was not recorded by this app still converts: the result
then holds only the general activity data. Every column and field is
described in [DATA_FORMAT.md](DATA_FORMAT.md), so other systems, such as a
club system, can read the files too.

## GPS and the heat map

* Steps and distance are always recorded and do not need GPS.
* **GPS** is a switch in the match setup. It is off by default and the app
  remembers your choice. Turn it on only on an open court: it uses more
  battery and does not work indoors.
* Watches without GPS do not show the switch.
* With GPS on, the watch adds the track to the activity and the converter
  draws `heatmap.png`: a picture of where you spent time, over the outline
  of a court, titled "Approximate court heat map". It needs at least ten
  GPS positions.

The heat map is approximate, and here is why:

* Watch GPS is off by 3 to 5 meters, on a court of about 24 by 11 meters.
  The picture shows tendencies, such as behind the baseline or at the net,
  not exact footprints.
* The watch does not know where the court is. The converter guesses the
  place and the direction of the court from how you moved, so playing only
  on one side or at one end shifts the picture.
* With little movement along the court, for example serving practice from
  one spot, the direction can come out wrong.
* Which end is drawn at the bottom is a guess based on where the track
  starts.

Marking the court on the watch to make the map more precise is an idea for
a later version.

## Practice mode

**(planned)** Choose **Practice** in the menu to record a training session
instead of a match.

* The session records time, heart rate, calories, steps and distance.
* Free counters: UP is a hit and DOWN is a miss.
* One button closes the block, so you can count one drill after another,
  for example serves and then forehands.
* The summary at the end shows the success rate of each block.

## To confirm before release

Every item below must be checked, and this guide corrected where the app
ends up different.

1. **Watch report (M5, in progress).** The pages and their order in
   [The report](#the-report) come from the plan.
2. **Match tags (M5, in progress).** When the tags are asked and how the
   options are named.
3. **Statistics in Garmin Connect (M5, in progress).** Only **Steps** and
   **Distance** are written as extra fields today.
4. **Point log in the activity file (M6 watch side, in progress).** Until
   it is written, `tennis-export` gives only the general activity data for
   a real match. Also to confirm: what the two activities of a resumed
   match contain, and the exact name of the export action in Garmin
   Connect.
5. **Practice mode (M7, in progress).** The whole section, including which
   button closes a block. The menu entry shows **Coming soon** today.
6. **Controls on real watches.** Hold UP for the menu, taps, the back swipe
   and the **MENU** and **FAULT** buttons need the watch pass of
   [TESTING.md](TESTING.md). The Venu 2 as the example of a two button
   watch needs a check too.
7. **Vibration at the change of ends** on a real watch.
8. **All 80 devices.** The Tennis sport type, steps, and the hidden GPS row
   on watches without GPS are open checks of the plan.
9. **Settings.** The menu has a **Settings** entry that shows **Coming
   soon**. The plan does not define its content, so this guide does not
   describe it.
