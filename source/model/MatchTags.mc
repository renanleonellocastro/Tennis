import Toybox.Lang;

// What the player says about a match when saving it: the surface and
// whether it counted. The first option of each field is "not set"; the
// others follow the codes of docs/DATA_FORMAT.md.
class MatchTags extends OptionList {
    static const SURFACE = 0;
    static const KIND = 1;

    function initialize(stored as Object?) {
        OptionList.initialize(
            [Str.TagSurface, Str.TagKind] as Array<Number>,
            [
                [Str.TagNotSet, Str.SurfaceClay, Str.SurfaceHard, Str.SurfaceGrass],
                [Str.TagNotSet, Str.KindMatch, Str.KindFriendly]
            ] as Array< Array<Number> >,
            stored);
    }

    function fields() as Array<Number> {
        return [SURFACE, KIND] as Array<Number>;
    }
}
