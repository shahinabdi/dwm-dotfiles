import QtQuick
import Quickshell
import Quickshell.Io

// Bluetooth: power, connected devices, and an expandable list (my devices + nearby).
// Everything goes through ~/.local/bin/dwm-bt (bluetoothctl).
Item {
    id: root
    width: 300
    height: card.implicitHeight

    property bool powered: false
    property bool scanning: false
    property bool expanded: false
    property var devices: []          // [{ mac, name, paired, connected, icon, battery }]
    property var busy: ({})           // mac -> "connecting" | "disconnecting" | "pairing" | "forgetting"
    property string statusText: ""

    readonly property var paired: devices.filter(d => d.paired)
    readonly property var nearby: devices.filter(d => !d.paired)
    readonly property var connected: devices.filter(d => d.connected)

    function refresh() { if (!statusP.running) statusP.running = true }
    function scan() {
        if (!root.powered || scanP.running) return
        root.scanning = true
        root.statusText = "Searching for devices… put yours in pairing mode"
        scanP.running = true
    }
    function act(cmd, mac, label) {
        const b = Object.assign({}, root.busy); b[mac] = label; root.busy = b
        const p = actionComp.createObject(root, { command: ["dwm-bt", cmd, mac], mac: mac })
        p.running = true
    }
    function glyph(icon) {
        if (/headset|headphone/.test(icon)) return 0xF02CB
        if (/audio/.test(icon)) return 0xF04C3
        if (/mouse/.test(icon)) return 0xF037D
        if (/keyboard/.test(icon)) return 0xF030C
        if (/phone/.test(icon)) return 0xF03F2
        if (/computer/.test(icon)) return 0xF0379
        if (/gaming|joystick/.test(icon)) return 0xF02B4
        return 0xF00AF
    }

    Process {
        id: statusP
        running: true
        command: ["dwm-bt", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = []
                for (const l of this.text.split("\n")) {
                    if (l === "power=1") root.powered = true
                    else if (l === "power=0") root.powered = false
                    else if (l.startsWith("scanning=")) { if (!scanP.running) root.scanning = l.endsWith("1") }
                    else if (l.startsWith("dev|")) {
                        const f = l.split("|")
                        list.push({ mac: f[1], name: f[2], paired: f[3] === "1", connected: f[4] === "1", icon: f[5], battery: f[6] || "" })
                    }
                }
                // connected first, then by name
                list.sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
                root.devices = list
            }
        }
    }
    Process {
        id: scanP
        command: ["dwm-bt", "scan", "12"]
        onExited: { root.scanning = false; root.statusText = root.nearby.length ? "" : "No new devices found"; root.refresh() }
    }
    Process {
        id: powerP
        onExited: root.refresh()
    }
    Component {
        id: actionComp
        Process {
            property string mac
            onExited: { const b = Object.assign({}, root.busy); delete b[mac]; root.busy = b; root.refresh(); destroy() }
        }
    }

    // scanning: refresh often so devices appear as they are found
    Timer { interval: root.scanning ? 2000 : (root.expanded ? 5000 : 8000); running: true; repeat: true; onTriggered: root.refresh() }

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
            x: 14
            y: 14
            width: parent.width - 28
            spacing: 10

            // header: title + power (same layout as the Wi-Fi card)
            Row {
                width: parent.width
                height: 28
                spacing: 10
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bluetooth"
                    color: "#c0caf5"
                    font.pixelSize: 16
                    font.bold: true
                }
                Item { width: 1; height: 1 }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 58; height: 28; radius: 14
                    color: root.powered ? "#7aa2f7" : "#414868"
                    Text { anchors.centerIn: parent; text: root.powered ? "ON" : "OFF"; color: "#1a1b26"; font.bold: true; font.pixelSize: 11 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerP.command = ["dwm-bt", "power", root.powered ? "off" : "on"]
                            root.powered = !root.powered
                            powerP.running = true
                        }
                    }
                }
            }

            // summary: what is connected
            Text {
                width: parent.width
                text: !root.powered ? "Bluetooth is off"
                    : root.connected.length ? "Connected: " + root.connected.map(d => d.name + (d.battery ? " (" + d.battery + "%)" : "")).join(", ")
                    : "No device connected"
                color: root.connected.length ? "#9ece6a" : "#a9b1d6"
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Rectangle { width: parent.width; height: 1; color: "#414868"; visible: root.powered }

            // buttons: devices list + search
            Row {
                visible: root.powered
                width: parent.width
                spacing: 8
                Rectangle {
                    width: parent.width - 48
                    height: 34
                    radius: 9
                    color: dm.containsMouse ? "#565f89" : "#414868"
                    Text {
                        anchors.centerIn: parent
                        text: root.expanded ? "Hide devices" : "Devices" + (root.paired.length ? "  (" + root.paired.length + " paired)" : "")
                        color: "#c0caf5"; font.pixelSize: 11; font.bold: true
                    }
                    MouseArea {
                        id: dm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.expanded = !root.expanded; if (root.expanded) root.refresh() }
                    }
                }
                Rectangle {
                    width: 40; height: 34; radius: 9
                    color: sm.containsMouse ? "#565f89" : "#414868"
                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        color: root.scanning ? "#e0af68" : "#7aa2f7"
                        font.pixelSize: 20
                        RotationAnimation on rotation { running: root.scanning; from: 0; to: 360; duration: 1200; loops: Animation.Infinite; alwaysRunToEnd: true }
                    }
                    MouseArea {
                        id: sm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.expanded = true; root.scan() }
                    }
                }
            }

            // ----- expanded list
            Column {
                visible: root.powered && root.expanded
                width: parent.width
                spacing: 6

                Text {
                    visible: text.length > 0
                    width: parent.width
                    text: root.scanning ? "Searching for devices… put yours in pairing mode" : root.statusText
                    color: "#7aa2f7"
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }

                Text { text: "MY DEVICES"; color: "#565f89"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                Text {
                    visible: root.paired.length === 0
                    width: parent.width
                    text: "No paired devices yet. Press ↻ to search, then Pair."
                    color: "#565f89"; font.pixelSize: 10; wrapMode: Text.WordWrap
                }
                Repeater {
                    model: root.paired
                    delegate: BtDeviceRow { card: root }
                }

                Item { width: 1; height: 4 }
                Text {
                    text: "NEARBY" + (root.scanning ? "  ·  searching" : "")
                    color: "#565f89"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
                }
                Text {
                    visible: root.nearby.length === 0
                    width: parent.width
                    text: root.scanning ? "…" : "Press ↻ to search for new devices."
                    color: "#565f89"; font.pixelSize: 10; wrapMode: Text.WordWrap
                }
                // nearby can be long (lamps, TVs…): scroll inside
                Flickable {
                    visible: root.nearby.length > 0
                    width: parent.width
                    height: Math.min(nearCol.implicitHeight, 5 * 40)
                    contentHeight: nearCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: nearCol
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: root.nearby
                            delegate: BtDeviceRow { card: root }
                        }
                    }
                }
                Text {
                    width: parent.width
                    text: "Keyboards that ask for a PIN: pair them with bluetoothctl in a terminal."
                    color: "#565f89"; font.pixelSize: 9; wrapMode: Text.WordWrap
                }
            }
        }
    }
}
