import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

// Workspaces page (Settings → Workspaces): icon of each workspace and which apps open on it.
// Reads / writes ~/.config/dwm-btw/workspaces.conf through dwm-workspaces; Apply restarts dwm in place.
Rectangle {
    id: page
    signal back()
    color: "#1a1b26"

    property var icons: []
    property var rules: []
    property bool custom: false
    property bool supported: true     // the running dwm reads workspaces.conf
    property bool dirty: false
    property int sel: 1                 // 1..10, 0 = "any workspace" (floating helpers…)
    property int editIndex: -1          // rule being edited, -1 = adding
    property bool formOpen: false
    property var openApps: []           // [{cls, inst, title}]
    property string status: ""
    property bool confirmReset: false

    readonly property var selRules: rules.map((r, i) => ({ r: r, i: i })).filter(x => x.r.ws === page.sel)
    readonly property string glyphFont: "JetBrainsMono Nerd Font Mono"
    readonly property var glyphs: [0xF018D, 0xF07B7, 0xF059F, 0xF0239, 0xF02AF, 0xF0A1E, 0xF0169, 0xF024B,
                                   0xF01EE, 0xF01C8, 0xF082E, 0xF0219, 0xF057C, 0xF075A, 0xF04C7, 0xF0381,
                                   0xF02E9, 0xF03D8, 0xF0369, 0xF066F, 0xF0B79, 0xF0297, 0xF044A, 0xF01DA,
                                   0xF0493, 0xF00ED, 0xF0D27, 0xF06A9, 0xF02CB, 0xF04C3, 0xF0E1E, 0xF011B]

    function count(ws) { return rules.filter(r => r.ws === ws).length }
    function setIcon(t, fromField) {
        const a = icons.slice(); a[sel - 1] = t.length ? t : String(sel); icons = a; dirty = true
        if (!fromField) iconField.text = a[sel - 1]
    }
    onSelChanged: if (sel > 0) iconField.text = icons[sel - 1] || ""
    onIconsChanged: if (sel > 0 && !iconField.activeFocusInside) iconField.text = icons[sel - 1] || ""
    function removeRule(i) { const a = rules.slice(); a.splice(i, 1); rules = a; dirty = true; formOpen = false }
    function openForm(i) {
        editIndex = i
        const r = i >= 0 ? rules[i] : { class: "", title: "", ws: sel, float: 0, follow: 1 }
        fClass.text = r.class || r.instance || ""
        fTitle.text = r.title || ""
        form.ws = r.ws; form.isFloat = !!r.float; form.follow = !!r.follow
        formOpen = true
        if (!winP.running) winP.running = true
        Qt.callLater(() => {            // bring the form into view
            const y = form.mapToItem(col, 0, 0).y
            flick.contentY = Math.max(0, Math.min(y - 10, flick.contentHeight - flick.height))
        })
    }
    function saveForm() {
        if (!fClass.text.trim() && !fTitle.text.trim()) { status = "Type the app's class (or pick a window)"; return }
        const r = { class: fClass.text.trim(), instance: editIndex >= 0 ? (rules[editIndex].instance || "") : "",
                    title: fTitle.text.trim(), ws: form.ws, float: form.isFloat ? 1 : 0, follow: form.follow ? 1 : 0 }
        const a = rules.slice()
        if (editIndex >= 0) a[editIndex] = r; else a.push(r)
        rules = a; dirty = true; formOpen = false; status = ""
        sel = r.ws
    }
    function apply() {
        Quickshell.execDetached(["dwm-workspaces", "save", JSON.stringify({ icons: icons, rules: rules })])
        dirty = false; custom = true
        status = "Saved — dwm restarted in place. New rules apply to apps you open from now on."
    }
    function reload() { if (!getP.running) getP.running = true }

    onVisibleChanged: if (visible) { reload(); formOpen = false; status = ""; confirmReset = false }

    Process {
        id: getP
        command: ["dwm-workspaces", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text)
                    page.icons = d.icons; page.rules = d.rules; page.custom = d.custom; page.supported = d.supported !== false; page.dirty = false
                } catch (e) {}
            }
        }
    }
    Process {
        id: winP
        command: ["dwm-workspaces", "windows"]
        stdout: StdioCollector {
            onStreamFinished: page.openApps = this.text.trim().split("\n").filter(l => l).map(l => {
                const f = l.split("|"); return { cls: f[0], inst: f[1], title: f.slice(2).join("|") }
            }).filter(w => w.cls !== "quickshell" && w.cls !== "org.quickshell")
        }
    }
    Process {
        id: pickP
        command: ["dwm-workspaces", "pick"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim().split("|")
                if (f[0]) { fClass.text = f[0]; page.status = "Picked: " + f[0] + (f[2] ? "  (title: " + f[2] + ")" : "") }
            }
        }
    }

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
            Text { anchors.centerIn: parent; text: String.fromCodePoint(0xF004D); font.family: page.glyphFont; font.pixelSize: 18; color: "#c0caf5" }
            MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.back() }
        }
        Column {
            anchors.left: backBtn.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { text: "Workspaces"; color: "#c0caf5"; font.pixelSize: 20; font.bold: true }
            Text { text: "icons · which apps open where"; color: "#565f89"; font.pixelSize: 10 }
        }
    }

    // ---------------------------------------------------------------- content
    Flickable {
        id: flick
        anchors.top: header.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footer.top
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.bottomMargin: 12
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: col
            width: flick.width
            spacing: 14

            // the running dwm is older than this feature: rebuild once
            Rectangle {
                visible: !page.supported
                width: parent.width
                height: upCol.implicitHeight + 20
                radius: 10
                color: "#2a2433"
                border.width: 1
                border.color: "#e0af68"
                Column {
                    id: upCol
                    x: 10; y: 10
                    width: parent.width - 20
                    spacing: 8
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: "#e0af68"; font.pixelSize: 11
                        text: "Your dwm is older than this page: rebuild it once so it reads these settings (a terminal opens and asks for your password, then dwm restarts — windows stay)."
                    }
                    BtButton { label: "Rebuild dwm now"; accent: "#e0af68"; onClicked: Quickshell.execDetached(["dwm-dev", "build"]) }
                }
            }

            // ---- the 10 workspaces
            Grid {
                id: tiles
                width: parent.width
                columns: 5
                spacing: 6
                Repeater {
                    model: 10
                    delegate: Rectangle {
                        readonly property int ws: index + 1
                        readonly property bool on: page.sel === ws
                        width: (tiles.width - 4 * tiles.spacing) / 5
                        height: 58
                        radius: 10
                        color: on ? "#2f3549" : (tm.containsMouse ? "#24283b" : "#1f2335")
                        border.width: on ? 2 : 1
                        border.color: on ? "#7aa2f7" : "#414868"
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 8
                            text: page.icons[index] || String(ws)
                            font.family: page.glyphFont
                            font.pixelSize: 20
                            color: parent.on ? "#7aa2f7" : "#c0caf5"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            text: ws + (page.count(ws) ? "  ·  " + page.count(ws) + " app" + (page.count(ws) > 1 ? "s" : "") : "")
                            font.pixelSize: 9
                            color: "#565f89"
                        }
                        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { page.sel = ws; page.formOpen = false } }
                    }
                }
            }
            // rules without a fixed workspace (e.g. floating helpers)
            Rectangle {
                readonly property bool on: page.sel === 0
                width: parent.width
                height: 30
                radius: 8
                color: on ? "#2f3549" : (am.containsMouse ? "#24283b" : "#1f2335")
                border.width: on ? 2 : 1
                border.color: on ? "#7aa2f7" : "#414868"
                Text {
                    anchors.centerIn: parent
                    text: "Any workspace (floating windows…)" + (page.count(0) ? "  ·  " + page.count(0) : "")
                    font.pixelSize: 10
                    color: parent.on ? "#7aa2f7" : "#a9b1d6"
                }
                MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { page.sel = 0; page.formOpen = false } }
            }

            // ---- selected workspace
            Rectangle {
                width: parent.width
                height: wsCol.implicitHeight + 28
                radius: 15
                color: "#24283b"
                border.width: 1
                border.color: "#414868"

                Column {
                    id: wsCol
                    x: 14; y: 14
                    width: parent.width - 28
                    spacing: 10

                    Text {
                        text: page.sel ? "Workspace " + page.sel : "Any workspace"
                        color: "#c0caf5"; font.pixelSize: 16; font.bold: true
                    }

                    // icon
                    Column {
                        visible: page.sel > 0
                        width: parent.width
                        spacing: 8
                        Text { text: "ICON"; color: "#565f89"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                        Row {
                            width: parent.width
                            spacing: 8
                            Rectangle {
                                width: 44; height: 44; radius: 10
                                color: "#1f2335"; border.width: 1; border.color: "#7aa2f7"
                                Text { anchors.centerIn: parent; text: page.icons[page.sel - 1] || ""; font.family: page.glyphFont; font.pixelSize: 24; color: "#7aa2f7" }
                            }
                            WsField {
                                id: iconField
                                width: parent.width - 44 - 8 - numBtn.width - 8
                                anchors.verticalCenter: parent.verticalCenter
                                placeholder: "Type text or paste an icon"
                                fontFamily: page.glyphFont
                                fontSize: 16
                                onEdited: page.setIcon(text, true)
                            }
                            BtButton {
                                id: numBtn
                                anchors.verticalCenter: parent.verticalCenter
                                label: "Number"; tip: "Show the workspace number"
                                onClicked: page.setIcon(String(page.sel))
                            }
                        }
                        Grid {
                            id: glyphGrid
                            width: parent.width
                            columns: 8
                            spacing: 4
                            Repeater {
                                model: page.glyphs
                                delegate: Rectangle {
                                    readonly property string g: String.fromCodePoint(modelData)
                                    width: (glyphGrid.width - 7 * glyphGrid.spacing) / 8
                                    height: 30; radius: 6
                                    color: page.icons[page.sel - 1] === g ? "#7aa2f7" : (gm.containsMouse ? "#2f3549" : "#1f2335")
                                    Text {
                                        anchors.centerIn: parent; text: parent.g; font.family: page.glyphFont; font.pixelSize: 17
                                        color: page.icons[page.sel - 1] === parent.g ? "#1a1b26" : "#c0caf5"
                                    }
                                    MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.setIcon(parent.g) }
                                }
                            }
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            textFormat: Text.StyledText
                            linkColor: "#7aa2f7"
                            color: "#565f89"; font.pixelSize: 10
                            text: "More icons: <a href=\"https://www.nerdfonts.com/cheat-sheet\">nerdfonts.com/cheat-sheet</a> — search (\"music\", \"chat\"…), click an icon to copy it, paste it above. Plain text works too (\"web\", \"1\")."
                            onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
                            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: "#414868" }

                    // apps on this workspace
                    Text { text: "APPS THAT OPEN HERE"; color: "#565f89"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                    Text {
                        visible: page.selRules.length === 0
                        width: parent.width
                        text: page.sel ? "None — apps open on the workspace you are on." : "None."
                        color: "#565f89"; font.pixelSize: 10; wrapMode: Text.WordWrap
                    }
                    Repeater {
                        model: page.selRules
                        delegate: Rectangle {
                            width: wsCol.width
                            height: 44
                            radius: 8
                            color: page.formOpen && page.editIndex === modelData.i ? "#2f3549" : "#1f2335"
                            border.width: 1
                            border.color: "#3b4261"
                            Column {
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 100
                                spacing: 2
                                Text {
                                    width: parent.width
                                    text: modelData.r.class || modelData.r.instance || ("title: " + modelData.r.title)
                                    color: "#c0caf5"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: [modelData.r.title && (modelData.r.class || modelData.r.instance) ? "title has “" + modelData.r.title + "”" : "",
                                           modelData.r.float ? "floating" : "",
                                           page.sel ? (modelData.r.follow ? "jumps there" : "opens quietly") : ""].filter(s => s).join("  ·  ")
                                    color: "#565f89"; font.pixelSize: 9; elide: Text.ElideRight
                                }
                            }
                            Row {
                                anchors.right: parent.right; anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                BtButton { label: "Edit"; onClicked: page.openForm(modelData.i) }
                                BtButton { label: "✕"; accent: "#f7768e"; onClicked: page.removeRule(modelData.i) }
                            }
                        }
                    }

                    BtButton {
                        visible: !page.formOpen
                        label: "+  Add an app"
                        height: 30
                        onClicked: page.openForm(-1)
                    }

                    // ---- add / edit form
                    Rectangle {
                        id: form
                        visible: page.formOpen
                        property int ws: 1
                        property bool isFloat: false
                        property bool follow: true
                        width: parent.width
                        height: formCol.implicitHeight + 24
                        radius: 10
                        color: "#1f2335"
                        border.width: 1
                        border.color: "#7aa2f7"

                        Column {
                            id: formCol
                            x: 12; y: 12
                            width: parent.width - 24
                            spacing: 10

                            Text { text: page.editIndex >= 0 ? "Edit app" : "Add an app"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true }

                            WsField {
                                id: fClass
                                width: parent.width
                                label: "APP (WINDOW CLASS)"
                                placeholder: "e.g. kitty, firefox, Spotify"
                            }
                            Row {
                                spacing: 6
                                BtButton {
                                    label: pickP.running ? "Click a window…" : "Pick a window"
                                    tip: "Then click any window"
                                    onClicked: if (!pickP.running) { page.status = "Click the window of the app (outside this panel)…"; pickP.running = true }
                                }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "or choose an open app:"; color: "#565f89"; font.pixelSize: 9 }
                            }
                            Flow {
                                width: parent.width
                                spacing: 4
                                Repeater {
                                    model: page.openApps
                                    delegate: Rectangle {
                                        width: oa.implicitWidth + 14; height: 22; radius: 11
                                        color: fClass.text === modelData.cls ? "#7aa2f7" : (om.containsMouse ? "#2f3549" : "#24283b")
                                        border.width: 1; border.color: "#414868"
                                        Text { id: oa; anchors.centerIn: parent; text: modelData.cls; font.pixelSize: 10; color: fClass.text === modelData.cls ? "#1a1b26" : "#a9b1d6" }
                                        MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: fClass.text = modelData.cls }
                                    }
                                }
                            }
                            WsField {
                                id: fTitle
                                width: parent.width
                                label: "ONLY IF THE TITLE CONTAINS (OPTIONAL)"
                                placeholder: "e.g. htop, YouTube"
                            }

                            Text { text: "WORKSPACE"; color: "#565f89"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                            Flow {
                                id: wsPick
                                width: parent.width
                                spacing: 4
                                Repeater {
                                    model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0]
                                    delegate: Rectangle {
                                        readonly property bool on: form.ws === modelData
                                        width: Math.floor((wsPick.width - 5 * wsPick.spacing - 1) / 6) * (modelData === 0 ? 2 : 1) + (modelData === 0 ? wsPick.spacing : 0)
                                        height: 28; radius: 6
                                        color: on ? "#7aa2f7" : (wm.containsMouse ? "#2f3549" : "#24283b")
                                        border.width: 1; border.color: on ? "#7aa2f7" : "#414868"
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                visible: modelData > 0
                                                text: page.icons[modelData - 1] || ""
                                                font.family: page.glyphFont; font.pixelSize: 12
                                                color: parent.parent.on ? "#1a1b26" : "#a9b1d6"
                                            }
                                            Text {
                                                text: modelData === 0 ? "Any" : modelData
                                                font.pixelSize: 10; font.bold: parent.parent.on
                                                color: parent.parent.on ? "#1a1b26" : "#a9b1d6"
                                            }
                                        }
                                        MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: form.ws = modelData }
                                    }
                                }
                            }

                            Item {
                                width: parent.width; height: 28
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Jump to the workspace when it opens"; color: "#a9b1d6"; font.pixelSize: 11 }
                                Switch2 { anchors.right: parent.right; on: form.follow; onToggled: form.follow = !form.follow }
                            }
                            Item {
                                width: parent.width; height: 28
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Floating window"; color: "#a9b1d6"; font.pixelSize: 11 }
                                Switch2 { anchors.right: parent.right; on: form.isFloat; onToggled: form.isFloat = !form.isFloat }
                            }

                            Row {
                                spacing: 8
                                BtButton { label: page.editIndex >= 0 ? "Update" : "Add"; accent: "#9ece6a"; height: 28; onClicked: page.saveForm() }
                                BtButton { label: "Cancel"; accent: "#a9b1d6"; height: 28; onClicked: { page.formOpen = false; page.status = "" } }
                            }
                        }
                    }
                }
            }

            // ---- tips
            Rectangle {
                width: parent.width
                height: tipCol.implicitHeight + 24
                radius: 12
                color: "#1f2335"
                Column {
                    id: tipCol
                    x: 12; y: 12
                    width: parent.width - 24
                    spacing: 6
                    Text { text: String.fromCodePoint(0xF0335) + "  Good to know"; font.family: page.glyphFont; color: "#e0af68"; font.pixelSize: 11; font.bold: true }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: "#a9b1d6"; font.pixelSize: 10
                        text: "• A workspace can hold as many apps as you like: add kitty, vim, htop… all to workspace 1."
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: "#a9b1d6"; font.pixelSize: 10
                        text: "• Terminal programs (vim, htop, btop…) run inside kitty, so they follow kitty's rule. To send one somewhere else, start it with its own class — kitty --class htop -e htop — and add a rule for “htop”. Or use “title contains”."
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: "#a9b1d6"; font.pixelSize: 10
                        text: "• Don't know an app's class? Open it, then “Pick a window” (or run xprop WM_CLASS in a terminal and click it). Start with = for an exact match (=obs, not Obsidian)."
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: "#a9b1d6"; font.pixelSize: 10
                        text: "• Windows already open stay where they are; rules apply to apps opened after Apply."
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------- footer: apply / reset
    Column {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        spacing: 8

        Text {
            visible: page.status.length > 0
            width: parent.width
            text: page.status
            color: "#7aa2f7"; font.pixelSize: 10; wrapMode: Text.WordWrap
        }
        Rectangle { width: parent.width; height: 1; color: "#414868" }
        Row {
            width: parent.width
            spacing: 8
            Rectangle {
                width: (parent.width - 8) * 0.62
                height: 34; radius: 9
                color: page.dirty ? (apm.containsMouse ? "#89b4fa" : "#7aa2f7") : "#2f3549"
                Text {
                    anchors.centerIn: parent
                    text: page.dirty ? "Apply  (dwm restarts, windows stay)" : "No changes"
                    color: page.dirty ? "#1a1b26" : "#565f89"; font.pixelSize: 11; font.bold: true
                }
                MouseArea { id: apm; anchors.fill: parent; hoverEnabled: true; enabled: page.dirty; cursorShape: Qt.PointingHandCursor; onClicked: page.apply() }
            }
            Rectangle {
                width: (parent.width - 8) * 0.38
                height: 34; radius: 9
                color: page.confirmReset ? "#f7768e" : (rm.containsMouse ? "#565f89" : "#414868")
                Text {
                    anchors.centerIn: parent
                    text: page.confirmReset ? "Sure? Click again" : "Reset to defaults"
                    color: page.confirmReset ? "#1a1b26" : "#c0caf5"; font.pixelSize: 11; font.bold: true
                }
                MouseArea {
                    id: rm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!page.confirmReset) { page.confirmReset = true; return }
                        page.confirmReset = false
                        Quickshell.execDetached(["dwm-workspaces", "reset"])
                        page.status = "Back to the built-in icons and rules — dwm restarted in place."
                        resetReload.restart()
                    }
                    onExited: page.confirmReset = false
                }
                Timer { id: resetReload; interval: 800; onTriggered: page.reload() }
            }
        }
    }
}
