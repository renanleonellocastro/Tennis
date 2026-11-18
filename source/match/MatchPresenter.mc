import Toybox.Lang;

// Whose line the banner is. The player ids double as tones, so a point at
// stake takes the color of the player who holds it.
module BannerTone {
    const ME = Player.ME;
    const OPPONENT = Player.OPPONENT;
    const NOTICE = 2;
}

// Turns the match state into the texts of the match and final screens.
module MatchPresenter {
    // Tennis writes a score as two numbers joined by this sign.
    const SCORE_SEPARATOR = "-";
    const SET_GAP = "  ";
    const NOTICE_GAP = ". ";
    const SECONDS_PER_MINUTE = 60;
    const MINUTES_PER_HOUR = 60;
    // Checked in this order for each player: the heaviest label wins.
    const PRESSURES = [
        [:hasMatchPoint, Str.LabelMatchPoint],
        [:hasSetPoint, Str.LabelSetPoint],
        [:hasBreakPoint, Str.LabelBreakPoint]
    ];

    // The number fonts only have digits, so the screen needs to know when
    // the points are a word such as the advantage.
    function isPointsNumeric(state as MatchState, player as Number) as Boolean {
        return state.displayPoints(player) != MatchState.DISPLAY_ADVANTAGE;
    }

    function pointsText(state as MatchState, player as Number) as String {
        if (!isPointsNumeric(state, player)) {
            return Strings.t(Str.LabelAdvantage);
        }
        return state.displayPoints(player).toString();
    }

    function pair(mine as Number, theirs as Number) as String {
        return mine + SCORE_SEPARATOR + theirs;
    }

    // A set decided by nothing but a tie break (a match tie break, or the
    // tie break only format) reads as its points; any other set as its games.
    function finishedSetText(state as MatchState, set as Number) as String {
        var mine = state.setGames(set, Player.ME);
        var theirs = state.setGames(set, Player.OPPONENT);
        if (mine + theirs > 1) {
            return pair(mine, theirs);
        }
        return pair(state.setTieBreakPoints(set, Player.ME), state.setTieBreakPoints(set, Player.OPPONENT));
    }

    function finishedSetsText(state as MatchState) as String {
        var text = "";
        for (var set = 0; set < state.finishedSets(); set++) {
            text += (set == 0 ? "" : SET_GAP) + finishedSetText(state, set);
        }
        return text;
    }

    // A match tie break, or the tie break only format, has no games to show.
    function isOnlyTieBreak(state as MatchState) as Boolean {
        return state.isTieBreak() && state.games(Player.ME) + state.games(Player.OPPONENT) == 0;
    }

    // The finished sets and then the games of the set in progress.
    function setsText(state as MatchState) as String {
        var finished = finishedSetsText(state);
        if (state.isFinished() || isOnlyTieBreak(state)) {
            return finished;
        }
        var current = pair(state.games(Player.ME), state.games(Player.OPPONENT));
        return finished.length() == 0 ? current : finished + SET_GAP + current;
    }

    // The final screen leaves out a set that never started: a match that
    // stopped right after a set reads "6-1", not "6-1  0-0".
    function finalSetsText(state as MatchState) as String {
        return MatchSummary.hasOpenSet(state) ? setsText(state) : finishedSetsText(state);
    }

    // [label key, player] of the heaviest point at stake, or null.
    function pressure(state as MatchState) as Array? {
        for (var i = 0; i < PRESSURES.size(); i++) {
            var check = PRESSURES[i] as Array;
            for (var player = 0; player < Player.COUNT; player++) {
                if (state.method(check[0] as Symbol).invoke(player) as Boolean) {
                    return [check[1], player];
                }
            }
        }
        return null;
    }

    // [text, BannerTone] of the line under the set score. A pause comes
    // first, then a fresh notice, then the point at stake.
    function banner(isPaused as Boolean, noticeKeys as Array<Number>, state as MatchState) as Array {
        if (isPaused) {
            return [Strings.t(Str.Paused), BannerTone.NOTICE];
        }
        if (noticeKeys.size() > 0) {
            return [noticeText(noticeKeys), BannerTone.NOTICE];
        }
        var stake = pressure(state);
        return stake == null ? ["", BannerTone.NOTICE] : [Strings.t(stake[0] as Number), stake[1]];
    }

    function twoDigits(value as Number) as String {
        return value.format("%02d");
    }

    // "m:ss" in the first hour, then "h:mm:ss".
    function clockText(seconds as Number) as String {
        var minutes = seconds / SECONDS_PER_MINUTE;
        var tail = ":" + twoDigits(seconds % SECONDS_PER_MINUTE);
        if (minutes < MINUTES_PER_HOUR) {
            return minutes + tail;
        }
        return (minutes / MINUTES_PER_HOUR) + ":" + twoDigits(minutes % MINUTES_PER_HOUR) + tail;
    }

    // "" when the watch has no reading.
    function heartRateText(beats as Number?) as String {
        return beats == null ? "" : beats.toString();
    }

    // The notice keys as one translated line, or "" for no notice.
    function noticeText(keys as Array<Number>) as String {
        var text = "";
        for (var i = 0; i < keys.size(); i++) {
            text += (i == 0 ? "" : NOTICE_GAP) + Strings.t(keys[i]);
        }
        return text;
    }

    function finalTitleKey(state as MatchState) as Number {
        if (!state.isFinished()) {
            return Str.FinalMatchEnded;
        }
        return state.winner() == Player.ME ? Str.FinalYouWon : Str.FinalYouLost;
    }
}
