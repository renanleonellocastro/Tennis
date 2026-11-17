import Toybox.Application;
import Toybox.Lang;

// Remembers the last setup choices between runs of the app.
module SetupStore {
    const KEY = "setup";

    function load() as MatchSetup {
        return new MatchSetup(Application.Storage.getValue(KEY));
    }

    function save(setup as MatchSetup) as Void {
        Application.Storage.setValue(KEY, setup.toArray() as Array<Application.Storage.ValueType>);
    }
}
