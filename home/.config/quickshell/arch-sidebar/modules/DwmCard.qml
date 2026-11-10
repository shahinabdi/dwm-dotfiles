import QtQuick
import Quickshell
import Quickshell.Io

// dwm tools -> ~/.local/bin/dwm-dev : restart in place, rebuild, edit config, source folder.
Item {
    id: root

    width: 300
    height: col.implicitHeight

    signal requestClose()

    property string dwmDir: ""

    function refresh() { pathProcess.running = true }

    // read the saved folder without prompting
    Process {
        id: pathProcess
        running: true
        command: ["sh", "-c", ". \"$HOME/.config/dwm-dev.conf\" 2>/dev/null; echo \"$DWM_DIR\""]
        stdout: StdioCollector {
            onStreamFinished: root.dwmDir = this.text.trim()
        }
    }

    function run(args) {
        root.requestClose()
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; dwm-dev " + args])
    }

    Column {
        id: col
        width: parent.width
        spacing: 8

        // folder row (click to change)
        Rectangle {
            width: parent.width
            height: 40
            radius: 12
            color: pm.containsMouse ? "#2f3549" : "#1f2335"
            border.width: 1
            border.color: pm.containsMouse ? "#7aa2f7" : "#414868"

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: String.fromCodePoint(0xF024B)
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 16
                    color: "#7aa2f7"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 80
                    text: root.dwmDir ? root.dwmDir.replace(/^\/home\/[^\/]+/, "~") : "Set dwm source folder…"
                    color: root.dwmDir ? "#c0caf5" : "#e0af68"
                    font.pixelSize: 12
                    elide: Text.ElideMiddle
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "change"
                    color: "#565f89"
                    font.pixelSize: 10
                }
            }

            MouseArea {
                id: pm
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.run("set-path")
            }
        }

        Row {
            id: btns
            width: parent.width
            spacing: 6

            readonly property real cellWidth: (width - 3 * spacing) / 4

            ActionButton { width: btns.cellWidth; glyph: 0xF0453; label: "Restart"; onClicked: root.run("restart") }
            ActionButton { width: btns.cellWidth; glyph: 0xF0AA8; label: "Rebuild"; accent: "#9ece6a"; onClicked: root.run("build") }
            ActionButton { width: btns.cellWidth; glyph: 0xF03EB; label: "Edit";    accent: "#e0af68"; onClicked: root.run("edit") }
            ActionButton { width: btns.cellWidth; glyph: 0xF0770; label: "Folder";  accent: "#bb9af7"; onClicked: root.run("folder") }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
}
