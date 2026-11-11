import QtQuick

Row {
    id: chipRow
    property var values: []
    property var current
    property var label: v => String(v)
    signal picked(var v)
    width: parent.width
    spacing: 6

    Repeater {
        model: chipRow.values
        Rectangle {
            required property var modelData
            readonly property bool on: String(chipRow.current) === String(modelData) || Math.abs(Number(chipRow.current) - Number(modelData)) < 0.001
            width: (chipRow.width - chipRow.spacing * (chipRow.values.length - 1)) / chipRow.values.length
            height: 30
            radius: 8
            color: on ? "#7aa2f7" : (m.containsMouse ? "#2f3549" : "#1f2335")
            border.width: 1
            border.color: on || m.containsMouse ? "#7aa2f7" : "#414868"
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                anchors.centerIn: parent
                text: chipRow.label(modelData)
                font.pixelSize: 11
                font.bold: parent.on
                color: parent.on ? "#1a1b26" : "#a9b1d6"
            }
            MouseArea {
                id: m
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: chipRow.picked(modelData)
            }
        }
    }
}
