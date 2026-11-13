import QtQuick

// "Clear all" for notifications: the first click asks, the second deletes (or `ids` only, when set).
Rectangle {
    id: btn
    property var store
    property var ids: null          // null = everything; otherwise only these (filtered view)
    property string label: "Clear all"
    property bool confirm: false
    readonly property int n: ids === null ? store.items.length : ids.length
    height: 32
    radius: 9
    color: confirm ? "#f7768e" : (cm.containsMouse ? "#565f89" : "#414868")
    Text {
        anchors.centerIn: parent
        text: btn.confirm ? "Click again to delete " + btn.n : btn.label
        color: btn.confirm ? "#1a1b26" : "#c0caf5"; font.pixelSize: 11; font.bold: true
    }
    MouseArea {
        id: cm
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!btn.confirm) { btn.confirm = true; t.restart(); return }
            btn.confirm = false
            if (btn.ids === null) btn.store.clearAll()
            else for (const id of btn.ids) btn.store.remove(id)
        }
        onExited: btn.confirm = false
    }
    Timer { id: t; interval: 3000; onTriggered: btn.confirm = false }
}
