import QtQuick
import Quickshell
import Quickshell.Io

// Notifications: everything dunst showed (or kept quiet in silent mode), saved until you delete it.
// Data and actions: ~/.local/bin/dwm-notif (also the cat on the bar).
Item {
    id: root
    width: 300
    height: card.implicitHeight

    property var items: []
    property bool silent: false
    property bool confirmClear: false
    property real now: Date.now() / 1000

    function refresh() { if (!listP.running) listP.running = true; if (!statP.running) statP.running = true }
    function remove(id) {
        root.items = root.items.filter(n => n.id !== id)          // instant, then saved
        Quickshell.execDetached(["dwm-notif", "rm", id])
    }
    function clearAll() {
        root.items = []; root.confirmClear = false
        Quickshell.execDetached(["dwm-notif", "clear"])
    }
    function setSilent(on) {
        root.silent = on
        Quickshell.execDetached(["dwm-notif", "silent", on ? "on" : "off"])
    }
    function ago(t) {
        const s = Math.max(0, root.now - t)
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + " min ago"
        if (s < 86400) return Math.floor(s / 3600) + " h ago"
        const d = new Date(t * 1000)
        return s < 7 * 86400 ? d.toLocaleDateString(Qt.locale("en_GB"), "ddd HH:mm")
                             : d.toLocaleDateString(Qt.locale("en_GB"), "d MMM yyyy")
    }
    function glyph(n) {
        const t = (n.app + " " + n.summary).toLowerCase()
        if (n.urgency === "critical" && /battery/.test(t)) return 0xF0083
        if (/battery/.test(t)) return 0xF0079
        if (/bluetooth/.test(t)) return 0xF00AF
        if (/wi-?fi|network/.test(t)) return 0xF05A9
        if (/screenshot/.test(t)) return 0xF0104
        if (/download/.test(t)) return 0xF01DA
        if (/mail/.test(t)) return 0xF01EE
        if (/firefox|chrom|brave|browser/.test(t)) return 0xF059F
        if (/discord|telegram|signal|message|chat/.test(t)) return 0xF0369
        if (/update|pacman|yay/.test(t)) return 0xF06B0
        return 0xF009A
    }

    Process {
        id: listP
        running: true
        command: ["dwm-notif", "list"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.items = JSON.parse(this.text) } catch (e) {} }
        }
    }
    Process {
        id: statP
        running: true
        command: ["dwm-notif", "status"]
        stdout: StdioCollector { onStreamFinished: root.silent = this.text.indexOf("silent=1") >= 0 }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: { root.now = Date.now() / 1000; root.refresh() } }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + 28
        radius: 15
        color: "#24283b"
        border.width: 1
        border.color: "#414868"

        Column {
            id: col
            x: 14; y: 14
            width: parent.width - 28
            spacing: 10

            // header: cat + title + count · silent switch
            Item {
                width: parent.width
                height: 28
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF011B)
                        color: "#bb9af7"; font.pixelSize: 20
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: "#c0caf5"; font.pixelSize: 16; font.bold: true
                    }
                    Rectangle {
                        visible: root.items.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: cnt.implicitWidth + 12; height: 18; radius: 9
                        color: "#414868"
                        Text { id: cnt; anchors.centerIn: parent; text: root.items.length; color: "#c0caf5"; font.pixelSize: 10; font.bold: true }
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: silRow.implicitWidth + 18; height: 28; radius: 14
                    color: root.silent ? "#bb9af7" : (sm.containsMouse ? "#565f89" : "#414868")
                    Row {
                        id: silRow
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: String.fromCodePoint(root.silent ? 0xF009B : 0xF009A)
                            color: root.silent ? "#1a1b26" : "#c0caf5"; font.pixelSize: 14
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Silent"
                            color: root.silent ? "#1a1b26" : "#c0caf5"; font.pixelSize: 11; font.bold: true
                        }
                    }
                    MouseArea {
                        id: sm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setSilent(!root.silent)
                    }
                }
            }

            Text {
                visible: root.silent
                width: parent.width
                text: "Silent: no pop-ups, everything is still saved here. Critical alerts (low battery) still show."
                color: "#bb9af7"; font.pixelSize: 10; wrapMode: Text.WordWrap
            }

            // empty state
            Column {
                visible: root.items.length === 0
                width: parent.width
                spacing: 4
                topPadding: 6; bottomPadding: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: String.fromCodePoint(0xF011B)
                    color: "#414868"; font.pixelSize: 34
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No notifications"
                    color: "#565f89"; font.pixelSize: 11
                }
            }

            // list (newest first), scrolls inside after ~4 items
            Flickable {
                visible: root.items.length > 0
                width: parent.width
                height: Math.min(listCol.implicitHeight, 290)
                contentHeight: listCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: listCol
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: root.items
                        delegate: NotifRow { card: root }
                    }
                }
            }

            // clear all (asks once)
            Rectangle {
                visible: root.items.length > 0
                width: parent.width
                height: 32; radius: 9
                color: root.confirmClear ? "#f7768e" : (cm.containsMouse ? "#565f89" : "#414868")
                Text {
                    anchors.centerIn: parent
                    text: root.confirmClear ? "Click again to delete all " + root.items.length : "Clear all"
                    color: root.confirmClear ? "#1a1b26" : "#c0caf5"; font.pixelSize: 11; font.bold: true
                }
                MouseArea {
                    id: cm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.confirmClear ? root.clearAll() : (root.confirmClear = true, confirmT.restart())
                    onExited: root.confirmClear = false
                }
                Timer { id: confirmT; interval: 3000; onTriggered: root.confirmClear = false }
            }
        }
    }
}
