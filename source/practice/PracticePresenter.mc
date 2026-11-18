import Toybox.Lang;

// Turns the counts of a practice into the texts of the practice screen and
// of the summary.
module PracticePresenter {
    const PERCENT = 100;
    const RATE_SIGN = "%";
    const OF_SIGN = "/";
    const GAP = "  ";
    const WORD_GAP = " ";
    // A count from here on has three digits and needs a smaller font.
    const WIDE_COUNT = 100;

    // The hits as a whole percentage of the entries, half rounded up, or
    // null with no entries.
    function percent(hits as Number, misses as Number) as Number? {
        var total = hits + misses;
        if (total == 0) {
            return null;
        }
        return (hits * PERCENT + total / 2) / total;
    }

    // "75%", or "" with no entries.
    function rateText(hits as Number, misses as Number) as String {
        var rate = percent(hits, misses);
        return rate == null ? "" : rate + RATE_SIGN;
    }

    // "Block 2"
    function blockTitle(number as Number) as String {
        return Strings.t(Str.PracticeBlock) + WORD_GAP + number;
    }

    // The line under the block title: the pause, or the rate of the block.
    function bannerText(isPaused as Boolean, hits as Number, misses as Number) as String {
        return isPaused ? Strings.t(Str.Paused) : rateText(hits, misses);
    }

    // Which of the two digit fonts the counts need: 0 while both have at
    // most two digits, 1 from the first one with three.
    function digitSlot(hits as Number, misses as Number) as Number {
        return hits >= WIDE_COUNT || misses >= WIDE_COUNT ? 1 : 0;
    }

    // "8/10  80%": the hits out of the entries and the rate.
    function tallyText(hits as Number, misses as Number) as String {
        var count = hits + OF_SIGN + (hits + misses);
        var rate = rateText(hits, misses);
        return rate.length() == 0 ? count : count + GAP + rate;
    }

    function totalText(log as PracticeLog) as String {
        return tallyText(log.totalHits(), log.totalMisses());
    }

    // "2  8/10  80%": the number of the block and its tally.
    function blockRow(log as PracticeLog, block as Number) as String {
        return (block + 1) + GAP + tallyText(log.hitsOf(block), log.missesOf(block));
    }

    // The rows of one page of the summary, from a block on.
    function summaryRows(log as PracticeLog, first as Number, count as Number) as Array<String> {
        var rows = [] as Array<String>;
        for (var block = first; block < first + count && block < log.blocks(); block++) {
            rows.add(blockRow(log, block));
        }
        return rows;
    }

    // "2/3" when the summary has more than one page, "" otherwise.
    function pageText(page as Number, pages as Number) as String {
        return pages > 1 ? (page + 1) + OF_SIGN + pages : "";
    }

    // The bottom line of the summary: the time and, with it, the page.
    function summaryFooter(seconds as Number, page as Number, pages as Number) as String {
        var clock = MatchPresenter.clockText(seconds);
        var mark = pageText(page, pages);
        return mark.length() == 0 ? clock : clock + GAP + mark;
    }

    // The row of the summary title, as a percentage of the height. The brand
    // arc sits lower on a screen that is not round, so the title moves down.
    function summaryTitleY(isRound as Boolean) as Number {
        return isRound ? 13 : 15;
    }
}
