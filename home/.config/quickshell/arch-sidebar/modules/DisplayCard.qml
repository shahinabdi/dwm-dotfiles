import QtQuick
import Quickshell
import Quickshell.Io

// Scale (Xft.dpi), font size and resolution — all through ~/.local/bin/dwm-display.
Item {
    id: root

    width: 300
    height: card.implicitHeight

    signal requestClose()

    property int scale: 100
    property int fontSize: 0
    property string resolution: ""
    readonly property var scales: [100, 125, 150, 175, 200]

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
        implicitHeight: content.implicitHeight + 28
        radius: 15
        color: "#24283b"

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12

            // ---- scale ----
            Row {
                width: parent.width
                Text { text: "Scale"; color: "#c0caf5"; font.pixelSize: 14; font.bold: true; width: parent.width - pct.width }
                Text { id: pct; text: root.scale + "%"; color: "#7aa2f7"; font.pixelSize: 12 }
            }

            Row {
                width: parent.width
                spacing: 6
                Repeater {
                    model: root.scales
                    Rectangle {
                        required property int modelData
                        width: (parent.width - 6 * (root.scales.length - 1)) / root.scales.length
                        height: 30
                        radius: 8
                        color: root.scale === modelData ? "#7aa2f7" : (m.containsMouse ? "#2f3549" : "#1f2335")
                        border.width: 1
                        border.color: root.scale === modelData || m.containsMouse ? "#7aa2f7" : "#414868"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 11
                            font.bold: root.scale === modelData
                            color: root.scale === modelData ? "#1a1b26" : "#a9b1d6"
                        }
                        MouseArea {
                            id: m
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.scale = modelData; root.run(["scale", String(modelData)]) }
                        }
                    }
                }
            }

            Text {
                text: "Scales the whole screen instantly"
                color: "#565f89"
                font.pixelSize: 10
            }

            // ---- font size ----
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

            // ---- resolution ----
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
        }
    }

    // refresh after an external change (rofi menu, keybinding)
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
}
