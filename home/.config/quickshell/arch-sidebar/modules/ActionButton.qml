import QtQuick

// Small tile button: nerd-font icon + label. `armed` = waiting for a confirm click.
Rectangle {
    id: btn

    property int glyph: 0
    property string label: ""
    property color accent: "#7aa2f7"
    property bool armed: false
    property bool active: false
    property int iconSize: 20

    signal clicked()

    implicitHeight: 62
    radius: 12
    color: armed || active ? accent : (mouse.containsMouse ? "#2f3549" : "#1f2335")
    border.width: 1
    border.color: mouse.containsMouse || armed || active ? accent : "#414868"

    Behavior on color { ColorAnimation { duration: 120 } }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: btn.glyph !== 0
            text: btn.glyph !== 0 ? String.fromCodePoint(btn.glyph) : ""
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: btn.iconSize
            color: btn.armed || btn.active ? "#1a1b26" : btn.accent
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: btn.armed ? "Confirm?" : btn.label
            font.pixelSize: 10
            font.bold: btn.armed || btn.active
            color: btn.armed || btn.active ? "#1a1b26" : "#a9b1d6"
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
