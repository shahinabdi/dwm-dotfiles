
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "modules"

ShellRoot {
    id: root

    // Sidebar starts hidden and opens with SUPER + A.
    property bool sidebarVisible: false
    property bool settingsOpen: false          // gear next to the profile
    property bool wsOpen: false                // Settings → Workspaces (icons + app rules)
    property bool notifOpen: false             // "See all" in Notifications / the cat on the bar
    // closing the sidebar: notifications seen (unread dots / bar count reset)
    onSidebarVisibleChanged: if (!sidebarVisible) { settingsOpen = false; notifOpen = false; wsOpen = false; Quickshell.execDetached(["dwm-notif", "seen"]) }

    // saved notifications (dwm-notif), shared by the card and the page
    NotifStore { id: notifs }

    // dwm bar height (changes with "Bar size"); the panel sits 12px below it
    property int barHeight: 28
    Process {
        id: barProcess
        running: true
        command: ["dwm-display", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/barh=(\d+)/)
                if (m && Number(m[1]) >= 10 && Number(m[1]) <= 200) root.barHeight = Number(m[1])
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: barProcess.running = true }

    // dwm gaps (from _DWM_STATE): the panel follows the outer gap when margin = "gaps" (-1)
    property bool gapsOn: true
    property int gapOuter: 10
    Process {
        id: gapProcess
        running: true
        command: ["dwm-layout", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const on = this.text.match(/ gaps=(\d)/), o = this.text.match(/gapouter=(\d+)/)
                if (on) root.gapsOn = on[1] === "1"
                if (o) root.gapOuter = Number(o[1])
            }
        }
    }
    Timer { interval: 1500; running: true; repeat: true; onTriggered: gapProcess.running = true }
    readonly property int edgeMargin: settings.margin < 0 ? (root.gapsOn ? root.gapOuter : 0) : settings.margin

    // sidebar settings (side, overlay / push, width, margin) — saved in settings.json,
    // changed from the "Sidebar" card; editing the file by hand reloads it live
    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/arch-sidebar/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter() }

        JsonAdapter {
            id: settings
            property string side: "right"     // right | left
            property string mode: "overlay"   // overlay: float above windows · push: windows make room
            property int width: 360
            property int margin: -1         // -1 = follow dwm's outer gap (0 when gaps are off)
        }
    }

    // =========================================
    // QUICK SETTINGS SIDEBAR
    // =========================================

    PanelWindow {
        id: sidebar

        visible: root.sidebarVisible

        anchors {
            left: settings.side === "left"
            right: settings.side !== "left"
            top: true
            bottom: true
        }

        margins {
            left: settings.side === "left" ? root.edgeMargin : 0
            right: settings.side !== "left" ? root.edgeMargin : 0
            top: root.barHeight + root.edgeMargin
            bottom: root.edgeMargin
        }

        implicitWidth: Math.max(300, Math.min(520, settings.width))

        // keyboard input (search fields, Wi-Fi password)
        focusable: true

        // push: dwm keeps tiled windows out of the panel's space (via the strut); overlay: float above
        exclusionMode: settings.mode === "push" ? ExclusionMode.Auto : ExclusionMode.Ignore

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
                        onOpenSettings: root.settingsOpen = true
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#414868"
                    }

                    // =================================
                    // NOTIFICATIONS (saved until deleted — dwm-notif)
                    // =================================

                    NotificationsCard {
                        width: parent.width
                        store: notifs
                        onOpenPage: root.notifOpen = true
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
                    // SYSTEM (CPU, memory, disk — htop in one click)
                    // =================================

                    SectionTitle { text: "SYSTEM" }

                    SystemCard {
                        width: parent.width
                        active: root.sidebarVisible
                    }

                    // =================================
                    // DISPLAY
                    // =================================

                    SectionTitle { text: "DISPLAY" }

                    BrightnessCard {
                        width: parent.width
                    }

                    WallpaperCard {
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
                    // SCREENSHOT
                    // =================================

                    SectionTitle { text: "SCREENSHOT" }

                    ScreenshotCard {
                        width: parent.width
                        onRequestClose: root.sidebarVisible = false
                    }
                }
            }

            // Notifications page: slides in like Settings
            NotificationsPage {
                width: parent.width - 2
                height: parent.height - 2
                y: 1
                x: root.notifOpen ? 1 : (settings.side === "left" ? -width : width)
                opacity: root.notifOpen ? 1 : 0
                visible: opacity > 0
                z: 9
                store: notifs
                onBack: root.notifOpen = false
                Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Settings page: slides in over the quick settings (from the side the panel is on)
            SettingsPage {
                width: parent.width - 2
                height: parent.height - 2
                y: 1
                x: root.settingsOpen ? 1 : (settings.side === "left" ? -width : width)
                opacity: root.settingsOpen ? 1 : 0
                visible: opacity > 0
                z: 10
                settings: settings
                onBack: root.settingsOpen = false
                onRequestClose: root.sidebarVisible = false
                onOpenWorkspaces: root.wsOpen = true
                Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Workspaces page (from Settings): slides in above it
            WorkspacesPage {
                width: parent.width - 2
                height: parent.height - 2
                y: 1
                x: root.wsOpen ? 1 : (settings.side === "left" ? -width : width)
                opacity: root.wsOpen ? 1 : 0
                visible: opacity > 0
                z: 11
                onBack: root.wsOpen = false
                Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
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

        // open straight on the Notifications page (the cat on the bar)
        function notifications(): void {
            root.settingsOpen = false
            root.notifOpen = true
            root.sidebarVisible = true
        }

        // open the Settings page (Updates is at the top) — lunaris-update, notifications
        function settings(): void {
            root.notifOpen = false
            root.wsOpen = false
            root.settingsOpen = true
            root.sidebarVisible = true
        }

        // open straight on the Workspaces page (icons + app rules)
        function workspaces(): void {
            root.notifOpen = false
            root.settingsOpen = true
            root.wsOpen = true
            root.sidebarVisible = true
        }

        function close(): void {
            root.sidebarVisible = false
        }

        // after a monitor change (plug in, arrangement, primary): rebuild the panel so its
        // position is computed from the new screen layout (called by the autorandr hook / dwm-monitor)
        function relayout(): void {
            root.sidebarVisible = false
            Quickshell.reload(true)
        }
    }
}
