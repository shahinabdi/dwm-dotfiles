import QtQuick
import Quickshell
import Quickshell.Io

// Fonts (Settings page): which Nerd Font the interface / terminal / bar use, and the
// online Nerd Fonts library (install / remove). Everything goes through ~/.local/bin/dwm-font.
Item {
    id: root

    width: 300
    height: col.implicitHeight

    property var current: ({ interface: "", terminal: "", bar: "" })
    property var families: []
    property var library: []          // [{ name, installed, ours, mb }]
    property string picking: ""       // target whose picker is open
    property string filter: ""
    property var busy: ({})           // name -> true while installing / removing
    property bool loading: false

    function refresh() { curP.running = true; famP.running = true }
    function loadLibrary(force) { root.loading = true; libP.command = ["dwm-font", "catalogue"].concat(force ? ["--refresh"] : []); libP.running = true }
    Component.onCompleted: { refresh(); loadLibrary(false) }

    Process {
        id: curP
        command: ["dwm-font", "current"]
        stdout: StdioCollector {
            onStreamFinished: {
                const c = {}
                for (const l of this.text.split("\n")) { const i = l.indexOf("="); if (i > 0) c[l.slice(0, i)] = l.slice(i + 1) }
                root.current = c
            }
        }
    }
    Process {
        id: famP
        command: ["dwm-font", "families"]
        stdout: StdioCollector { onStreamFinished: root.families = this.text.split("\n").filter(l => l) }
    }
    Process {
        id: libP
        stdout: StdioCollector {
            onStreamFinished: {
                root.library = this.text.split("\n").filter(l => l.includes("|")).map(l => {
                    const f = l.split("|"); return { name: f[0], installed: f[1] === "1", ours: f[2] === "1", mb: f[3] } })
                root.loading = false
            }
        }
    }

    // installing / removing runs in the background; poll the library until it settles
    Timer { id: settle; interval: 2500; repeat: true; property int left: 0
        onTriggered: { root.loadLibrary(false); root.refresh(); if (--left <= 0) { stop(); root.busy = ({}) } } }

    function font(args) { Quickshell.execDetached(["dwm-font"].concat(args)) }
    function setFont(target, fam) {
        root.picking = ""
        const c = Object.assign({}, root.current); c[target] = fam; root.current = c
        font(["set", target, fam])
        settle.left = 2; settle.restart()
    }
    function libAction(name, action) {
        const b = Object.assign({}, root.busy); b[name] = true; root.busy = b
        font([action, name])
        settle.left = 12; settle.restart()
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        // ---------------------------------------------------------------- current fonts
        Repeater {
            model: [
                { key: "interface", title: "Interface", hint: "GTK · Qt · sidebar · rofi · notifications" },
                { key: "terminal",  title: "Terminal",  hint: "kitty (live)" },
                { key: "bar",       title: "Bar",       hint: "dwm bar text (restarts dwm in place)" }
            ]
            Rectangle {
                id: row
                required property var modelData
                readonly property bool open: root.picking === modelData.key
                width: col.width
                height: rowCol.implicitHeight + 20
                radius: 12
                color: "#1f2335"
                border.width: 1
                border.color: open ? "#7aa2f7" : "#414868"
                clip: true

                Column {
                    id: rowCol
                    x: 12
                    y: 10
                    width: parent.width - 24
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 40
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 74
                            spacing: 2
                            Text { text: row.modelData.title + "  ·  " + row.modelData.hint; color: "#565f89"; font.pixelSize: 9; width: parent.width; elide: Text.ElideRight }
                            Text {
                                width: parent.width
                                text: root.current[row.modelData.key] || "…"
                                font.family: (root.current[row.modelData.key] || "").replace(/ \(default\)$/, "")
                                font.pixelSize: 15
                                color: "#c0caf5"
                                elide: Text.ElideRight
                            }
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 66; height: 28; radius: 8
                            color: row.open ? "#7aa2f7" : (cm.containsMouse ? "#2f3549" : "#24283b")
                            border.width: 1; border.color: "#7aa2f7"
                            Text { anchors.centerIn: parent; text: row.open ? "Close" : "Change"; font.pixelSize: 10; font.bold: true; color: row.open ? "#1a1b26" : "#7aa2f7" }
                            MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.picking = row.open ? "" : row.modelData.key }
                        }
                    }

                    // picker: every installed family, shown in its own font
                    Column {
                        visible: row.open
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: row.modelData.key === "bar" ? ["default"].concat(root.families) : root.families
                            Rectangle {
                                required property string modelData
                                width: rowCol.width
                                height: 30
                                radius: 7
                                readonly property bool sel: (root.current[row.modelData.key] || "").startsWith(modelData === "default" ? "JetBrains Mono (default)" : modelData)
                                color: sel ? "#7aa2f7" : (fm.containsMouse ? "#2f3549" : "#24283b")
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData === "default" ? "Default — JetBrains Mono + big icons" : modelData
                                    font.family: modelData === "default" ? "JetBrains Mono" : modelData
                                    font.pixelSize: 13
                                    color: parent.sel ? "#1a1b26" : "#c0caf5"
                                }
                                MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setFont(row.modelData.key, modelData) }
                            }
                        }
                        Text {
                            visible: row.modelData.key === "bar"
                            width: parent.width
                            text: "A Nerd Font as bar text also draws the icons, at text size."
                            color: "#565f89"; font.pixelSize: 9; wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------------------- Nerd Fonts library
        Item {
            width: parent.width
            height: 26
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Nerd Fonts library"
                color: "#c0caf5"; font.pixelSize: 13; font.bold: true
            }
            Text {
                anchors.right: refreshBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.loading ? "loading…" : root.library.filter(f => f.installed).length + " / " + root.library.length + " installed"
                color: "#565f89"; font.pixelSize: 10
            }
            Rectangle {
                id: refreshBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 26; height: 26; radius: 7
                color: rfm.containsMouse ? "#2f3549" : "#1f2335"
                Text { anchors.centerIn: parent; text: String.fromCodePoint(0xF0450); font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14; color: "#a9b1d6" }
                MouseArea { id: rfm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.loadLibrary(true) }
            }
        }

        // search
        Rectangle {
            width: parent.width
            height: 34
            radius: 9
            color: "#1f2335"
            border.width: 1
            border.color: search.activeFocus ? "#7aa2f7" : "#414868"
            Text {
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(0xF0349)
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 14
                color: "#565f89"
            }
            TextInput {
                id: search
                x: 32
                width: parent.width - 42
                anchors.verticalCenter: parent.verticalCenter
                color: "#c0caf5"
                font.pixelSize: 12
                selectByMouse: true
                clip: true
                onTextChanged: root.filter = text.toLowerCase()
                Text { visible: !search.text; text: "search 72 fonts…"; color: "#565f89"; font.pixelSize: 12 }
            }
        }

        // list
        Rectangle {
            width: parent.width
            height: 300
            radius: 10
            color: "#16161e"
            border.width: 1
            border.color: "#414868"
            clip: true

            ListView {
                id: lib
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.library.filter(f => !root.filter || f.name.toLowerCase().includes(root.filter))
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool busyNow: !!root.busy[modelData.name]
                    width: lib.width
                    height: 34
                    radius: 7
                    color: lm.containsMouse ? "#24283b" : "transparent"
                    MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: (modelData.installed ? "● " : "  ") + modelData.name
                        color: modelData.installed ? "#c0caf5" : "#a9b1d6"
                        font.pixelSize: 12
                        font.bold: modelData.installed
                    }
                    Text {
                        anchors.right: act.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.mb + " MB"
                        color: "#565f89"; font.pixelSize: 9
                    }
                    Rectangle {
                        id: act
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 64; height: 24; radius: 7
                        visible: !modelData.installed || modelData.ours || busyNow
                        readonly property bool remove: modelData.installed && modelData.ours
                        color: busyNow ? "#24283b" : am.containsMouse ? (remove ? "#f7768e" : "#9ece6a") : "#24283b"
                        border.width: 1
                        border.color: busyNow ? "#414868" : remove ? "#f7768e" : "#9ece6a"
                        Text {
                            anchors.centerIn: parent
                            text: busyNow ? "…" : act.remove ? "Remove" : "Install"
                            font.pixelSize: 10; font.bold: true
                            color: busyNow ? "#565f89" : am.containsMouse ? "#1a1b26" : (act.remove ? "#f7768e" : "#9ece6a")
                        }
                        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            enabled: !busyNow
                            onClicked: root.libAction(modelData.name, act.remove ? "remove" : "install") }
                    }
                    Text {
                        visible: modelData.installed && !modelData.ours && !busyNow
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "system"
                        color: "#565f89"; font.pixelSize: 9
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "From github.com/ryanoasis/nerd-fonts (latest release). Fonts install for your user in ~/.local/share/fonts/NerdFonts; “system” fonts come from packages."
            color: "#565f89"; font.pixelSize: 10; wrapMode: Text.WordWrap
        }
    }
}
