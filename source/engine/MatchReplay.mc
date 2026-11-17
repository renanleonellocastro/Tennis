import Toybox.Lang;

// Derives everything from the point log by applying it from the first entry.
module MatchReplay {
    function statistics(config as MatchConfig, log as PointLog) as MatchStatistics {
        var state = new MatchState(config);
        var collector = new StatisticsCollector();
        for (var i = 0; i < log.size() && !state.isFinished(); i++) {
            collector.record(state, log.at(i));
        }
        return collector.statistics();
    }
}
