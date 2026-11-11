import QtQuick

// ON / OFF pill (same look as the Wi-Fi and Bluetooth switches)
Rectangle {
    id: sw
    property bool on: false
    signal toggled()
    width: 58
    height: 28
    radius: 14
    color: on ? "#7aa2f7" : "#414868"
    Behavior on color { ColorAnimation { duration: 120 } }
    Text {
        anchors.centerIn: parent
        text: sw.on ? "ON" : "OFF"
        color: "#1a1b26"
        font.bold: true
        font.pixelSize: 11
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled()
    }
}
