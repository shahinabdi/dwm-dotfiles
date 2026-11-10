import QtQuick
import Quickshell

// Power menu -> ~/.local/bin/dwm-power. Log out / reboot / shut down need a second click.
Item {
    id: root

    width: 300
    height: row.implicitHeight

    signal requestClose()

    property string armed: ""   // action waiting for confirmation

    function act(action, needsConfirm) {
        if (needsConfirm && root.armed !== action) {
            root.armed = action
            disarm.restart()
            return
        }
        root.armed = ""
        root.requestClose()
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; dwm-power " + action])
    }

    Timer { id: disarm; interval: 3000; onTriggered: root.armed = "" }

    Row {
        id: row
        width: parent.width
        spacing: 6

        readonly property real cellWidth: (width - 4 * spacing) / 5

        ActionButton { width: row.cellWidth; glyph: 0xF033E; label: "Lock";     accent: "#7aa2f7"; onClicked: root.act("lock", false) }
        ActionButton { width: row.cellWidth; glyph: 0xF04B2; label: "Sleep";    accent: "#bb9af7"; onClicked: root.act("suspend", false) }
        ActionButton { width: row.cellWidth; glyph: 0xF0343; label: "Log out";  accent: "#e0af68"; armed: root.armed === "logout";   onClicked: root.act("logout", true) }
        ActionButton { width: row.cellWidth; glyph: 0xF0709; label: "Reboot";   accent: "#ff9e64"; armed: root.armed === "reboot";   onClicked: root.act("reboot", true) }
        ActionButton { width: row.cellWidth; glyph: 0xF0425; label: "Power";    accent: "#f7768e"; armed: root.armed === "shutdown"; onClicked: root.act("shutdown", true) }
    }
}
