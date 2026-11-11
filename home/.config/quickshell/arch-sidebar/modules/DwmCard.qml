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
    // keyboard profile (dwm-keyboard): which keys the workspace / screen shortcuts use
    property string kbProfile: ""
    property string kbLayouts: ""
    property string kbPending: ""      // picked but not applied yet (needs a rebuild)

    readonly property var kbInfo: ({
        "azerty": { label: "AZERTY", keys: "Workspaces  Super + & é \" ' ( - è _ ç à   ·   next screen  Super + ;", layouts: "fr,ir" },
        "qwerty": { label: "QWERTY", keys: "Workspaces  Super + 1 … 9 0   ·   next screen  Super + .", layouts: "us,ir" }
    })

    function refresh() { pathProcess.running = true; kbProcess.running = true }

    Process {
        id: kbProcess
        running: true
        command: ["sh", "-c", "dwm-keyboard get profile; dwm-keyboard get layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim().split("\n")
                root.kbProfile = l[0] || "azerty"
                root.kbLayouts = l[1] || ""
                if (root.kbPending === root.kbProfile) root.kbPending = ""
            }
        }
    }

    // read the saved folder without prompting
    Process {
        id: pathProcess
        running: true
        command: ["sh", "-c", ". \"$HOME/.config/dwm-dev.conf\" 2>/dev/null; echo \"$DWM_DIR\""]
        stdout: StdioCollector {
            onStreamFinished: root.dwmDir = this.text.trim()
        }
    }

    function run2(cmd) {   // any command, after the sidebar closed
        root.requestClose()
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; " + cmd])
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

        // ---- keyboard profile
        Item { width: 1; height: 4 }
        RowTitle { title: "Keyboard"; value: root.kbProfile ? root.kbInfo[root.kbProfile].label + "  ·  " + root.kbLayouts : "" }
        ChipRow {
            values: ["azerty", "qwerty"]
            current: root.kbPending || root.kbProfile
            label: v => v === "azerty" ? "AZERTY  (fr)" : "QWERTY  (us)"
            onPicked: v => root.kbPending = (v === root.kbProfile ? "" : v)
        }
        Text {
            width: parent.width
            text: root.kbInfo[root.kbPending || root.kbProfile || "azerty"].keys
            color: "#565f89"
            font.pixelSize: 10
            wrapMode: Text.WordWrap
        }

        // confirm: only shown after picking the other profile
        Rectangle {
            visible: root.kbPending !== ""
            width: parent.width
            height: visible ? confirmCol.implicitHeight + 16 : 0
            radius: 10
            color: "#1f2335"
            border.width: 1
            border.color: "#e0af68"

            Column {
                id: confirmCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Text {
                    width: parent.width
                    text: root.kbPending ? "Switch to " + root.kbInfo[root.kbPending].label + " (layouts "
                          + root.kbInfo[root.kbPending].layouts + ")? dwm is rebuilt in a terminal (asks for sudo) and restarts in place — windows stay open." : ""
                    color: "#c0caf5"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Row {
                    id: cbtns
                    width: parent.width
                    spacing: 6
                    readonly property real cellWidth: (width - spacing) / 2
                    ActionButton {
                        width: cbtns.cellWidth; glyph: 0xF0AA8; label: "Apply"; accent: "#9ece6a"
                        onClicked: { const p = root.kbPending; root.kbPending = ""; root.run2("dwm-keyboard set " + p) }
                    }
                    ActionButton {
                        width: cbtns.cellWidth; glyph: 0xF0156; label: "Cancel"; accent: "#f7768e"
                        onClicked: root.kbPending = ""
                    }
                }
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
}
