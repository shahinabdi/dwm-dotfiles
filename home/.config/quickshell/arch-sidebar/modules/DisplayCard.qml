import QtQuick
import Quickshell
import Quickshell.Io

// Display settings as an accordion (like the Wi-Fi networks list):
// collapsed = one-line summary, expanded = screen scale, bar size, font size, resolution.
// Everything goes through ~/.local/bin/dwm-display.
Item {
    id: root

    width: 300
    height: card.height

    signal requestClose()

    property bool expanded: false
    property int scale: 100
    property real barScale: 1.0
    property int fontSize: 0
    property string resolution: ""
    readonly property var scales: [100, 125, 150, 175, 200]
    readonly property var barScales: [1.0, 1.15, 1.3, 1.5, 1.75]

    function refresh() { statusProcess.running = true }

    Process {
        id: statusProcess
        running: true
        command: ["dwm-display", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const kv of this.text.trim().split(" ")) {
                    const [k, v] = kv.split("=")
                    if (k === "scale") root.scale = Number(v)
                    else if (k === "bar") root.barScale = Number(v) || 1
                    else if (k === "font") root.fontSize = Number(v)
                    else if (k === "res") root.resolution = v
                }
            }
        }
    }

    Process {
        id: runProcess
        onExited: root.refresh()
    }

    function run(args) {
        runProcess.command = ["dwm-display"].concat(args)
        runProcess.running = true
    }

    Rectangle {
        id: card
        width: parent.width
        height: header.height + (root.expanded ? body.implicitHeight + 14 : 0) + 28
        radius: 15
        color: "#24283b"
        clip: true
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // ---------------------------------------------------------------- header (click to expand)
        Item {
            id: header
            x: 14
            y: 14
            width: parent.width - 28
            height: 40

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text { text: "Scale & size"; color: "#c0caf5"; font.pixelSize: 14; font.bold: true }
                Text {
                    text: root.scale + "%  ·  bar " + root.barScale.toFixed(2).replace(/\.?0+$/, "") + "×  ·  font "
                          + (root.fontSize || "–") + "  ·  " + (root.resolution || "…")
                    color: "#7aa2f7"
                    font.pixelSize: 11
                    width: header.width - 44
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: 8
                color: hm.containsMouse ? "#2f3549" : "#1f2335"
                border.width: 1
                border.color: "#414868"
                Text {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0xF0140)   // chevron-down
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 16
                    color: "#a9b1d6"
                    rotation: root.expanded ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
            }

            MouseArea {
                id: hm
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.expanded = !root.expanded; if (root.expanded) root.refresh() }
            }
        }

        // ---------------------------------------------------------------- body
        Column {
            id: body
            x: 14
            anchors.top: header.bottom
            anchors.topMargin: 14
            width: parent.width - 28
            spacing: 10
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Rectangle { width: parent.width; height: 1; color: "#414868" }

            RowTitle { title: "Screen scale"; value: root.scale + "%" }
            ChipRow {
                values: root.scales
                current: root.scale
                onPicked: v => { root.scale = v; root.run(["scale", String(v)]) }
            }
            Text { text: "Scales the whole screen instantly"; color: "#565f89"; font.pixelSize: 10 }

            RowTitle { title: "Bar size"; value: root.barScale.toFixed(2).replace(/\.?0+$/, "") + "×" }
            ChipRow {
                values: root.barScales
                current: root.barScale
                label: v => Math.round(v * 100) + "%"
                onPicked: v => { root.barScale = v; root.run(["bar", String(v)]) }
            }
            Text { text: "dwm bar text + icons (restarts dwm in place)"; color: "#565f89"; font.pixelSize: 10 }

            // font size
            Row {
                width: parent.width
                spacing: 8
                Text {
                    text: "Font size"
                    color: "#c0caf5"
                    font.pixelSize: 14
                    font.bold: true
                    width: parent.width - 3 * 34 - 2 * 8
                    anchors.verticalCenter: parent.verticalCenter
                }
                ActionButton {
                    width: 34; height: 30; implicitHeight: 30; radius: 8
                    glyph: 0xF0374; iconSize: 14; label: ""
                    onClicked: { root.fontSize -= 1; root.run(["font", "-"]) }
                }
                Text {
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.fontSize > 0 ? root.fontSize : "–"
                    color: "#7aa2f7"
                    font.pixelSize: 13
                    font.bold: true
                }
                ActionButton {
                    width: 34; height: 30; implicitHeight: 30; radius: 8
                    glyph: 0xF0415; iconSize: 14; label: ""
                    onClicked: { root.fontSize += 1; root.run(["font", "+"]) }
                }
            }

            // resolution
            Row {
                width: parent.width
                spacing: 8
                Column {
                    width: parent.width - resBtn.width - 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Resolution"; color: "#c0caf5"; font.pixelSize: 14; font.bold: true }
                    Text { text: root.resolution || "…"; color: "#7aa2f7"; font.pixelSize: 11 }
                }
                Rectangle {
                    id: resBtn
                    width: 86
                    height: 30
                    radius: 8
                    color: rm.containsMouse ? "#7aa2f7" : "#1f2335"
                    border.width: 1
                    border.color: "#7aa2f7"
                    Text {
                        anchors.centerIn: parent
                        text: "Change…"
                        font.pixelSize: 11
                        font.bold: true
                        color: rm.containsMouse ? "#1a1b26" : "#7aa2f7"
                    }
                    MouseArea {
                        id: rm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.requestClose()
                            Quickshell.execDetached(["sh", "-c", "sleep 0.2; dwm-display res-menu"])
                        }
                    }
                }
            }

            ResetButton {
                what: "display"
                onConfirmed: { root.run(["reset"]) }
            }
        }
    }

    // refresh after an external change (rofi menu, keybinding)
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
}
