import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

// Tests for the tags of a saved match and how they are remembered.
module MatchTagsTests {
    function assertFallsBackToNotSet(stored as Object?) as Void {
        Test.assertEqual(joinedNumbers(new MatchTags(stored).toArray()), "0,0");
    }

    (:test)
    function testTagsAreNotSetWhenStorageHasNothingUsable(logger as Test.Logger) as Boolean {
        assertFallsBackToNotSet(null);
        assertFallsBackToNotSet("tags");
        assertFallsBackToNotSet([1]);
        assertFallsBackToNotSet([4, 0]);
        assertFallsBackToNotSet([0, 3]);
        assertFallsBackToNotSet([0, "match"]);
        return true;
    }

    (:test)
    function testTagsKeepValidStoredChoices(logger as Test.Logger) as Boolean {
        var tags = new MatchTags([3, 2]);
        Test.assertEqual(joinedNumbers(tags.toArray()), "3,2");
        Test.assertEqual(tags.labelKey(MatchTags.SURFACE), Str.TagSurface);
        Test.assertEqual(tags.valueKey(MatchTags.SURFACE), Str.SurfaceGrass);
        Test.assertEqual(tags.labelKey(MatchTags.KIND), Str.TagKind);
        Test.assertEqual(tags.valueKey(MatchTags.KIND), Str.KindFriendly);
        return true;
    }

    // The option index is the code the activity file keeps.
    (:test)
    function testTagOptionsFollowTheCodesOfTheFile(logger as Test.Logger) as Boolean {
        var tags = new MatchTags(null);
        var surfaces = [Str.TagNotSet, Str.SurfaceClay, Str.SurfaceHard, Str.SurfaceGrass];
        for (var i = 0; i < surfaces.size(); i++) {
            Test.assertEqual(tags.valueKey(MatchTags.SURFACE), surfaces[i]);
            tags.cycle(MatchTags.SURFACE);
        }
        Test.assertEqual(tags.valueKey(MatchTags.SURFACE), Str.TagNotSet);
        tags.cycle(MatchTags.KIND);
        Test.assertEqual(tags.valueKey(MatchTags.KIND), Str.KindMatch);
        Test.assertEqual(tags.optionCount(MatchTags.KIND), 3);
        return true;
    }

    (:test)
    function testTagTextsExistInEveryLanguage(logger as Test.Logger) as Boolean {
        var tags = new MatchTags(null);
        var fields = tags.fields();
        Test.assertEqual(fields.size(), 2);
        for (var i = 0; i < fields.size(); i++) {
            assertKeyInEveryLanguage(tags.labelKey(fields[i]));
            for (var option = 0; option < tags.optionCount(fields[i]); option++) {
                assertKeyInEveryLanguage(tags.valueKey(fields[i]));
                tags.cycle(fields[i]);
            }
        }
        return true;
    }

    (:test)
    function testTagStoreRemembersTheLastTags(logger as Test.Logger) as Boolean {
        TagStore.save(new MatchTags([2, 1]));
        Test.assertEqual(joinedNumbers(TagStore.load().toArray()), "2,1");
        Application.Storage.deleteValue(TagStore.KEY);
        Test.assertEqual(joinedNumbers(TagStore.load().toArray()), "0,0");
        return true;
    }
}
