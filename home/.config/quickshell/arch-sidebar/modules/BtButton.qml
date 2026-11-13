import QtQuick

// small outlined button (Bluetooth device rows)
Rectangle {
    property string label
    property string accent: "#7aa2f7"
    property string tip: ""
    signal clicked()
    width: Math.max(26, t.implicitWidth + 14)
    height: 24
    radius: 6
    color: m.containsMouse ? accent : "transparent"
    border.width: 1
    border.color: accent
    Text { id: t; anchors.centerIn: parent; text: parent.label; font.pixelSize: 10; font.bold: true; color: m.containsMouse ? "#1a1b26" : parent.accent }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
}
