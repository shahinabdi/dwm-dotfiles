import QtQuick

// One saved notification in the Notifications card (modelData from `dwm-notif list`).
Rectangle {
    id: row
    property var card
    width: parent ? parent.width : 280
    height: body.implicitHeight + 20
    radius: 10
    color: hover.hovered ? "#2f3549" : "#1f2335"
    border.width: 1
    border.color: modelData.urgency === "critical" ? "#f7768e" : (modelData.unread ? "#3b4261" : "#2a2e42")

    HoverHandler { id: hover }

    // unread dot
    Rectangle {
        visible: modelData.unread
        x: 6; y: 8; width: 6; height: 6; radius: 3
        color: "#7aa2f7"
    }

    // icon: the notification's image (screenshot, avatar…) or a glyph
    Item {
        id: ico
        x: 14; y: 10
        width: 32; height: 32
        Image {
            id: img
            anchors.fill: parent
            source: modelData.icon ? "file://" + modelData.icon : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 64; sourceSize.height: 64
            asynchronous: true
            visible: status === Image.Ready
        }
        Rectangle {
            anchors.fill: parent
            visible: img.status !== Image.Ready
            radius: 8
            color: "#24283b"
            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(row.card.glyph(modelData))
                color: modelData.urgency === "critical" ? "#f7768e" : "#7aa2f7"
                font.pixelSize: 18
            }
        }
    }

    Column {
        id: body
        x: ico.x + ico.width + 10
        y: 10
        width: row.width - x - 34
        spacing: 2
        Text {
            width: parent.width
            text: (modelData.app ? modelData.app + "  ·  " : "") + row.card.ago(modelData.time)
            color: "#565f89"; font.pixelSize: 9
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: modelData.summary
            color: "#c0caf5"; font.pixelSize: 12; font.bold: true
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
        Text {
            visible: text.length > 0
            width: parent.width
            text: modelData.body
            color: "#a9b1d6"; font.pixelSize: 11
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }

    // delete
    Rectangle {
        anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 6
        width: 22; height: 22; radius: 11
        color: xm.containsMouse ? "#f7768e" : "transparent"
        opacity: hover.hovered || xm.containsMouse ? 1 : 0.45
        Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; color: xm.containsMouse ? "#1a1b26" : "#a9b1d6" }
        MouseArea {
            id: xm
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.card.remove(modelData.id)
        }
    }
}
