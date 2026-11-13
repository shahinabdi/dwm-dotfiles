import QtQuick

// "Silent" switch for notifications (no pop-ups, still saved).
Rectangle {
    id: chip
    property var store
    width: silRow.implicitWidth + 18
    height: 28
    radius: 14
    color: store.silent ? "#bb9af7" : (sm.containsMouse ? "#565f89" : "#414868")
    Row {
        id: silRow
        anchors.centerIn: parent
        spacing: 5
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(chip.store.silent ? 0xF009B : 0xF009A)
            color: chip.store.silent ? "#1a1b26" : "#c0caf5"; font.pixelSize: 14
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Silent"
            color: chip.store.silent ? "#1a1b26" : "#c0caf5"; font.pixelSize: 11; font.bold: true
        }
    }
    MouseArea {
        id: sm
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.store.setSilent(!chip.store.silent)
    }
}
