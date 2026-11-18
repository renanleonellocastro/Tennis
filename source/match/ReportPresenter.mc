import Toybox.Lang;

// Builds the pages of the report from a finished match, one page at a time
// so that only the page on screen takes memory. A page is
// [title key, rows]; a row is [label, my value, opponent value] on the
// pages that compare the players and [label, value] on the others. All the
// cells are texts, so the screen only places them.
class ReportPresenter {
    static const MISSING = "--";
    hidden const OF = "/";
    hidden const PERCENT = "%";
    // The pages in the order they show.
    hidden const SCORE_PAGE = 0;
    hidden const SERVE_PAGE = 1;
    hidden const ENDINGS_PAGE = 2;
    hidden const TIME_PAGE = 4;
    hidden const BODY_PAGE = 5;
    hidden const PAGE_COUNT = 6;

    hidden var _state as MatchState;
    hidden var _statistics as MatchStatistics;

    function initialize(state as MatchState, statistics as MatchStatistics) {
        _state = state;
        _statistics = statistics;
    }

    // The endings page exists only when the match asked how points ended.
    function pageCount(isDetailed as Boolean) as Number {
        return isDetailed ? PAGE_COUNT : PAGE_COUNT - 1;
    }

    // The page at an index, counted from zero.
    function page(index as Number, isDetailed as Boolean, clockSeconds as Number, sensors as BodySensors) as Array {
        var kind = !isDetailed && index >= ENDINGS_PAGE ? index + 1 : index;
        var titles = ["ReportScore", "ReportServe", "ReportEndings", "ReportPressure", "ReportTime", "ReportBody"];
        return [titles[kind], rows(kind, clockSeconds, sensors)];
    }

    hidden function rows(kind as Number, clockSeconds as Number, sensors as BodySensors) as Array<Array> {
        if (kind == SCORE_PAGE) {
            return scoreRows();
        }
        if (kind == TIME_PAGE) {
            return timeRows(clockSeconds);
        }
        return kind == BODY_PAGE ? bodyRows(sensors) : playerRows(playerTable(kind));
    }

    // Label key, then the method that gives the value of a player, for
    // each row of a page that compares the players. One flat list: a list
    // of pairs takes more of the little memory of the smallest watches.
    hidden function playerTable(kind as Number) as Array {
        if (kind == SERVE_PAGE) {
            return ["ReportFirstIn", :firstIn, "ReportFirstWon", :firstWon,
                    "ReportSecondWon", :secondWon, "ReportDoubleFaults", :doubleFaults];
        }
        if (kind == ENDINGS_PAGE) {
            return ["ReportAces", :aces, "ReportWinners", :winners,
                    "ReportNetErrors", :netErrors, "ReportOutErrors", :outErrors];
        }
        return ["ReportBreaks", :breaks, "ReportSaved", :saved, "ReportHolds", :holds, "ReportBestRun", :bestRun];
    }

    hidden function playerRows(table as Array) as Array<Array> {
        var rows = [] as Array<Array>;
        for (var i = 0; i < table.size(); i += 2) {
            var value = method(table[i + 1] as Symbol);
            rows.add([Strings.t(table[i] as String), value.invoke(Player.ME), value.invoke(Player.OPPONENT)]);
        }
        return rows;
    }

    // Score: one row per set, the set that was left open and the points.

    hidden function scoreRows() as Array<Array> {
        var rows = [] as Array<Array>;
        for (var set = 0; set < _state.finishedSets(); set++) {
            rows.add(setRow(rows.size(), MatchSummary.setScore(_state, set)));
        }
        if (MatchSummary.hasOpenSet(_state)) {
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
        return [
            [Strings.t("ReportMatchTime"), MatchPresenter.clockText(clockSeconds)],
            [Strings.t("ReportAvgGame"), secondsText(_statistics.averageGameSeconds())],
            [Strings.t("ReportLongGame"), secondsText(_statistics.longestGameSeconds())],
            [Strings.t("ReportPerPoint"), secondsText(Math.round(_statistics.averageSecondsBetweenPoints()).toNumber())]
        ] as Array<Array>;
    }

    // Zero seconds means there was nothing to measure.
    hidden function secondsText(seconds as Number) as String {
        return seconds == 0 ? MISSING : MatchPresenter.clockText(seconds);
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
