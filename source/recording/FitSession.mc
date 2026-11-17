import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Lang;

// The tennis activity of the watch with the developer fields of
// RecordingFields. Heart rate, calories and the GPS track are recorded by
// the watch itself.
class FitSession {
    hidden var _session as ActivityRecording.Session;
    hidden var _fields as Dictionary<Number, FitContributor.Field> = {} as Dictionary<Number, FitContributor.Field>;

    function initialize(name as String) {
        _session = ActivityRecording.createSession({
            :name => name, :sport => Activity.SPORT_TENNIS, :subSport => Activity.SUB_SPORT_GENERIC
        });
        for (var i = 0; i < RecordingFields.TABLE.size(); i++) {
            createField(RecordingFields.TABLE[i] as Array);
        }
    }

    hidden function createField(row as Array) as Void {
        var type = row[2] as Boolean ? FitContributor.MESG_TYPE_LAP : FitContributor.MESG_TYPE_SESSION;
        var field = _session.createField(row[1] as String, row[0] as Number, FitContributor.DATA_TYPE_UINT32,
                                         {:mesgType => type, :units => row[3] as String});
        field.setData(0);
        _fields.put(row[0] as Number, field);
    }

    function start() as Void {
        _session.start();
    }

    function stop() as Void {
        _session.stop();
    }

    function addLap() as Void {
        _session.addLap();
    }

    function save() as Void {
        _session.save();
    }

    function discard() as Void {
        _session.discard();
    }

    function setField(id as Number, value as Number) as Void {
        (_fields[id] as FitContributor.Field).setData(value);
    }
}
