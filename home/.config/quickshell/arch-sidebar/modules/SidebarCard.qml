import QtQuick

// Sidebar placement settings (accordion): side, overlay / push windows, width, margin.
// Writes straight into the JsonAdapter of settings.json (saved automatically).
Item {
    id: root

    width: 300
    height: card.height

    property var settings
    property bool expanded: false

    readonly property var descriptions: ({
        "overlay": "Floats above your windows; nothing moves when it opens.",
        "push": "Windows make room: tiled windows shrink so nothing is hidden behind the panel."
    })

    Rectangle {
        id: card
        width: parent.width
        height: header.height + (root.expanded ? body.implicitHeight + 14 : 0) + 28
        radius: 15
        color: "#24283b"
        clip: true
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Item {
            id: header
            x: 14
            y: 14
            width: parent.width - 28
            height: 40

            // little panel icon showing the side
            Rectangle {
                id: icon
                width: 46
                height: 32
                radius: 6
                anchors.verticalCenter: parent.verticalCenter
                color: "#1f2335"
                border.width: 1
                border.color: "#414868"
                Rectangle {
                    width: 14
                    height: parent.height - 8
                    y: 4
                    x: root.settings && root.settings.side === "left" ? 4 : parent.width - width - 4
                    radius: 3
                    color: "#7aa2f7"
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }

            Column {
                anchors.left: icon.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text { text: "Sidebar"; color: "#c0caf5"; font.pixelSize: 14; font.bold: true }
                Text {
                    text: root.settings ? root.settings.side + "  ·  " + root.settings.mode + "  ·  " + root.settings.width + "px  ·  "
                          + (root.settings.margin < 0 ? "gaps" : root.settings.margin + "px") : ""
                    color: "#7aa2f7"
                    font.pixelSize: 11
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: 8
                color: hm.containsMouse ? "#2f3549" : "#1f2335"
                border.width: 1
                border.color: "#414868"
                Text {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0xF0140)
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 16
                    color: "#a9b1d6"
                    rotation: root.expanded ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
            }

            MouseArea {
                id: hm
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }

        Column {
            id: body
            x: 14
            anchors.top: header.bottom
            anchors.topMargin: 14
            width: parent.width - 28
            spacing: 10
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Rectangle { width: parent.width; height: 1; color: "#414868" }

            RowTitle { title: "Side"; value: root.settings ? root.settings.side : "" }
            ChipRow {
                values: ["left", "right"]
                current: root.settings ? root.settings.side : ""
                label: v => v === "left" ? "◧  Left" : "Right  ◨"
                onPicked: v => root.settings.side = v
            }

            RowTitle { title: "Behaviour"; value: root.settings ? root.settings.mode : "" }
            ChipRow {
                values: ["overlay", "push"]
                current: root.settings ? root.settings.mode : ""
                label: v => v === "overlay" ? "Overlay" : "Push windows"
                onPicked: v => root.settings.mode = v
            }
            Text {
                width: parent.width
                text: root.settings ? root.descriptions[root.settings.mode] || "" : ""
                color: "#565f89"
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }

            RowTitle { title: "Width"; value: root.settings ? root.settings.width + "px" : "" }
            ChipRow {
                values: [320, 360, 400, 440]
                current: root.settings ? root.settings.width : 0
                label: v => v + ""
                onPicked: v => root.settings.width = v
            }

            RowTitle { title: "Margin"; value: root.settings ? (root.settings.margin < 0 ? "follows gaps" : root.settings.margin + "px") : "" }
            ChipRow {
                values: [-1, 0, 8, 12, 20]
                current: root.settings ? root.settings.margin : -1
                label: v => v < 0 ? "gaps" : v === 0 ? "flush" : v + ""
                onPicked: v => root.settings.margin = v
            }
            Text {
                width: parent.width
                text: "gaps: same space as dwm's outer gap (none when gaps are off). In push mode the panel keeps the inner gap to your windows."
                color: "#565f89"
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }

            ResetButton {
                what: "sidebar"
                onConfirmed: {
                    root.settings.side = "right"
                    root.settings.mode = "overlay"
                    root.settings.width = 360
                    root.settings.margin = -1
                }
            }
        }
    }
}
