import QtQuick
import Quickshell
import Quickshell.Io

// Monitors (Settings page): arrangement map, per-screen on/off, resolution, position,
// primary; automatic switching on hotplug, detect now, saved layouts (autorandr).
// Everything goes through ~/.local/bin/dwm-monitor.
Item {
    id: root

    width: 300
    height: col.implicitHeight

    signal requestClose()

    property var outs: []       // [{ name, on, primary, mode, rate, x, y, modes, model }]
    property var profiles: []   // [{ name, state }]
    property bool auto: true

    function refresh() { listP.running = true; profP.running = true; autoP.running = true }
    Component.onCompleted: refresh()
    onVisibleChanged: if (visible) refresh()

    Process {
        id: listP
        command: ["dwm-monitor", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = []
                for (const l of this.text.split("\n")) {
                    const f = l.split("|")
                    if (f.length < 9) continue
                    o.push({ name: f[0], on: f[1] === "1", primary: f[2] === "1", mode: f[3], rate: f[4],
                             x: Number(f[5]), y: Number(f[6]), modes: f[7].split(",").filter(m => m), model: f[8] })
                }
                root.outs = o
            }
        }
    }
    Process {
        id: profP
        command: ["dwm-monitor", "profiles"]
        stdout: StdioCollector {
            onStreamFinished: root.profiles = this.text.split("\n").filter(l => l).map(l => {
                const f = l.split("|"); return { name: f[0], state: f[1] || "" } })
        }
    }
    Process {
        id: autoP
        command: ["dwm-monitor", "auto", "status"]
        stdout: StdioCollector { onStreamFinished: root.auto = this.text.trim() !== "off" }
    }

    Timer { id: refreshSoon; interval: 1200; onTriggered: root.refresh() }
    Timer { interval: 4000; running: root.visible; repeat: true; onTriggered: root.refresh() }

    function mon(args, close) {
        if (close) root.requestClose()
        Quickshell.execDetached(close ? ["sh", "-c", "sleep 0.3; dwm-monitor " + args.join(" ")]
                                      : ["dwm-monitor"].concat(args))
        refreshSoon.restart()
    }
    function wh(m) { const p = (m || "0x0").split("x"); return [Number(p[0]) || 0, Number(p[1]) || 0] }

    Column {
        id: col
        width: parent.width
        spacing: 10

        // ---------------------------------------------------------------- arrangement map
        Rectangle {
            id: map
            width: parent.width
            height: 120
            radius: 12
            color: "#16161e"
            border.width: 1
            border.color: "#414868"

            readonly property var active: root.outs.filter(o => o.on && o.mode !== "-")
            readonly property real minX: Math.min(...active.map(o => o.x), 0)
            readonly property real minY: Math.min(...active.map(o => o.y), 0)
            readonly property real maxX: Math.max(...active.map(o => o.x + root.wh(o.mode)[0]), 1)
            readonly property real maxY: Math.max(...active.map(o => o.y + root.wh(o.mode)[1]), 1)
            readonly property real k: Math.min((width - 24) / (maxX - minX), (height - 24) / (maxY - minY))
            readonly property real ox: (width - (maxX - minX) * k) / 2
            readonly property real oy: (height - (maxY - minY) * k) / 2

            Repeater {
                model: map.active
                Rectangle {
                    required property var modelData
                    x: map.ox + (modelData.x - map.minX) * map.k
                    y: map.oy + (modelData.y - map.minY) * map.k
                    width: root.wh(modelData.mode)[0] * map.k - 3
                    height: root.wh(modelData.mode)[1] * map.k - 3
                    radius: 5
                    color: modelData.primary ? "#2f3f6b" : "#24283b"
                    border.width: modelData.primary ? 2 : 1
                    border.color: modelData.primary ? "#7aa2f7" : "#565f89"
                    Column {
                        anchors.centerIn: parent
                        spacing: 1
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: "#c0caf5"; font.pixelSize: 10; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.mode; color: "#a9b1d6"; font.pixelSize: 9 }
                    }
                }
            }
            Text {
                visible: map.active.length === 0
                anchors.centerIn: parent
                text: "…"
                color: "#565f89"
            }
        }

        // ---------------------------------------------------------------- automatic + actions
        Row {
            width: parent.width
            spacing: 8
            Column {
                width: parent.width - 58 - 8
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "Automatic"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true }
                Text {
                    width: parent.width
                    text: "plug in a screen: saved layout, or side by side"
                    color: "#565f89"; font.pixelSize: 9; elide: Text.ElideRight
                }
            }
            Switch2 { on: root.auto; onToggled: { root.auto = !root.auto; root.mon(["auto", root.auto ? "on" : "off"]) } }
        }

        Row {
            id: acts
            width: parent.width
            spacing: 6
            readonly property real cellWidth: (width - spacing) / 2
            ActionButton { width: acts.cellWidth; implicitHeight: 52; glyph: 0xF0379; label: "Detect now"; onClicked: root.mon(["detect"]) }
            ActionButton { width: acts.cellWidth; implicitHeight: 52; glyph: 0xF0193; label: "Save layout…"; accent: "#9ece6a"; onClicked: root.mon(["save"], true) }
        }

        // ---------------------------------------------------------------- one card per connected screen
        Repeater {
            model: root.outs
            Rectangle {
                id: mc
                required property var modelData
                width: col.width
                height: mcol.implicitHeight + 24
                radius: 12
                color: "#1f2335"
                border.width: 1
                border.color: modelData.primary ? "#7aa2f7" : "#414868"

                Column {
                    id: mcol
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 8

                    Row {
                        width: parent.width
                        spacing: 10
                        Text {
                            text: String.fromCodePoint(mc.modelData.name.startsWith("eDP") ? 0xF0322 : 0xF0379)  // laptop / monitor
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 20
                            color: mc.modelData.on ? "#7aa2f7" : "#565f89"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            width: parent.width - 30 - 58 - 20
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                width: parent.width
                                text: mc.modelData.model
                                color: "#c0caf5"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: mc.modelData.name + (mc.modelData.on ? "  ·  " + mc.modelData.mode + " @ " + mc.modelData.rate + " Hz" : "  ·  off")
                                      + (mc.modelData.primary ? "  ·  primary" : "")
                                color: mc.modelData.primary ? "#7aa2f7" : "#565f89"; font.pixelSize: 10; elide: Text.ElideRight
                            }
                        }
                        Switch2 {
                            anchors.verticalCenter: parent.verticalCenter
                            on: mc.modelData.on
                            onToggled: root.mon([mc.modelData.on ? "off" : "on", mc.modelData.name])
                        }
                    }

                    // resolution
                    ChipRow {
                        visible: mc.modelData.on
                        values: mc.modelData.modes.slice(0, 4)
                        current: mc.modelData.mode
                        label: v => v
                        onPicked: v => root.mon(["mode", mc.modelData.name, v])
                    }

                    // position relative to the primary
                    ChipRow {
                        visible: mc.modelData.on && !mc.modelData.primary
                        values: ["left", "right", "above", "below", "mirror"]
                        current: ""
                        label: v => v
                        onPicked: v => root.mon(["place", mc.modelData.name, v])
                    }

                    Rectangle {
                        visible: mc.modelData.on && !mc.modelData.primary
                        width: parent.width
                        height: 28
                        radius: 8
                        color: pm.containsMouse ? "#2f3549" : "transparent"
                        border.width: 1
                        border.color: "#414868"
                        Text { anchors.centerIn: parent; text: "Make primary (bar status · sidebar)"; color: "#a9b1d6"; font.pixelSize: 10 }
                        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.mon(["primary", mc.modelData.name]) }
                    }
                }
            }
        }

        // ---------------------------------------------------------------- saved layouts
        Text {
            visible: root.profiles.length > 0
            text: "Saved layouts"
            color: "#c0caf5"; font.pixelSize: 13; font.bold: true
        }
        Repeater {
            model: root.profiles
            Rectangle {
                required property var modelData
                width: col.width
                height: 36
                radius: 9
                color: "#1f2335"
                border.width: 1
                border.color: modelData.state === "current" ? "#7aa2f7" : "#414868"
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name + (modelData.state ? "  ·  " + modelData.state : "")
                    color: modelData.state === "current" ? "#7aa2f7" : "#c0caf5"
                    font.pixelSize: 12
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Rectangle {
                        width: 54; height: 24; radius: 7
                        color: am.containsMouse ? "#7aa2f7" : "#24283b"
                        Text { anchors.centerIn: parent; text: "Apply"; font.pixelSize: 10; font.bold: true; color: am.containsMouse ? "#1a1b26" : "#7aa2f7" }
                        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.mon(["load", modelData.name]) }
                    }
                    Rectangle {
                        width: 24; height: 24; radius: 7
                        color: dm.containsMouse ? "#f7768e" : "#24283b"
                        Text { anchors.centerIn: parent; text: String.fromCodePoint(0xF01B4); font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 12; color: dm.containsMouse ? "#1a1b26" : "#f7768e" }
                        MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.mon(["delete", modelData.name]) }
                    }
                }
            }
        }
        Text {
            width: parent.width
            text: "Save a layout once for each setup (laptop only, desk, TV…). When the same screens are plugged in again it is applied automatically."
            color: "#565f89"; font.pixelSize: 10; wrapMode: Text.WordWrap
        }
    }
}
