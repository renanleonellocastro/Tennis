import Toybox.Lang;

// Builds the pages of the report from a finished match. A page is
// [title key, rows]; a row is [label, my value, opponent value] on the
// pages that compare the players and [label, value] on the others. All the
// cells are texts, so the screen only places them.
class ReportPresenter {
    static const MISSING = "--";
    hidden const OF = "/";
    hidden const PERCENT = "%";

    // [label key, method that gives the value of a player].
    hidden const SERVE = [
        ["ReportFirstIn", :firstIn], ["ReportFirstWon", :firstWon],
        ["ReportSecondWon", :secondWon], ["ReportDoubleFaults", :doubleFaults]
    ];
    hidden const ENDINGS = [
        ["ReportAces", :aces], ["ReportWinners", :winners],
        ["ReportNetErrors", :netErrors], ["ReportOutErrors", :outErrors]
    ];
    hidden const PRESSURE = [
        ["ReportBreaks", :breaks], ["ReportSaved", :saved],
        ["ReportHolds", :holds], ["ReportBestRun", :bestRun]
    ];

    hidden var _state as MatchState;
    hidden var _statistics as MatchStatistics;

    function initialize(state as MatchState, statistics as MatchStatistics) {
        _state = state;
        _statistics = statistics;
    }

    // The endings page exists only when the match asked how points ended.
    function pages(isDetailed as Boolean, clockSeconds as Number, sensors as BodySensors) as Array<Array> {
        var pages = [["ReportScore", scoreRows()], ["ReportServe", playerRows(SERVE)]] as Array<Array>;
        if (isDetailed) {
            pages.add(["ReportEndings", playerRows(ENDINGS)]);
        }
        pages.add(["ReportPressure", playerRows(PRESSURE)]);
        pages.add(["ReportTime", timeRows(clockSeconds)]);
        pages.add(["ReportBody", bodyRows(sensors)]);
        return pages;
    }

    hidden function playerRows(table as Array) as Array<Array> {
        var rows = [] as Array<Array>;
        for (var i = 0; i < table.size(); i++) {
            var row = table[i] as Array;
            var value = method(row[1] as Symbol);
            rows.add([Strings.t(row[0] as String), value.invoke(Player.ME), value.invoke(Player.OPPONENT)]);
        }
        return rows;
    }

    // Score: one row per set, the set that was left open and the points.

    hidden function scoreRows() as Array<Array> {
        var rows = [] as Array<Array>;
        for (var set = 0; set < _state.finishedSets(); set++) {
            rows.add(setRow(rows.size(), MatchSummary.setScore(_state, set)));
        }
        if (!_state.isFinished()) {
            rows.add(setRow(rows.size(), MatchSummary.openSetScore(_state)));
        }
        rows.add([Strings.t("ReportPoints"), count(Stat.POINTS_WON, Player.ME), count(Stat.POINTS_WON, Player.OPPONENT)]);
        return rows;
    }

    hidden function setRow(index as Number, score as Array<Number>) as Array {
        var label = Strings.t("ReportSet") + " " + (index + 1);
        return [label, setCell(score, Player.ME), setCell(score, Player.OPPONENT)];
    }

    // The games of a player in a set, with the tie break points when a tie
    // break was played: "7(7)".
    hidden function setCell(score as Array<Number>, player as Number) as String {
        var games = score[player].toString();
        if (score[Player.COUNT] + score[Player.COUNT + 1] == 0) {
            return games;
        }
        return games + "(" + score[Player.COUNT + player] + ")";
    }

    // Values of one player.

    hidden function count(stat as Number, player as Number) as String {
        return _statistics.count(stat, player).toString();
    }

    hidden function ratio(part as Number, whole as Number) as String {
        return part + OF + whole;
    }

    function firstIn(player as Number) as String {
        return _statistics.firstServePercent(player) + PERCENT;
    }

    function firstWon(player as Number) as String {
        return ratio(_statistics.count(Stat.FIRST_SERVE_POINTS_WON, player),
                     _statistics.count(Stat.FIRST_SERVES_IN, player));
    }

    function secondWon(player as Number) as String {
        return ratio(_statistics.count(Stat.SECOND_SERVE_POINTS_WON, player),
                     _statistics.secondServePoints(player));
    }

    function doubleFaults(player as Number) as String {
        return count(Stat.DOUBLE_FAULTS, player);
    }

    function aces(player as Number) as String {
        return count(Stat.ACES, player);
    }

    function winners(player as Number) as String {
        return count(Stat.WINNERS, player);
    }

    function netErrors(player as Number) as String {
        return count(Stat.ERRORS_NET, player);
    }

    function outErrors(player as Number) as String {
        return count(Stat.ERRORS_OUT, player);
    }

    // Break points won out of the chances.
    function breaks(player as Number) as String {
        return ratio(_statistics.count(Stat.BREAK_POINTS_WON, player),
                     _statistics.count(Stat.BREAK_POINT_CHANCES, player));
    }

    // Break points saved out of the ones faced.
    function saved(player as Number) as String {
        return ratio(_statistics.breakPointsSaved(player), _statistics.breakPointsFaced(player));
    }

    // Service games won out of the ones played.
    function holds(player as Number) as String {
        return ratio(_statistics.count(Stat.SERVICE_GAMES_WON, player),
                     _statistics.count(Stat.SERVICE_GAMES_PLAYED, player));
    }

    function bestRun(player as Number) as String {
        return count(Stat.LONGEST_RUN, player);
    }

    // Times.

    hidden function timeRows(clockSeconds as Number) as Array<Array> {
        var games = _statistics.gameDurations();
        return [
            [Strings.t("ReportMatchTime"), MatchPresenter.clockText(clockSeconds)],
            [Strings.t("ReportAvgGame"), secondsText(average(games))],
            [Strings.t("ReportLongGame"), secondsText(longest(games))],
            [Strings.t("ReportPerPoint"), secondsText(Math.round(_statistics.averageSecondsBetweenPoints()).toNumber())]
        ] as Array<Array>;
    }

    // Zero seconds means there was nothing to measure.
    hidden function secondsText(seconds as Number) as String {
        return seconds == 0 ? MISSING : MatchPresenter.clockText(seconds);
    }

    hidden function average(values as Array<Number>) as Number {
        var sum = 0;
        for (var i = 0; i < values.size(); i++) {
            sum += values[i];
        }
        return values.size() == 0 ? 0 : (sum + values.size() / 2) / values.size();
    }

    hidden function longest(values as Array<Number>) as Number {
        var best = 0;
        for (var i = 0; i < values.size(); i++) {
            best = values[i] > best ? values[i] : best;
        }
        return best;
    }

    // Heart rate and calories.

    hidden function bodyRows(sensors as BodySensors) as Array<Array> {
        return [
            [Strings.t("ReportAvgHr"), numberText(sensors.averageHeartRate())],
            [Strings.t("ReportMaxHr"), numberText(sensors.maxHeartRate())],
            [Strings.t("ReportKeyHr"), numberText(_statistics.averageDecidingHeartRate())],
            [Strings.t("ReportCalories"), numberText(sensors.calories())]
        ] as Array<Array>;
    }

    hidden function numberText(value as Number?) as String {
        return value == null ? MISSING : value.toString();
    }
}
