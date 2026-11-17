import Toybox.Application;
import Toybox.Lang;

// Remembers the tags of the last saved match, offered again at the next one.
module TagStore {
    const KEY = "tags";

    function load() as MatchTags {
        return new MatchTags(Application.Storage.getValue(KEY));
    }

    function save(tags as MatchTags) as Void {
        Application.Storage.setValue(KEY, tags.toArray() as Array<Application.Storage.ValueType>);
    }
}
