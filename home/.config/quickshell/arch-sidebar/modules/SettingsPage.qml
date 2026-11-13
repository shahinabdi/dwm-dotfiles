import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

// Settings page (gear next to the profile): bar items, sidebar placement.
// Slides over the sidebar; the back arrow returns to the quick settings.
Rectangle {
    id: page

    property var settings
    signal back()
    signal requestClose()
    signal openWorkspaces()

    color: "#1a1b26"

    // ---------------------------------------------------------------- bar items (dwm-bar)
    property var items: []   // [{ id, shown, available, label }]
    readonly property var glyphs: ({
        "kb": 0xF030C, "net": 0xF05A9, "vol": 0xF057E, "mic": 0xF036C,
        "bright": 0xF00DF, "bat": 0xF0079, "clk": 0xF0150
    })

    function refresh() { listProc.running = true }

    Process {
        id: listProc
        running: true
        command: ["dwm-bar", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of this.text.split("\n")) {
                    const f = line.split(" ")
                    if (f.length < 4) continue
                    out.push({ id: f[0], shown: f[1] === "1", available: f[2] === "1", label: f.slice(3).join(" ") })
                }
                page.items = out
            }
        }
    }

    Timer { id: refreshSoon; interval: 300; onTriggered: page.refresh() }
    function bar(args) { Quickshell.execDetached(["dwm-bar"].concat(args)); refreshSoon.restart() }

    // workspace icons for the WORKSPACES card
    property var wsIcons: []
    Process {
        id: wsP
        command: ["dwm-workspaces", "get"]
        stdout: StdioCollector { onStreamFinished: { try { page.wsIcons = JSON.parse(this.text).icons } catch (e) {} } }
    }

    onVisibleChanged: if (visible) { refresh(); wsP.running = true }

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
            width: 36
            height: 36
            radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: bm.containsMouse ? "#2f3549" : "#24283b"
            border.width: 1
            border.color: bm.containsMouse ? "#7aa2f7" : "#414868"
            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(0xF004D)   // arrow-left
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 18
                color: "#c0caf5"
            }
            MouseArea {
                id: bm
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.back()
            }
        }

        Column {
            anchors.left: backBtn.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { text: "Settings"; color: "#c0caf5"; font.pixelSize: 20; font.bold: true }
            Text { text: "bar · sidebar · screen · fonts · monitors · dwm"; color: "#565f89"; font.pixelSize: 10 }
        }
    }

    Rectangle {
        id: rule
        anchors.top: header.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        height: 1
        color: "#414868"
    }

    // ---------------------------------------------------------------- content
    Flickable {
        anchors.top: rule.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.bottomMargin: 20
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: col
            width: parent.width
            spacing: 18

            // ---- bar items
            SectionTitle { text: "BAR ITEMS" }

            Rectangle {
                width: parent.width
                height: itemsCol.implicitHeight + 24
                radius: 15
                color: "#24283b"

                Column {
                    id: itemsCol
                    x: 14
                    y: 12
                    width: parent.width - 28
                    spacing: 4

                    Text {
                        width: parent.width
                        text: "What the right side of the dwm bar shows. Battery and brightness hide by themselves on machines without them."
                        color: "#565f89"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        bottomPadding: 6
                    }

                    Repeater {
                        model: page.items
                        Item {
                            required property var modelData
                            width: itemsCol.width
                            height: 42

                            Rectangle {
                                id: ic
                                width: 30
                                height: 30
                                radius: 8
                                anchors.verticalCenter: parent.verticalCenter
                                color: "#1f2335"
                                Text {
                                    anchors.centerIn: parent
                                    text: String.fromCodePoint(page.glyphs[modelData.id] || 0xF0493)
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 16
                                    color: modelData.shown && modelData.available ? "#7aa2f7" : "#565f89"
                                }
                            }

                            Column {
                                anchors.left: ic.right
                                anchors.leftMargin: 12
                                anchors.right: sw.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text { text: modelData.label; color: "#c0caf5"; font.pixelSize: 13; font.bold: true }
                                Text {
                                    visible: !modelData.available
                                    text: "not on this machine"
                                    color: "#e0af68"
                                    font.pixelSize: 9
                                }
                            }

                            Switch2 {
                                id: sw
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                on: modelData.shown
                                opacity: modelData.available ? 1 : 0.45
                                onToggled: page.bar([modelData.shown ? "hide" : "show", modelData.id])
                            }
                        }
                    }

                    ResetButton {
                        width: itemsCol.width
                        what: "bar items"
                        onConfirmed: page.bar(["reset"])
                    }
                }
            }

            // ---- sidebar placement
            // ---- workspaces: icons + app rules (WorkspacesPage)
            SectionTitle { text: "WORKSPACES" }

            Rectangle {
                width: parent.width
                height: wsCardCol.implicitHeight + 28
                radius: 15
                color: "#24283b"
                Column {
                    id: wsCardCol
                    x: 14; y: 14
                    width: parent.width - 28
                    spacing: 10
                    Row {
                        id: wsIcons
                        width: parent.width
                        Repeater {
                            model: page.wsIcons
                            delegate: Text {
                                width: wsIcons.width / 10
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 17
                                color: "#c0caf5"
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        text: "Choose each workspace's icon and which apps open on it."
                        color: "#a9b1d6"; font.pixelSize: 11; wrapMode: Text.WordWrap
                    }
                    Rectangle {
                        width: parent.width
                        height: 34; radius: 9
                        color: wsm.containsMouse ? "#565f89" : "#414868"
                        Text {
                            anchors.centerIn: parent
                            text: "Edit icons & app rules  " + String.fromCodePoint(0xF0142)
                            color: "#c0caf5"; font.pixelSize: 11; font.bold: true
                        }
                        MouseArea { id: wsm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.openWorkspaces() }
                    }
                }
            }

            SectionTitle { text: "SIDEBAR" }

            SidebarCard {
                width: parent.width
                settings: page.settings
                expanded: true
            }

            // ---- screen scale, bar size, resolution
            SectionTitle { text: "SCREEN & BAR" }

            DisplayCard {
                width: parent.width
                expanded: true
                onRequestClose: page.requestClose()
            }

            // ---- fonts
            SectionTitle { text: "FONTS" }

            FontsCard {
                width: parent.width
            }

            // ---- monitors
            SectionTitle { text: "MONITORS" }

            MonitorsCard {
                width: parent.width
                onRequestClose: page.requestClose()
            }

            // ---- dwm: source folder, restart in place, rebuild, edit config
            SectionTitle { text: "DWM" }

            DwmCard {
                width: parent.width
                onRequestClose: page.requestClose()
            }

            Text {
                width: parent.width
                text: "Restart keeps your windows (Super + Ctrl + Shift + Q). Rebuild compiles and installs dwm from the folder above, then restarts it."
                color: "#565f89"
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }
}
