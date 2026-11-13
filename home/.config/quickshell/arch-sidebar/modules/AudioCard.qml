import QtQuick

// Audio: output volume and microphone volume (PipeWire / wpctl, same as the bar and the volume keys).
// Device choice: right-click the volume / microphone item on the bar.
Item {
    id: root
    width: 300
    height: card.implicitHeight

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + 28
        radius: 15
        color: "#24283b"

        Column {
            id: col
            x: 14
            y: 14
            width: parent.width - 28
            spacing: 14

            VolumeRow {
                width: parent.width
                title: "Output"
                target: "@DEFAULT_AUDIO_SINK@"
                glyph: 0xF057E
                accent: "#7aa2f7"
            }

            Rectangle { width: parent.width; height: 1; color: "#414868" }

            VolumeRow {
                width: parent.width
                title: "Microphone"
                target: "@DEFAULT_AUDIO_SOURCE@"
                glyph: 0xF036C
                accent: "#bb9af7"
            }
        }
    }
}
