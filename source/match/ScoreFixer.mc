import Toybox.Lang;

// Corrections beyond undoing the last entry. Each one only cuts the end of
// the point log or appends plain points to it, so the log stays the single
// source of truth and the score is still derived from it.
module ScoreFixer {
    // Removes the game in progress, or the game before it when the game in
    // progress has no entry yet. False when the log is empty.
    function undoGame(engine as MatchEngine) as Boolean {
        return engine.truncate(engine.gameStart());
    }

    // Gives the game in progress to a player by logging plain points for
    // that player until it closes. Each point is handed to the recorder on
    // its own: the file takes three entries at a time (see PacedSession).
    // False when the match is already over.
    function awardGame(engine as MatchEngine, player as Number, time as Number, recorder as MatchRecorder) as Boolean {
        var games = gamesPlayed(engine.state());
        var isLogged = false;
        while (gamesPlayed(engine.state()) == games && engine.point(player, Ending.NONE, time, null)) {
            recorder.writePointLog(engine.slots());
            isLogged = true;
        }
        return isLogged;
    }

    // Games closed since the first point, over every set.
    function gamesPlayed(state as MatchState) as Number {
        var total = state.games(Player.ME) + state.games(Player.OPPONENT);
        for (var set = 0; set < state.finishedSets(); set++) {
            total += state.setGames(set, Player.ME) + state.setGames(set, Player.OPPONENT);
        }
        return total;
    }
}
