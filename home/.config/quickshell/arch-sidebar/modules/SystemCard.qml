import QtQuick
import Quickshell
import Quickshell.Io

// System: CPU (with temperature), memory, disk usage, the busiest apps, and htop in one click.
// Data: ~/.local/bin/dwm-sysinfo, polled only while the sidebar is open.
Rectangle {
    id: root
    width: 300
    height: col.implicitHeight + 28
    radius: 15
    color: "#24283b"

    property bool active: true          // shell.qml: the sidebar is open
    property real cpu: -1               // %
    property var prevCpu: null          // [busy, total]
    property real memUsed: 0; property real memTotal: 0       // kB
    property real swapUsed: 0; property real swapTotal: 0     // kB
    property real diskUsed: 0; property real diskTotal: 0     // bytes
    property string temp: ""
    property string load: ""
    property int cores: 1
    property var busiest: []            // [{ name, cpu }]

    function gb(bytes) { return (bytes / 1073741824).toFixed(bytes >= 107374182400 ? 0 : 1) }
    function level(p) { return p >= 90 ? "#f7768e" : p >= 75 ? "#e0af68" : "" }
    function openHtop() { Quickshell.execDetached(["dwm-sysinfo", "htop"]) }

    Process {
        id: infoP
        command: ["dwm-sysinfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const tops = []
                for (const l of this.text.split("\n")) {
                    const i = l.indexOf("="); if (i < 0) continue
                    const k = l.slice(0, i), v = l.slice(i + 1), f = v.split(" ")
                    if (k === "cpu") {
                        const cur = [Number(f[0]), Number(f[1])]
                        if (root.prevCpu && cur[1] > root.prevCpu[1])
                            root.cpu = Math.max(0, Math.min(100, 100 * (cur[0] - root.prevCpu[0]) / (cur[1] - root.prevCpu[1])))
                        root.prevCpu = cur
                    }
                    else if (k === "mem") { root.memUsed = Number(f[0]); root.memTotal = Number(f[1]) }
                    else if (k === "swap") { root.swapUsed = Number(f[0]); root.swapTotal = Number(f[1]) }
                    else if (k === "disk") { root.diskUsed = Number(f[0]); root.diskTotal = Number(f[1]) }
                    else if (k === "temp") root.temp = v
                    else if (k === "load") root.load = v
                    else if (k === "cores") root.cores = Number(v) || 1
                    else if (k === "top") { const p = v.split("|"); tops.push({ name: p[0], cpu: Number(p[1]) }) }
                }
                root.busiest = tops
                // the first snapshot only gives a starting point for the CPU %: take a second one right away
                if (root.cpu < 0) again.start()
            }
        }
    }
    Timer { id: again; interval: 700; onTriggered: if (!infoP.running) infoP.running = true }
    Timer {
        interval: 3000; repeat: true; triggeredOnStart: true
        running: root.active && root.visible
        onTriggered: if (!infoP.running) infoP.running = true
    }

    Column {
        id: col
        x: 14; y: 14
        width: parent.width - 28
        spacing: 12

        // header: title · htop
        Item {
            width: parent.width
            height: 28
            Text { anchors.verticalCenter: parent.verticalCenter; text: "System"; color: "#c0caf5"; font.pixelSize: 16; font.bold: true }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: 72
                visible: root.load.length > 0
                text: "load " + root.load + " · " + root.cores + " cores"
                color: "#565f89"; font.pixelSize: 10
            }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: hr.implicitWidth + 18; height: 28; radius: 14
                color: hm.containsMouse ? "#89b4fa" : "#7aa2f7"
                Row {
                    id: hr
                    anchors.centerIn: parent
                    spacing: 5
                    Text { anchors.verticalCenter: parent.verticalCenter; text: String.fromCodePoint(0xF0128); color: "#1a1b26"; font.pixelSize: 14 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "htop"; color: "#1a1b26"; font.pixelSize: 11; font.bold: true }
                }
                MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openHtop() }
            }
        }

        Repeater {
            model: [
                { glyph: 0xF0EE0, name: "CPU", accent: "#7aa2f7",
                  pct: root.cpu < 0 ? 0 : root.cpu,
                  value: (root.cpu < 0 ? "…" : Math.round(root.cpu) + "%") + (root.temp ? "  ·  " + root.temp + "°C" : "") },
                { glyph: 0xF035B, name: "Memory", accent: "#bb9af7",
                  pct: root.memTotal ? 100 * root.memUsed / root.memTotal : 0,
                  value: root.gb(root.memUsed * 1024) + " / " + root.gb(root.memTotal * 1024) + " GB"
                         + (root.swapTotal ? "  ·  swap " + root.gb(root.swapUsed * 1024) + " GB" : "") },
                { glyph: 0xF02CA, name: "Disk  /", accent: "#9ece6a",
                  pct: root.diskTotal ? 100 * root.diskUsed / root.diskTotal : 0,
                  value: root.gb(root.diskUsed) + " / " + root.gb(root.diskTotal) + " GB" }
            ]
            delegate: Column {
                width: col.width
                spacing: 5
                Item {
                    width: parent.width
                    height: 18
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7
                        Text { anchors.verticalCenter: parent.verticalCenter; text: String.fromCodePoint(modelData.glyph); color: modelData.accent; font.pixelSize: 15 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: "#c0caf5"; font.pixelSize: 12; font.bold: true }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.value
                        color: root.level(modelData.pct) || "#a9b1d6"; font.pixelSize: 11
                    }
                }
                Rectangle {
                    width: parent.width; height: 6; radius: 3
                    color: "#1f2335"
                    Rectangle {
                        width: Math.max(parent.height, parent.width * Math.min(100, modelData.pct) / 100)
                        height: parent.height; radius: 3
                        color: root.level(modelData.pct) || modelData.accent
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        // busiest apps right now (top: % of one core)
        Text {
            visible: root.busiest.length > 0
            width: parent.width
            elide: Text.ElideRight
            color: "#565f89"; font.pixelSize: 10
            text: "Busiest: " + root.busiest.map(p => p.name + " " + Math.round(p.cpu) + "%").join("  ·  ")
        }
    }

    // a click anywhere on the card (outside the bars' text) also opens htop
    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openHtop()
    }
}
