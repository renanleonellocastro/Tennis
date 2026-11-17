import Toybox.Lang;

// How a point ended, logged in detailed mode only.
module Ending {
    const NONE = 0;
    const WINNER = 1;
    const ACE = 2;
    const ERROR_NET = 3;
    const ERROR_OUT = 4;
}

// One point log entry packed into a single Number, so the whole log is a
// plain array of numbers that fits in storage and in little memory.
//
//   bits  0..1   result: 0 serve fault, 1 point for Player.ME, 2 point for
//                Player.OPPONENT
//   bits  2..4   ending (see Ending)
//   bits  5..12  heart rate in beats per minute, 0 when there is none
//   bits 13..30  seconds on the match clock, capped at about 72 hours
module PointEntry {
    const RESULT_FAULT = 0;
    const RESULT_MASK = 0x3;
    const ENDING_SHIFT = 2;
    const ENDING_MASK = 0x7;
    const HEART_RATE_SHIFT = 5;
    const HEART_RATE_MASK = 0xFF;
    const TIME_SHIFT = 13;
    const TIME_MASK = 0x3FFFF;

    function fault(time as Number, heartRate as Number?) as Number {
        return pack(RESULT_FAULT, Ending.NONE, time, heartRate);
    }

    function point(winner as Number, ending as Number, time as Number, heartRate as Number?) as Number {
        return pack(winner + 1, ending, time, heartRate);
    }

    function pack(result as Number, ending as Number, time as Number, heartRate as Number?) as Number {
        var beats = heartRate == null ? 0 : heartRate;
        return result | (ending << ENDING_SHIFT)
            | (clamp(beats, HEART_RATE_MASK) << HEART_RATE_SHIFT)
            | (clamp(time, TIME_MASK) << TIME_SHIFT);
    }

    function clamp(value as Number, max as Number) as Number {
        if (value < 0) {
            return 0;
        }
        return value > max ? max : value;
    }

    function isFault(entry as Number) as Boolean {
        return (entry & RESULT_MASK) == RESULT_FAULT;
    }

    // Only meaningful for an entry that is not a fault.
    function winner(entry as Number) as Number {
        return (entry & RESULT_MASK) - 1;
    }

    function ending(entry as Number) as Number {
        return (entry >> ENDING_SHIFT) & ENDING_MASK;
    }

    function time(entry as Number) as Number {
        return (entry >> TIME_SHIFT) & TIME_MASK;
    }

    function heartRate(entry as Number) as Number? {
        var beats = (entry >> HEART_RATE_SHIFT) & HEART_RATE_MASK;
        return beats == 0 ? null : beats;
    }
}
