
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "modules"

ShellRoot {
    id: root

    // Sidebar starts hidden and opens with SUPER + A.
    property bool sidebarVisible: false

    // dwm bar height (changes with "Bar size"); the panel sits 12px below it
    property int barHeight: 28
    Process {
        id: barProcess
        running: true
        command: ["dwm-display", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/barh=(\d+)/)
                if (m) root.barHeight = Number(m[1])
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: barProcess.running = true }

    // =========================================
    // QUICK SETTINGS SIDEBAR
    // =========================================

    PanelWindow {
        id: sidebar

        visible: root.sidebarVisible

        anchors {
            right: true
            top: true
            bottom: true
        }

        margins {
            right: 12
            top: root.barHeight + 12
            bottom: 12
        }

        implicitWidth: 360

        // Square, opaque outer frame: no rounded corners showing the window behind them
        // (picom draws a shadow around the window rectangle). Cards inside stay rounded.
        color: "#1a1b26"

        Rectangle {
            anchors.fill: parent

            radius: 0
            color: "#1a1b26"

            border.width: 1
            border.color: "#414868"

            // power row pinned to the bottom, always visible
            Column {
                id: powerFooter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 20
                spacing: 14

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#414868"
                }

                PowerCard {
                    width: parent.width
                    onRequestClose: root.sidebarVisible = false
                }
            }

            Flickable {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: powerFooter.top
                anchors.margins: 20
                anchors.bottomMargin: 14

                contentWidth: width
                contentHeight: contentColumn.implicitHeight

                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Column {
                    id: contentColumn

                    width: parent.width
                    spacing: 18

                    // =================================
                    // USER (name, distro, wm — detected automatically)
                    // =================================

                    UserCard {
                        width: parent.width
                        onRequestClose: root.sidebarVisible = false
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#414868"
                    }

                    // =================================
                    // CONNECTIVITY
                    // =================================

                    SectionTitle { text: "CONNECTIVITY" }

                    Wifi {
                        width: parent.width
                    }

                    BluetoothCard {
                        width: parent.width
                    }

                    // =================================
                    // AUDIO
                    // =================================

                    SectionTitle { text: "AUDIO" }

                    AudioCard {
                        width: parent.width
                    }

                    // =================================
                    // DISPLAY
                    // =================================

                    SectionTitle { text: "DISPLAY" }

                    BrightnessCard {
                        width: parent.width
                    }

                    DisplayCard {
                        width: parent.width
                        onRequestClose: root.sidebarVisible = false
                    }

                    // =================================
                    // WINDOWS (dwm layouts)
                    // =================================

                    SectionTitle { text: "WINDOWS" }

                    LayoutsCard {
                        width: parent.width
                    }

                    // =================================
                    // DWM (restart / rebuild / edit)
                    // =================================

                    SectionTitle { text: "DWM" }

                    DwmCard {
                        width: parent.width
                        onRequestClose: root.sidebarVisible = false
                    }

                    // =================================
                    // SCREENSHOT
                    // =================================

                    SectionTitle { text: "SCREENSHOT" }

                    ScreenshotCard {
                        width: parent.width
                        onRequestClose: root.sidebarVisible = false
                    }
                }
            }
        }
    }

    // =========================================
    // IPC COMMANDS
    // =========================================

    IpcHandler {
        target: "sidebar"

        function toggle(): void {
            root.sidebarVisible = !root.sidebarVisible
        }

        function open(): void {
            root.sidebarVisible = true
        }

        function close(): void {
            root.sidebarVisible = false
        }
    }
}
