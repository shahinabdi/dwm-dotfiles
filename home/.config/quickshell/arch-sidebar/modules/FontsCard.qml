import QtQuick
import Quickshell
import Quickshell.Io

// Fonts (Settings page): which font the interface (any installed font) / terminal / bar
// (Nerd Fonts or other monospace fonts) use, and the
// online Nerd Fonts library (install / remove). Everything goes through ~/.local/bin/dwm-font.
Item {
    id: root

    width: 300
    height: col.implicitHeight

    property var current: ({ interface: "", terminal: "", bar: "" })
    property var families: ({ interface: [], terminal: [] })   // [{ kind: "nerd"|"system", name }]
    property string pickFilter: ""    // search inside the open picker
    property var library: []          // [{ name, installed, ours, mb }]
    property string picking: ""       // target whose picker is open
    property string filter: ""
    property var busy: ({})           // name -> true while installing / removing
    property bool loading: false
    property int textSize: 0          // dwm-display font size (kitty, GTK, Qt, rofi, notifications)

    function refresh() { curP.running = true; famP.running = true; sizeP.running = true }
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
        id: sizeP
        command: ["dwm-display", "status"]
        stdout: StdioCollector { onStreamFinished: { const m = this.text.match(/font=(\d+)/); if (m) root.textSize = Number(m[1]) } }
    }
    Process {
        id: famP
        // interface: every installed font · terminal / bar: monospace (Nerd Fonts first)
        command: ["sh", "-c", "dwm-font families interface | sed 's/^/interface|/'; dwm-font families terminal | sed 's/^/terminal|/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = { interface: [], terminal: [] }
                for (const l of this.text.split("\n")) {
                    const p = l.split("|"); if (p.length < 3 || !f[p[0]]) continue
                    f[p[0]].push({ kind: p[1], name: p.slice(2).join("|") })
                }
                root.families = f
            }
        }
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

    function font(args) {
        if (args[0] === "__size") {   // text size lives in dwm-display
            Quickshell.execDetached(["dwm-display", "font", args[1]])
            settle.left = 1; settle.restart()
            return
        }
        Quickshell.execDetached(["dwm-font"].concat(args))
    }
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

        // ---------------------------------------------------------------- text size
        Rectangle {
            width: col.width
            height: sizeCol.implicitHeight + 20
            radius: 12
            color: "#1f2335"
            border.width: 1
            border.color: "#414868"
            Column {
                id: sizeCol
                x: 12
                y: 10
                width: parent.width - 24
                spacing: 6
                Row {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: "Text size"
                        color: "#c0caf5"; font.pixelSize: 13; font.bold: true
                        width: parent.width - 3 * 34 - 2 * 8
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    ActionButton {
                        width: 34; height: 30; implicitHeight: 30; radius: 8
                        glyph: 0xF0374; iconSize: 14; label: ""
                        onClicked: { root.textSize -= 1; root.font(["__size", "-"]) }
                    }
                    Text {
                        width: 34
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: root.textSize > 0 ? root.textSize : "–"
                        color: "#7aa2f7"; font.pixelSize: 13; font.bold: true
                    }
                    ActionButton {
                        width: 34; height: 30; implicitHeight: 30; radius: 8
                        glyph: 0xF0415; iconSize: 14; label: ""
                        onClicked: { root.textSize += 1; root.font(["__size", "+"]) }
                    }
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Changes: terminal (kitty, live) · GTK apps (live) · rofi menus · notifications · Qt apps (after restart). "
                        + "Not the dwm bar — that's “Bar size” above — and not the whole screen — that's “Screen scale”."
                    color: "#565f89"; font.pixelSize: 10
                }
            }
        }

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

                    // picker: search + every font this target can use, each shown in its own font
                    Column {
                        id: picker
                        visible: row.open
                        width: parent.width
                        spacing: 6

                        // filtered fonts with a heading row before each group
                        readonly property var items: {
                            const all = (row.modelData.key === "interface" ? root.families.interface : root.families.terminal) || []
                            const base = row.modelData.key === "bar" ? [{ kind: "nerd", name: "default" }].concat(all) : all
                            const q = root.pickFilter
                            const out = []
                            let last = ""
                            for (const f of base) {
                                if (q && !f.name.toLowerCase().includes(q)) continue
                                if (f.kind !== last) {
                                    last = f.kind
                                    out.push({ kind: "header", name: f.kind === "nerd" ? "NERD FONTS"
                                        : (row.modelData.key === "interface" ? "OTHER INSTALLED FONTS" : "OTHER MONOSPACE FONTS") })
                                }
                                out.push(f)
                            }
                            return out
                        }

                        Rectangle {
                            width: parent.width
                            height: 30
                            radius: 8
                            color: "#16161e"
                            border.width: 1
                            border.color: pickSearch.activeFocus ? "#7aa2f7" : "#414868"
                            Text {
                                x: 9
                                anchors.verticalCenter: parent.verticalCenter
                                text: String.fromCodePoint(0xF0349)
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 13
                                color: "#565f89"
                            }
                            TextInput {
                                id: pickSearch
                                x: 30
                                width: parent.width - 40
                                anchors.verticalCenter: parent.verticalCenter
                                color: "#c0caf5"
                                font.pixelSize: 12
                                selectByMouse: true
                                clip: true
                                onTextChanged: root.pickFilter = text.toLowerCase()
                                Connections { target: row; function onOpenChanged() { pickSearch.text = "" } }
                                Text {
                                    visible: !pickSearch.text
                                    text: row.modelData.key === "interface" ? "search all installed fonts (e.g. vazirmatn)…" : "search monospace fonts…"
                                    color: "#565f89"; font.pixelSize: 12
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: Math.min(300, Math.max(34, fontList.contentHeight + 8))
                            radius: 8
                            color: "#16161e"
                            border.width: 1
                            border.color: "#414868"
                            clip: true

                            ListView {
                                id: fontList
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 3
                                boundsBehavior: Flickable.StopAtBounds
                                model: picker.items
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property string fam: modelData.name
                                    readonly property bool header: modelData.kind === "header"
                                    width: fontList.width
                                    height: header ? 22 : 30
                                    radius: 7
                                    // selected: same family, maybe followed by a weight ("… Ultra-Light")
                                    readonly property bool sel: {
                                        if (header) return false
                                        const cur = root.current[row.modelData.key] || ""
                                        if (fam === "default") return cur === "JetBrains Mono (default)"
                                        return cur === fam || (cur.startsWith(fam + " ") && /^(Thin|Ultra-?Light|Extra-?Light|Light|Regular|Medium|Semi-?Bold|Bold|Extra-?Bold|Black)$/.test(cur.slice(fam.length + 1)))
                                    }
                                    color: header ? "transparent" : sel ? "#7aa2f7" : (fm.containsMouse ? "#2f3549" : "#24283b")
                                    Text {
                                        visible: parent.header
                                        anchors.verticalCenter: parent.verticalCenter
                                        leftPadding: 6
                                        text: parent.fam
                                        color: "#7aa2f7"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
                                    }
                                    Text {
                                        visible: !parent.header
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: fam === "default" ? "Default — JetBrains Mono + big icons" : fam
                                        font.family: fam === "default" ? "JetBrains Mono" : fam
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        color: parent.sel ? "#1a1b26" : "#c0caf5"
                                    }
                                    MouseArea { id: fm; anchors.fill: parent; enabled: !parent.header; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setFont(row.modelData.key, fam) }
                                }
                            }
                            Text {
                                visible: fontList.count === 0
                                anchors.centerIn: parent
                                text: "no installed font matches"
                                color: "#565f89"; font.pixelSize: 11
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
