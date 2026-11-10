import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    width: 300
    height: 90

    property real brightness: 50
    property real maxBrightness: 100
    property real currentBrightness: 50

    function readBrightness() {
        maxRead.running = true
    }

    Process {
        id: maxRead
        command: ["brightnessctl", "max"]

        stdout: StdioCollector {
            onStreamFinished: {
                let value = Number(this.text.trim())

                if (value > 0) {
                    root.maxBrightness = value
                    currentRead.running = true
                }
            }
        }
    }

    Process {
        id: currentRead
        command: ["brightnessctl", "get"]

        stdout: StdioCollector {
            onStreamFinished: {
                let value = Number(this.text.trim())

                if (root.maxBrightness > 0 && !isNaN(value)) {
                    root.currentBrightness = value
                    root.brightness = Math.round(
                        value / root.maxBrightness * 100
                    )
                }
            }
        }
    }

    Process {
        id: brightnessWrite
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.readBrightness()
    }

    Rectangle {
        anchors.fill: parent
        radius: 15
        color: "#24283b"

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Row {
                width: parent.width

                Text {
                    text: "Brightness"
                    color: "#c0caf5"
                    font.pixelSize: 14
                    font.bold: true
                    width: parent.width - brightnessPct.width
                }

                Text {
                    id: brightnessPct
                    text: Math.round(root.brightness) + "%"
                    color: "#7aa2f7"
                    font.pixelSize: 12
                }
            }

            Rectangle {
                id: track
                width: parent.width
                height: 9
                radius: 5
                color: "#414868"

                Rectangle {
                    width: track.width * root.brightness / 100
                    height: parent.height
                    radius: 5
                    color: "#e0af68"
                }

                Rectangle {
                    id: knob
                    width: 17
                    height: 17
                    radius: 9
                    color: "#c0caf5"

                    x: Math.max(
                        0,
                        Math.min(
                            track.width - width,
                            track.width * root.brightness / 100 - width / 2
                        )
                    )

                    anchors.verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    anchors.fill: parent

                    function updateValue(mouseX) {
                        let percentage = Math.max(
                            1,
                            Math.min(100, mouseX / width * 100)
                        )

                        root.brightness = percentage

                        brightnessWrite.command = [
                            "brightnessctl",
                            "set",
                            Math.round(percentage) + "%"
                        ]

                        brightnessWrite.running = true
                    }

                    onPressed: mouse => updateValue(mouse.x)

                    onPositionChanged: mouse => {
                        if (pressed)
                            updateValue(mouse.x)
                    }
                }
            }
        }
    }

    Component.onCompleted: readBrightness()
}
