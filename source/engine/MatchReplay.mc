import Toybox.Lang;

// Derives everything from the point log by applying it from the first entry.
module MatchReplay {
    // Entries past the end of the match are ignored, so a damaged stored log
    // cannot push the score beyond the final result.
    function state(config as MatchConfig, log as PointLog) as MatchState {
        var state = new MatchState(config);
        for (var i = 0; i < log.size() && !state.isFinished(); i++) {
            state.apply(log.at(i));
        }
        return state;
    }

    function statistics(config as MatchConfig, log as PointLog) as MatchStatistics {
        var state = new MatchState(config);
        var collector = new StatisticsCollector();
        for (var i = 0; i < log.size() && !state.isFinished(); i++) {
            collector.record(state, log.at(i));
        }
        return collector.statistics();
    }
}
