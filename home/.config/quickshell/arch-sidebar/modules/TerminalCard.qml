import QtQuick
import Quickshell
import Quickshell.Io

// Default terminal (Settings → Terminal): Mod+Return, terminal apps from the launcher (htop, vim…),
// Thunar "Open Terminal Here", $TERMINAL and Lunaris's own windows. Through ~/.local/bin/dwm-term.
Rectangle {
    id: root
    width: 300
    height: col.implicitHeight + 28
    radius: 15
    color: "#24283b"

    property var terms: []            // installed: [{ name, label }]
    property string current: ""
    property bool busy: false

    function refresh() { if (!listP.running) listP.running = true }
    onVisibleChanged: if (visible) refresh()

    Process {
        id: listP
        running: true
        command: ["dwm-term", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const all = this.text.trim().split("\n").filter(l => l).map(l => {
                    const f = l.split("|"); return { name: f[0], installed: f[1] === "1", current: f[2] === "1", label: f[3] }
                })
                root.terms = all.filter(t => t.installed)
                const c = all.find(t => t.current); root.current = c ? c.name : ""
            }
        }
    }
    Process {
        id: setP
        onExited: { root.busy = false; root.refresh() }
    }

    Column {
        id: col
        x: 14; y: 14
        width: parent.width - 28
        spacing: 10

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            color: "#a9b1d6"; font.pixelSize: 11
            text: "Used by Mod+Return, terminal apps from the launcher (htop, vim…), Thunar's Open Terminal Here and Lunaris's own windows."
        }

        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: root.terms
                delegate: Rectangle {
                    readonly property bool on: modelData.name === root.current
                    width: tl.implicitWidth + 24; height: 32; radius: 8
                    color: on ? "#7aa2f7" : (tm.containsMouse ? "#2f3549" : "#1f2335")
                    border.width: 1
                    border.color: on || tm.containsMouse ? "#7aa2f7" : "#414868"
                    Text { id: tl; anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11; font.bold: parent.on; color: parent.on ? "#1a1b26" : "#a9b1d6" }
                    MouseArea {
                        id: tm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (!parent.on && !root.busy) {
                            root.busy = true; root.current = modelData.name
                            setP.command = ["dwm-term", "set", modelData.name]; setP.running = true
                        }
                    }
                }
            }
        }

        Row {
            spacing: 8
            BtButton { label: "Open a terminal"; height: 28; onClicked: Quickshell.execDetached(["dwm-term"]) }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.busy
                text: "applying…"; color: "#7aa2f7"; font.pixelSize: 10
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            color: "#565f89"; font.pixelSize: 9
            text: "Only installed terminals are listed — install another one (e.g. alacritty) and it appears here. The workspace rule follows your choice (dwm restarts in place). Live font changes work in kitty."
        }
    }
}
