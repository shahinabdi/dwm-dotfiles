import QtQuick

// "Reset to defaults" — needs a second click within 3 s (like the power buttons)
Rectangle {
    id: btn
    property string what: "defaults"
    property bool armed: false
    signal confirmed()

    width: parent ? parent.width : 200
    height: 32
    radius: 9
    color: armed ? "#e0af68" : (m.containsMouse ? "#2f3549" : "transparent")
    border.width: 1
    border.color: armed ? "#e0af68" : "#414868"
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        anchors.centerIn: parent
        spacing: 8
        Text {
            text: String.fromCodePoint(0xF0453)   // restore arrow
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 14
            color: btn.armed ? "#1a1b26" : "#a9b1d6"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: btn.armed ? "Click again to reset " + btn.what : "Reset " + btn.what + " to defaults"
            font.pixelSize: 11
            font.bold: btn.armed
            color: btn.armed ? "#1a1b26" : "#a9b1d6"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Timer { id: disarm; interval: 3000; onTriggered: btn.armed = false }

    MouseArea {
        id: m
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (btn.armed) { btn.armed = false; disarm.stop(); btn.confirmed() }
            else { btn.armed = true; disarm.restart() }
        }
    }
}
