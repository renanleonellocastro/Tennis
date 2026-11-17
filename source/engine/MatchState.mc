import Toybox.Lang;

// What one applied log entry did, as flags that add up: the point that ends
// a set reports POINT, GAME and SET together.
module Outcome {
    const FAULT = 0;
    const POINT = 1;
    const GAME = 2;
    const SET = 4;
    const MATCH = 8;
}

// The score of a match, built by applying the log entries in order. It knows
// the rules of tennis and nothing about the clock, the screen or storage.
// Views read it; only MatchEngine and MatchReplay apply entries to it.
class MatchState {
    // Shown in place of 40 for the player who is one point from the game
    // after deuce.
    static const DISPLAY_ADVANTAGE = 50;

    hidden const REGULAR_GAME_POINTS = 4;
    hidden const DEUCE_POINTS = 3;
    hidden const DISPLAY_POINT_STEP = 15;
    hidden const DISPLAY_FORTY = 40;
    hidden const TWO_CLEAR = 2;
    hidden const TIE_BREAK_POINTS_PER_END = 6;
    hidden const SET_SCORE_WIDTH = 4;

    hidden var _config as MatchConfig;
    hidden var _points as Array<Number> = [0, 0] as Array<Number>;
    hidden var _games as Array<Number> = [0, 0] as Array<Number>;
    hidden var _sets as Array<Number> = [0, 0] as Array<Number>;
    // Per finished set: games of each player, then the points of each player
    // in its last game.
    hidden var _setScores as Array<Number> = [] as Array<Number>;
    hidden var _serviceTurn as Number = 0;
    hidden var _isSecondServe as Boolean = false;
    hidden var _endChanges as Number = 0;
    hidden var _isChangeOfEndsDue as Boolean = false;
    hidden var _winner as Number = Player.NONE;

    function initialize(config as MatchConfig) {
        _config = config;
    }

    // Applies one log entry and returns its Outcome flags.
    function apply(entry as Number) as Number {
        _isChangeOfEndsDue = false;
        if (PointEntry.isFault(entry) && !_isSecondServe) {
            _isSecondServe = true;
            return Outcome.FAULT;
        }
        return awardPoint(pointWinner(entry));
    }

    // Who takes the point when this entry ends one. A fault ends a point
    // only as a double fault, which goes to the receiver.
    function pointWinner(entry as Number) as Number {
        return PointEntry.isFault(entry) ? receiver() : PointEntry.winner(entry);
    }

    hidden function awardPoint(winner as Number) as Number {
        _isSecondServe = false;
        _points[winner] += 1;
        if (winsGameWith(_points[winner], lead(_points, winner))) {
            return Outcome.POINT | closeGame(winner);
        }
        changeEndsEverySixTieBreakPoints();
        return Outcome.POINT;
    }

    hidden function closeGame(winner as Number) as Number {
        var isSetOver = wouldWinSet(winner);
        _games[winner] += 1;
        _serviceTurn += 1;
        changeEndsAfterOddGame();
        if (isSetOver) {
            return Outcome.GAME | closeSet(winner);
        }
        clear(_points);
        return Outcome.GAME;
    }

    hidden function closeSet(winner as Number) as Number {
        _sets[winner] += 1;
        _setScores.addAll([_games[0], _games[1], _points[0], _points[1]] as Array<Number>);
        clear(_games);
        clear(_points);
        if (_sets[winner] < _config.setsToWin()) {
            return Outcome.SET;
        }
        _winner = winner;
        _isChangeOfEndsDue = false;
        return Outcome.SET | Outcome.MATCH;
    }

    hidden function clear(pair as Array<Number>) as Void {
        pair[Player.ME] = 0;
        pair[Player.OPPONENT] = 0;
    }

    hidden function lead(pair as Array<Number>, player as Number) as Number {
        return pair[player] - pair[Player.opponentOf(player)];
    }

    hidden function pointsPlayed() as Number {
        return _points[Player.ME] + _points[Player.OPPONENT];
    }

    // Rules of the game in progress.

    function isTieBreak() as Boolean {
        var gamesAll = _config.gamesPerSet();
        return isMatchTieBreak() || (_games[Player.ME] == gamesAll && _games[Player.OPPONENT] == gamesAll);
    }

    hidden function isMatchTieBreak() as Boolean {
        var setsBeforeDecider = _config.setsToWin() - 1;
        return _config.matchTieBreakPoints() > 0 && _sets[Player.ME] == setsBeforeDecider
            && _sets[Player.OPPONENT] == setsBeforeDecider;
    }

    hidden function gameTarget() as Number {
        if (isMatchTieBreak()) {
            return _config.matchTieBreakPoints();
        }
        return isTieBreak() ? _config.tieBreakPoints() : REGULAR_GAME_POINTS;
    }

    hidden function gameMargin() as Number {
        return isTieBreak() ? TWO_CLEAR : _config.gameWinMargin();
    }

    hidden function winsGameWith(points as Number, pointsLead as Number) as Boolean {
        return points >= gameTarget() && pointsLead >= gameMargin();
    }

    hidden function wouldWinSet(player as Number) as Boolean {
        return isTieBreak() || (_games[player] + 1 >= _config.gamesPerSet()
            && lead(_games, player) + 1 >= TWO_CLEAR);
    }

    // Ends.

    hidden function changeEndsAfterOddGame() as Void {
        if ((_games[Player.ME] + _games[Player.OPPONENT]) % 2 == 1) {
            changeEnds();
        }
    }

    hidden function changeEndsEverySixTieBreakPoints() as Void {
        if (isTieBreak() && pointsPlayed() % TIE_BREAK_POINTS_PER_END == 0) {
            changeEnds();
        }
    }

    hidden function changeEnds() as Void {
        _endChanges += 1;
        _isChangeOfEndsDue = true;
    }

    // True right after the entry that sent the players to the other end.
    function isChangeOfEndsDue() as Boolean {
        return _isChangeOfEndsDue;
    }

    function endOf(player as Number) as Number {
        return (_endChanges + player) % 2 == 0 ? CourtEnd.NEAR : CourtEnd.FAR;
    }

    // Serve.

    function server() as Number {
        return _config.serverAt(_serviceTurn + tieBreakServeTurns());
    }

    function receiver() as Number {
        return Player.opponentOf(server());
    }

    // Inside a tie break the serve passes after the first point and then
    // after every two.
    hidden function tieBreakServeTurns() as Number {
        return isTieBreak() ? (pointsPlayed() + 1) / 2 : 0;
    }

    function serveSide() as Number {
        return pointsPlayed() % 2 == 0 ? ServeSide.DEUCE : ServeSide.AD;
    }

    function isSecondServe() as Boolean {
        return _isSecondServe;
    }

    // Score.

    // 0, 15, 30, 40 or DISPLAY_ADVANTAGE in a regular game; the plain count
    // in a tie break.
    function displayPoints(player as Number) as Number {
        var points = _points[player];
        if (isTieBreak()) {
            return points;
        }
        if (points < DEUCE_POINTS) {
            return points * DISPLAY_POINT_STEP;
        }
        return lead(_points, player) > 0 && points > DEUCE_POINTS ? DISPLAY_ADVANTAGE : DISPLAY_FORTY;
    }

    function games(player as Number) as Number {
        return _games[player];
    }

    function sets(player as Number) as Number {
        return _sets[player];
    }

    function finishedSets() as Number {
        return _setScores.size() / SET_SCORE_WIDTH;
    }

    function setGames(setIndex as Number, player as Number) as Number {
        return _setScores[setIndex * SET_SCORE_WIDTH + player];
    }

    // Points of the tie break that decided a finished set, or zero when the
    // set was won by two clear games.
    function setTieBreakPoints(setIndex as Number, player as Number) as Number {
        var gamesGap = setGames(setIndex, Player.ME) - setGames(setIndex, Player.OPPONENT);
        if (gamesGap.abs() >= TWO_CLEAR) {
            return 0;
        }
        return _setScores[setIndex * SET_SCORE_WIDTH + Player.COUNT + player];
    }

    function isFinished() as Boolean {
        return _winner != Player.NONE;
    }

    function winner() as Number {
        return _winner;
    }

    // Pressure flags.

    function hasGamePoint(player as Number) as Boolean {
        return !isFinished() && winsGameWith(_points[player] + 1, lead(_points, player) + 1);
    }

    function hasBreakPoint(player as Number) as Boolean {
        return !isTieBreak() && player == receiver() && hasGamePoint(player);
    }

    function hasSetPoint(player as Number) as Boolean {
        return hasGamePoint(player) && wouldWinSet(player);
    }

    function hasMatchPoint(player as Number) as Boolean {
        return hasSetPoint(player) && _sets[player] + 1 >= _config.setsToWin();
    }

    // A break, set or match point for either player (a match point is
    // always a set point too).
    function isDecidingPoint() as Boolean {
        return hasBreakPoint(receiver()) || hasSetPoint(Player.ME) || hasSetPoint(Player.OPPONENT);
    }
}
