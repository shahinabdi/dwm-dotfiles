import QtQuick
import Quickshell
import Quickshell.Io

// one volume control (AudioCard): title + device name, percentage, mute, slider.
// target: a wpctl node, e.g. @DEFAULT_AUDIO_SINK@ (output) or @DEFAULT_AUDIO_SOURCE@ (microphone)
Column {
    id: row
    property string title: "Volume"
    property string target: "@DEFAULT_AUDIO_SINK@"
    property int glyph: 0xF057E
    property string accent: "#7aa2f7"

    property real volume: 0
    property bool muted: false
    property string device: ""
    property string error: ""
    property bool dragging: false

    spacing: 10

    function read() { if (!getP.running) getP.running = true; if (!devP.running) devP.running = true }
    function setVolume(v) {
        row.volume = Math.max(0, Math.min(100, v))
        setP.command = ["wpctl", "set-volume", "-l", "1.0", row.target, Math.round(row.volume) + "%"]
        if (!setP.running) setP.running = true; else setP.pending = true
    }
    function toggleMute() { row.muted = !row.muted; muteP.running = true }

    Process {
        id: getP
        command: ["wpctl", "get-volume", row.target]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/Volume:\s*([\d.]+)/)
                if (m) {
                    if (!row.dragging) row.volume = Math.min(100, Math.round(Number(m[1]) * 100))
                    row.muted = this.text.includes("[MUTED]")
                    row.error = ""
                } else row.error = "No " + row.title.toLowerCase() + " device"
            }
        }
    }
    Process {
        id: devP
        command: ["sh", "-c", "wpctl inspect " + row.target + " | sed -n 's/.*node.description = \"\\(.*\\)\"/\\1/p' | head -1"]
        stdout: StdioCollector { onStreamFinished: row.device = this.text.trim() }
    }
    Process {
        id: setP
        property bool pending: false
        // while dragging, apply the latest value once the previous call finished
        onExited: { if (pending) { pending = false; running = true } }
    }
    Process {
        id: muteP
        command: ["wpctl", "set-mute", row.target, "toggle"]
        onExited: row.read()
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: row.read() }
    Component.onCompleted: read()

    // header
    Item {
        width: parent.width
        height: 27
        Text {
            id: ic
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(row.muted ? (row.target.includes("SOURCE") ? 0xF036D : 0xF075F) : row.glyph)
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 16
            color: row.muted ? "#f7768e" : row.accent
        }
        Column {
            anchors.left: ic.right
            anchors.leftMargin: 8
            anchors.right: right.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            Text { text: row.title; color: "#c0caf5"; font.pixelSize: 14; font.bold: true }
            Text {
                visible: row.device.length > 0
                width: parent.width
                text: row.device
                color: "#565f89"; font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
        Row {
            id: right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: row.muted ? "Muted" : Math.round(row.volume) + "%"
                color: row.muted ? "#f7768e" : row.accent
                font.pixelSize: 11
            }
            Rectangle {
                width: 58; height: 27; radius: 8
                color: row.muted ? "#f7768e" : (mm.containsMouse ? "#565f89" : "#414868")
                Text {
                    anchors.centerIn: parent
                    text: row.muted ? "UNMUTE" : "MUTE"
                    color: row.muted ? "#1a1b26" : "#c0caf5"
                    font.pixelSize: 9; font.bold: true
                }
                MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: row.toggleMute() }
            }
        }
    }

    // slider
    Rectangle {
        id: track
        width: parent.width
        height: 9
        radius: 5
        color: "#414868"
        Rectangle {
            width: track.width * row.volume / 100
            height: parent.height
            radius: 5
            color: row.muted ? "#565f89" : row.accent
        }
        Rectangle {
            width: 17; height: 17; radius: 9
            color: "#c0caf5"
            x: Math.max(0, Math.min(track.width - width, track.width * row.volume / 100 - width / 2))
            anchors.verticalCenter: parent.verticalCenter
        }
        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -8
            anchors.bottomMargin: -8
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => { row.dragging = true; row.setVolume(mouse.x / width * 100) }
            onPositionChanged: mouse => { if (pressed) row.setVolume(mouse.x / width * 100) }
            onReleased: row.dragging = false
            onWheel: wheel => row.setVolume(row.volume + (wheel.angleDelta.y > 0 ? 5 : -5))
        }
    }

    Text {
        visible: row.error.length > 0
        width: parent.width
        text: row.error
        color: "#f7768e"; font.pixelSize: 9; wrapMode: Text.Wrap
    }
}
