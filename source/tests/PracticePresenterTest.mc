import Toybox.Lang;
import Toybox.Test;

// Tests for the texts of the practice screen and of the summary, and for
// the pages of the summary.
module PracticeTests {
    (:test)
    function testPercentIsNothingWithoutEntries(logger as Test.Logger) as Boolean {
        Test.assert(PracticePresenter.percent(0, 0) == null);
        Test.assertEqual(PracticePresenter.rateText(0, 0), "");
        return true;
    }

    (:test)
    function testPercentRoundsHalfUp(logger as Test.Logger) as Boolean {
        Test.assertEqual(PracticePresenter.percent(5, 0) as Number, 100);
        Test.assertEqual(PracticePresenter.percent(0, 5) as Number, 0);
        Test.assertEqual(PracticePresenter.percent(3, 1) as Number, 75);
        Test.assertEqual(PracticePresenter.percent(2, 1) as Number, 67);
        Test.assertEqual(PracticePresenter.percent(1, 2) as Number, 33);
        Test.assertEqual(PracticePresenter.percent(1, 7) as Number, 13);
        return true;
    }

    (:test)
    function testRateTextCarriesThePercentSign(logger as Test.Logger) as Boolean {
        Test.assertEqual(PracticePresenter.rateText(3, 1), "75%");
        Test.assertEqual(PracticePresenter.rateText(0, 4), "0%");
        return true;
    }

    (:test)
    function testBlockTitleNamesTheBlock(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        Test.assertEqual(PracticePresenter.blockTitle(1), "Block 1");
        Test.assertEqual(PracticePresenter.blockTitle(12), "Block 12");
        return true;
    }

    (:test)
    function testBannerShowsThePauseBeforeTheRate(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        Test.assertEqual(PracticePresenter.bannerText(true, 3, 1), "Paused");
        Test.assertEqual(PracticePresenter.bannerText(false, 3, 1), "75%");
        Test.assertEqual(PracticePresenter.bannerText(false, 0, 0), "");
        return true;
    }

    (:test)
    function testDigitSlotGrowsWithTheFirstCountOfThreeDigits(logger as Test.Logger) as Boolean {
        Test.assertEqual(PracticePresenter.digitSlot(0, 0), 0);
        Test.assertEqual(PracticePresenter.digitSlot(99, 99), 0);
        Test.assertEqual(PracticePresenter.digitSlot(100, 0), 1);
        Test.assertEqual(PracticePresenter.digitSlot(0, 100), 1);
        return true;
    }

    (:test)
    function testTallyShowsHitsOutOfEntriesAndTheRate(logger as Test.Logger) as Boolean {
        Test.assertEqual(PracticePresenter.tallyText(8, 2), "8/10  80%");
        Test.assertEqual(PracticePresenter.tallyText(0, 0), "0/0");
        return true;
    }

    (:test)
    function testTotalAddsEveryBlock(logger as Test.Logger) as Boolean {
        Test.assertEqual(PracticePresenter.totalText(practiceLogOf("HHXNHXXNH")), "4/7  57%");
        Test.assertEqual(PracticePresenter.totalText(new PracticeLog()), "0/0");
        return true;
    }

    (:test)
    function testBlockRowStartsWithTheBlockNumber(logger as Test.Logger) as Boolean {
        var log = practiceLogOf("HHXNX");
        Test.assertEqual(PracticePresenter.blockRow(log, 0), "1  2/3  67%");
        Test.assertEqual(PracticePresenter.blockRow(log, 1), "2  0/1  0%");
        return true;
    }

    (:test)
    function testSummaryRowsAreOnePageOfBlocks(logger as Test.Logger) as Boolean {
        var log = practiceLogOf("HNXNHHNHXNH");
        Test.assertEqual(joined(PracticePresenter.summaryRows(log, 0, 2)), "1  1/1  100%,2  0/1  0%");
        Test.assertEqual(joined(PracticePresenter.summaryRows(log, 4, 2)), "5  1/1  100%");
        Test.assertEqual(PracticePresenter.summaryRows(log, 6, 2).size(), 0);
        Test.assertEqual(PracticePresenter.summaryRows(new PracticeLog(), 0, 4).size(), 0);
        return true;
    }

    (:test)
    function testPageTextShowsOnlyWithMoreThanOnePage(logger as Test.Logger) as Boolean {
        Test.assertEqual(PracticePresenter.pageText(0, 1), "");
        Test.assertEqual(PracticePresenter.pageText(0, 3), "1/3");
        Test.assertEqual(PracticePresenter.pageText(2, 3), "3/3");
        return true;
    }

    (:test)
    function testSummaryFooterIsTheTimeAndThePage(logger as Test.Logger) as Boolean {
        Test.assertEqual(PracticePresenter.summaryFooter(125, 0, 1), "2:05");
        Test.assertEqual(PracticePresenter.summaryFooter(3725, 1, 2), "1:02:05  2/2");
        return true;
    }

    // SummaryPager.

    (:test)
    function testPagerHasOnePageEvenWithoutRows(logger as Test.Logger) as Boolean {
        Test.assertEqual(new SummaryPager(0, 4).pages(), 1);
        Test.assertEqual(new SummaryPager(4, 4).pages(), 1);
        Test.assertEqual(new SummaryPager(5, 4).pages(), 2);
        Test.assertEqual(new SummaryPager(8, 4).pages(), 2);
        Test.assertEqual(new SummaryPager(9, 4).pages(), 3);
        return true;
    }

    (:test)
    function testPagerStartsOnTheFirstPage(logger as Test.Logger) as Boolean {
        var pager = new SummaryPager(9, 4);
        Test.assertEqual(pager.page(), 0);
        Test.assertEqual(pager.firstRow(), 0);
        Test.assertEqual(pager.pageSize(), 4);
        return true;
    }

    (:test)
    function testPagerMovesForwardUntilTheLastPage(logger as Test.Logger) as Boolean {
        var pager = new SummaryPager(9, 4);
        Test.assert(pager.next());
        Test.assertEqual(pager.firstRow(), 4);
        Test.assert(pager.next());
        Test.assertEqual(pager.page(), 2);
        Test.assert(!pager.next());
        Test.assertEqual(pager.firstRow(), 8);
        return true;
    }

    (:test)
    function testPagerMovesBackUntilTheFirstPage(logger as Test.Logger) as Boolean {
        var pager = new SummaryPager(5, 4);
        Test.assert(!pager.previous());
        pager.next();
        Test.assert(pager.previous());
        Test.assertEqual(pager.page(), 0);
        Test.assert(!pager.previous());
        return true;
    }

    (:test)
    function testPagerWithOnePageStays(logger as Test.Logger) as Boolean {
        var pager = new SummaryPager(3, 4);
        Test.assert(!pager.next());
        Test.assertEqual(pager.page(), 0);
        return true;
    }

    (:test)
    function testSummaryTitleSitsLowerOnAScreenThatIsNotRound(logger as Test.Logger) as Boolean {
        Test.assertEqual(PracticePresenter.summaryTitleY(true), 13);
        Test.assertEqual(PracticePresenter.summaryTitleY(false), 15);
        return true;
    }
}
