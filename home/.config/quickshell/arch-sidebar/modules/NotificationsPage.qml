import QtQuick
import QtQuick.Controls

// Notifications page: slides over the sidebar like Settings.
// Every saved notification grouped by day, search, filter by app / unread, silent, clear.
Rectangle {
    id: page

    property var store
    signal back()

    color: "#1a1b26"

    property string query: ""
    property string app: ""          // "" = all apps
    property bool unreadOnly: false

    readonly property var shown: store.items.filter(n =>
        (!page.unreadOnly || n.unread) &&
        (page.app === "" || store.appOf(n) === page.app) &&
        (page.query === "" || (n.app + " " + n.summary + " " + n.body).toLowerCase().indexOf(page.query.toLowerCase()) >= 0))
    readonly property var groups: {
        const out = []
        for (const n of shown) {
            const d = store.day(n.time)
            if (!out.length || out[out.length - 1].title !== d) out.push({ title: d, items: [] })
            out[out.length - 1].items.push(n)
        }
        return out
    }
    readonly property bool filtered: query !== "" || app !== "" || unreadOnly

    onVisibleChanged: if (!visible) { query = ""; search.text = ""; app = ""; unreadOnly = false }

    // ---------------------------------------------------------------- header
    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        height: 40

        Rectangle {
            id: backBtn
            width: 36; height: 36; radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: bm.containsMouse ? "#2f3549" : "#24283b"
            border.width: 1
            border.color: bm.containsMouse ? "#7aa2f7" : "#414868"
            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(0xF004D)
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 18
                color: "#c0caf5"
            }
            MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.back() }
        }
        Column {
            anchors.left: backBtn.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Row {
                spacing: 8
                Text { text: String.fromCodePoint(0xF011B); color: "#bb9af7"; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Notifications"; color: "#c0caf5"; font.pixelSize: 20; font.bold: true }
            }
            Text {
                text: page.store.items.length + " saved" + (page.store.unread ? "  ·  " + page.store.unread + " new" : "")
                      + (page.store.silent ? "  ·  silent" : "")
                color: "#565f89"; font.pixelSize: 10
            }
        }
        SilentChip { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; store: page.store }
    }

    // ---------------------------------------------------------------- tools: search, filters
    Column {
        id: tools
        anchors.top: header.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 10

        Text {
            visible: page.store.silent
            width: parent.width
            text: "Silent is on: no pop-ups, everything is still saved here. Critical alerts (low battery) still show."
            color: "#bb9af7"; font.pixelSize: 10; wrapMode: Text.WordWrap
        }

        // search
        Rectangle {
            width: parent.width
            height: 34; radius: 9
            color: "#24283b"
            border.width: 1
            border.color: search.activeFocus ? "#7aa2f7" : "#414868"
            Text {
                id: sIcon
                x: 10; anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(0xF0349); color: "#565f89"; font.pixelSize: 15
            }
            TextInput {
                id: search
                anchors.left: sIcon.right; anchors.leftMargin: 8
                anchors.right: clr.left; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                color: "#c0caf5"; font.pixelSize: 12
                clip: true
                selectByMouse: true
                onTextChanged: page.query = text
                Text { visible: !search.text && !search.activeFocus; text: "Search notifications"; color: "#565f89"; font.pixelSize: 12 }
            }
            Text {
                id: clr
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: search.text.length > 0
                text: "✕"; color: "#a9b1d6"; font.pixelSize: 11
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: search.text = "" }
            }
        }

        // filter chips: All · Unread · apps
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: ["All", "Unread"].concat(page.store.apps)
                delegate: Rectangle {
                    readonly property bool on: index === 0 ? (!page.unreadOnly && page.app === "")
                                              : index === 1 ? page.unreadOnly : page.app === modelData
                    width: chipT.implicitWidth + 18; height: 24; radius: 12
                    color: on ? "#7aa2f7" : (cm.containsMouse ? "#2f3549" : "#24283b")
                    border.width: 1
                    border.color: on ? "#7aa2f7" : "#414868"
                    Text {
                        id: chipT
                        anchors.centerIn: parent
                        text: index === 1 ? "Unread" + (page.store.unread ? " " + page.store.unread : "") : modelData
                        color: parent.on ? "#1a1b26" : "#a9b1d6"; font.pixelSize: 10; font.bold: parent.on
                    }
                    MouseArea {
                        id: cm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (index === 0) { page.unreadOnly = false; page.app = "" }
                            else if (index === 1) page.unreadOnly = !page.unreadOnly
                            else page.app = page.app === modelData ? "" : modelData
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------- list, grouped by day
    Flickable {
        id: list
        anchors.top: tools.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footer.top
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.bottomMargin: 12
        contentWidth: width
        contentHeight: listCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: listCol
            width: list.width
            spacing: 6

            // empty
            Column {
                visible: page.shown.length === 0
                width: parent.width
                topPadding: 40
                spacing: 6
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: String.fromCodePoint(0xF011B); color: "#414868"; font.pixelSize: 56 }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: page.filtered ? "Nothing matches" : "No notifications"
                    color: "#565f89"; font.pixelSize: 12
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !page.filtered
                    text: "They are saved here until you delete them."
                    color: "#414868"; font.pixelSize: 10
                }
            }

            Repeater {
                model: page.groups
                delegate: Column {
                    width: listCol.width
                    spacing: 6
                    Text {
                        topPadding: index === 0 ? 0 : 8
                        text: modelData.title.toUpperCase() + "  ·  " + modelData.items.length
                        color: "#565f89"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
                    }
                    Repeater {
                        model: modelData.items
                        delegate: NotifRow { store: page.store }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------- footer: clear
    Column {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        spacing: 10
        visible: page.shown.length > 0
        height: visible ? implicitHeight : 0

        Rectangle { width: parent.width; height: 1; color: "#414868" }
        ClearAllButton {
            width: parent.width
            store: page.store
            ids: page.filtered ? page.shown.map(n => n.id) : null
            label: page.filtered ? "Delete these " + page.shown.length : "Clear all " + page.store.items.length
        }
    }
}
