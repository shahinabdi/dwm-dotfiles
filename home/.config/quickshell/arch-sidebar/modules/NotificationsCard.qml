import QtQuick

// Notifications on the main sidebar: the 3 newest + "See all" (opens NotificationsPage).
Item {
    id: root
    width: 300
    height: card.implicitHeight

    property var store
    signal openPage()

    readonly property var latest: store.items.slice(0, 3)

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
            x: 14; y: 14
            width: parent.width - 28
            spacing: 10

            // header: cat + title + unread · silent
            Item {
                width: parent.width
                height: 28
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF011B)
                        color: "#bb9af7"; font.pixelSize: 20
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: "#c0caf5"; font.pixelSize: 16; font.bold: true
                    }
                    Rectangle {
                        visible: root.store.unread > 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: cnt.implicitWidth + 12; height: 18; radius: 9
                        color: "#7aa2f7"
                        Text { id: cnt; anchors.centerIn: parent; text: root.store.unread + " new"; color: "#1a1b26"; font.pixelSize: 10; font.bold: true }
                    }
                }
                SilentChip { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; store: root.store }
            }

            Text {
                visible: root.store.silent
                width: parent.width
                text: "Silent: no pop-ups, everything is still saved. Critical alerts still show."
                color: "#bb9af7"; font.pixelSize: 10; wrapMode: Text.WordWrap
            }

            // empty state
            Column {
                visible: root.store.items.length === 0
                width: parent.width
                spacing: 4
                topPadding: 4; bottomPadding: 4
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: String.fromCodePoint(0xF011B); color: "#414868"; font.pixelSize: 34 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No notifications"; color: "#565f89"; font.pixelSize: 11 }
            }

            Repeater {
                model: root.latest
                delegate: NotifRow { store: root.store }
            }

            // see all + clear all
            Row {
                visible: root.store.items.length > 0
                width: parent.width
                spacing: 8
                Rectangle {
                    width: (parent.width - 8) * 0.6
                    height: 32; radius: 9
                    color: am.containsMouse ? "#565f89" : "#414868"
                    Text {
                        anchors.centerIn: parent
                        text: "See all  (" + root.store.items.length + ")  " + String.fromCodePoint(0xF0142)
                        color: "#c0caf5"; font.pixelSize: 11; font.bold: true
                    }
                    MouseArea {
                        id: am
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openPage()
                    }
                }
                ClearAllButton { width: (parent.width - 8) * 0.4; store: root.store }
            }
        }
    }
}
