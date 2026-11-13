import QtQuick

// one Bluetooth device row (BluetoothCard): icon, name (+ battery), action buttons
Rectangle {
    required property var modelData
    property var card
    readonly property string busyState: card ? (card.busy[modelData.mac] || "") : ""
    width: parent ? parent.width : 0
    height: 34
    radius: 8
    color: modelData.connected ? "#2a3350" : "#1a1b26"
    border.width: modelData.connected ? 1 : 0
    border.color: "#7aa2f7"

    Text {
        id: ic
        x: 9
        anchors.verticalCenter: parent.verticalCenter
        text: String.fromCodePoint(card.glyph(modelData.icon))
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 15
        color: modelData.connected ? "#7aa2f7" : "#a9b1d6"
    }
    Text {
        anchors.left: ic.right
        anchors.leftMargin: 8
        anchors.right: btns.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: modelData.name + (modelData.battery ? "  " + modelData.battery + "%" : "")
        color: "#c0caf5"
        font.pixelSize: 11
        elide: Text.ElideRight
    }
    Row {
        id: btns
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            visible: parent.parent.busyState !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: parent.parent.busyState + "…"
            color: "#e0af68"; font.pixelSize: 10
        }
        BtButton {
            visible: parent.parent.busyState === ""
            label: !modelData.paired ? "Pair" : modelData.connected ? "Disconnect" : "Connect"
            accent: modelData.connected ? "#f7768e" : "#9ece6a"
            onClicked: {
                if (!modelData.paired) card.act("pair", modelData.mac, "pairing")
                else if (modelData.connected) card.act("disconnect", modelData.mac, "disconnecting")
                else card.act("connect", modelData.mac, "connecting")
            }
        }
        BtButton {
            visible: parent.parent.busyState === "" && modelData.paired
            label: "✕"
            accent: "#565f89"
            tip: "Forget"
            onClicked: card.act("remove", modelData.mac, "forgetting")
        }
    }
}
