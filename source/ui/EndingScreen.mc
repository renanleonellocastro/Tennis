import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// How the point ended, in detailed mode: one press on a key, or one tap on
// an area, picks the ending. The texts and the places come from
// EndingChoices.
module EndingScreen {
    const CENTERED = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    // Rows of the title and of the name of who won the point, in percent of
    // the height: around the middle between the keys, at the top above the
    // tap areas.
    const KEY_ROWS = [36, 53];
    (:keyArc)
    const TAP_ROWS = [11, 21];
    // How much of the room of an area its widest text may take, in percent,
    // so that the word keeps air on both sides.
    (:keyArc)
    const AREA_FILL = 85;
    // The room of the name, in percent of the screen.
    const NAME_ROOM = [60, 22];

    // A watch with neither the labels of the keys nor a touch screen keeps
    // the plain list.
    function show(controller as MatchController, layout as MatchLayout) as Void {
        if (layout.hasKeyHints() || layout.hasTouchControls()) {
            WatchUi.pushView(new View(controller, layout), new Delegate(controller, layout), WatchUi.SLIDE_IMMEDIATE);
        } else {
            WatchUi.pushView(MatchFlow.endingMenu(controller.pendingWinner(), controller.state().server()),
                             new ListDelegate(controller), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    // The watches that draw their key labels from images have no touch
    // screen, so they carry no code for the tap areas.
    (:keyImages)
    function headerRows(layout as MatchLayout) as Array<Number> {
        return KEY_ROWS;
    }

    (:keyImages)
    function drawAreas(dc as Dc, layout as MatchLayout, winner as Number, server as Number) as Void {
    }

    (:keyArc)
    function headerRows(layout as MatchLayout) as Array<Number> {
        return layout.hasTouchControls() ? TAP_ROWS : KEY_ROWS;
    }

    // One font for every area: the largest in which the widest ending fits
    // a narrow area.
    (:keyArc)
    function areaFont(dc as Dc, layout as MatchLayout, choices as Array<Number>) as Graphics.FontDefinition {
        var widest = "";
        for (var i = 0; i < choices.size(); i++) {
            var text = Strings.t(EndingChoices.labelKey(choices[i]));
            if (dc.getTextWidthInPixels(text, Graphics.FONT_XTINY) > dc.getTextWidthInPixels(widest, Graphics.FONT_XTINY)) {
                widest = text;
            }
        }
        var narrow = EndingChoices.tapRect(0, 4, [dc.getWidth(), dc.getHeight()] as Array<Number>, layout.isRound());
        var room = EndingChoices.textRoom(narrow);
        return MatchDraw.textFont(dc, widest, 0, [room[0] * AREA_FILL / 100, room[1]] as Array<Number>);
    }

    // One outlined area with the name of its ending.
    (:keyArc)
    function drawArea(dc as Dc, box as Array<Number>, font as Graphics.FontDefinition, text as String) as Void {
        dc.setPenWidth(Theme.FRAME_PEN);
        dc.setColor(Theme.COLOR_FRAME, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(box[0], box[1], box[2], box[3], box[3] / 3);
        dc.setPenWidth(1);
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(box[0] + box[2] / 2, box[1] + box[3] / 2, font, text, CENTERED);
    }

    // One area per ending, like the touch controls of the match.
    (:keyArc)
    function drawAreas(dc as Dc, layout as MatchLayout, winner as Number, server as Number) as Void {
        var choices = layout.hasTouchControls() ? EndingChoices.tapChoices(winner, server) : [] as Array<Number>;
        var font = areaFont(dc, layout, choices);
        var screen = [dc.getWidth(), dc.getHeight()] as Array<Number>;
        for (var i = 0; i < choices.size(); i++) {
            drawArea(dc, EndingChoices.tapRect(i, choices.size(), screen, layout.isRound()), font,
                     Strings.t(EndingChoices.labelKey(choices[i])));
        }
    }

    class View extends WatchUi.View {
        hidden var _layout as MatchLayout;
        hidden var _winner as Number;
        hidden var _server as Number;
        hidden var _keys as Array<Number>;

        function initialize(controller as MatchController, layout as MatchLayout) {
            View.initialize();
            _layout = layout;
            _winner = controller.pendingWinner();
            _server = controller.state().server();
            _keys = EndingChoices.keyTexts(_winner, _server);
        }

        function onShow() as Void {
            MatchDraw.prepare(_layout, _keys);
        }

        function onHide() as Void {
            MatchDraw.release();
        }

        function onUpdate(dc as Dc) as Void {
            dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
            dc.clear();
            drawHeader(dc, EndingScreen.headerRows(_layout));
            for (var slot = 0; slot < KeySlot.COUNT; slot++) {
                MatchDraw.drawKeyLabel(dc, _layout, slot, _keys);
            }
            EndingScreen.drawAreas(dc, _layout, _winner, _server);
        }

        // The quiet title and, in the color of the player, who won the point.
        hidden function drawHeader(dc as Dc, rows as Array<Number>) as Void {
            var name = Strings.t(_winner == Player.ME ? Str.PlayerMe : Str.PlayerOpponent);
            var room = [dc.getWidth() * NAME_ROOM[0] / 100, dc.getHeight() * NAME_ROOM[1] / 100] as Array<Number>;
            dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_layout.centerX(), dc.getHeight() * rows[0] / 100, Graphics.FONT_XTINY,
                        Strings.t(Str.EndingTitle), CENTERED);
            dc.setColor(MatchDraw.TONE_COLORS[_winner] as Number, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_layout.centerX(), dc.getHeight() * rows[1] / 100, MatchDraw.textFont(dc, name, 0, room),
                        name, CENTERED);
        }
    }

    // A key picks its ending on a watch that shows the labels of the keys;
    // a tap picks the ending of its area. BACK, as a key or as a gesture,
    // returns to the match without a point.
    class Delegate extends WatchUi.BehaviorDelegate {
        hidden var _controller as MatchController;
        hidden var _layout as MatchLayout;
        hidden var _winner as Number;
        hidden var _server as Number;

        function initialize(controller as MatchController, layout as MatchLayout) {
            BehaviorDelegate.initialize();
            _controller = controller;
            _layout = layout;
            _winner = controller.pendingWinner();
            _server = controller.state().server();
        }

        hidden function choose(choice as Number) as Boolean {
            var reaction = EndingChoices.settle(_controller, choice);
            if (reaction == null) {
                // The two errors were on the keys: the list opens on the rest.
                var menu = MatchFlow.endingMenu(_winner, _server);
                menu.setFocus(0);
                WatchUi.switchToView(menu, new ListDelegate(_controller), WatchUi.SLIDE_IMMEDIATE);
            } else if (choice != EndingChoices.NOTHING) {
                MatchAlert.play(Reaction.cueOf(reaction));
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            }
            return true;
        }

        function onKey(event as WatchUi.KeyEvent) as Boolean {
            var action = MatchInput.actionForKey(event.getKey());
            return choose(EndingChoices.keyChoice(action, _layout.hasKeyHints(), _winner, _server));
        }

        (:keyArc)
        function onTap(event as WatchUi.ClickEvent) as Boolean {
            var at = event.getCoordinates();
            var settings = System.getDeviceSettings();
            return choose(_layout.hasTouchControls()
                ? EndingChoices.tapChoice(at, [settings.screenWidth, settings.screenHeight] as Array<Number>,
                                          _layout.isRound(), _winner, _server)
                : EndingChoices.NOTHING);
        }

        function onBack() as Boolean {
            return choose(EndingChoices.CANCEL);
        }
    }

    // The full list of endings, behind the more key and on a watch without labels.
    class ListDelegate extends WatchUi.Menu2InputDelegate {
        hidden var _controller as MatchController;

        function initialize(controller as MatchController) {
            Menu2InputDelegate.initialize();
            _controller = controller;
        }

        function onSelect(item as WatchUi.MenuItem) as Void {
            MatchAlert.play(Reaction.cueOf(_controller.chooseEnding(item.getId() as Number)));
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }

        function onBack() as Void {
            _controller.cancelEnding();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }
}
