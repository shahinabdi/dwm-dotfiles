import QtQuick
import Quickshell
import Quickshell.Io

// Window layouts (dwm) as an accordion: collapsed = current layout, expanded = a grid of
// mini diagrams for all 9 layouts with a description, plus master count / size controls.
// Everything goes through ~/.local/bin/dwm-layout (dwm's _DWM_CMD / _DWM_STATE properties).
Item {
    id: root

    width: 300
    height: card.height

    property bool expanded: false
    property int current: 0
    property string symbol: "[]="
    property real mfact: 0.55
    property int nmaster: 1
    property int windows: 0
    property int hovered: -1
    property bool gaps: true
    property int gapInner: 10
    property int gapOuter: 10
    property bool smartGaps: true

    // index order = layouts[] in dwm's config.h
    readonly property var layouts: [
        { name: "Tile", sym: "[]=", keys: "Super + T",
          desc: "Master on the left, the other windows stacked on the right. The classic dwm layout: an editor or browser big, terminals beside it.",
          r: [[0,0,.55,1],[.55,0,.45,.34],[.55,.34,.45,.33],[.55,.67,.45,.33]] },
        { name: "Bottom stack", sym: "TTT", keys: "Super + Shift + →",
          desc: "Master across the top, the others side by side below. Good on wide screens, and for logs or a terminal under an editor.",
          r: [[0,0,1,.55],[0,.55,.34,.45],[.34,.55,.33,.45],[.67,.55,.33,.45]] },
        { name: "Centered", sym: "|M|", keys: "Super + C",
          desc: "Centered master: the main window in the middle, the others split between the left and right edges. Great on ultrawide monitors and for reading.",
          r: [[.25,0,.5,1],[0,0,.25,.5],[0,.5,.25,.5],[.75,0,.25,.5],[.75,.5,.25,.5]] },
        { name: "Grid", sym: "###", keys: "Super + G",
          desc: "Every window gets an equal cell. Best for watching many terminals, logs or dashboards at the same time.",
          r: [[0,0,.5,.5],[.5,0,.5,.5],[0,.5,.5,.5],[.5,.5,.5,.5]] },
        { name: "Deck", sym: "[D]", keys: "Super + Shift + →",
          desc: "Master on the left, the rest stacked like cards on the right with only the top one visible. Two big windows; the others are one Super + J away.",
          r: [[0,0,.55,1],[.63,.12,.37,.88],[.59,.06,.37,.88],[.55,0,.37,.88]] },
        { name: "Spiral", sym: "[@]", keys: "Super + Shift + →",
          desc: "Fibonacci spiral: each new window takes half of the previous one, turning towards the centre. Looks great and keeps the first window big.",
          r: [[0,0,.5,1],[.5,0,.5,.5],[.75,.5,.25,.5],[.5,.75,.25,.25],[.5,.5,.25,.25]] },
        { name: "Dwindle", sym: "[\\]", keys: "Super + Shift + →",
          desc: "Fibonacci dwindle: like spiral, but always shrinking towards the bottom-right corner. Very predictable with many windows.",
          r: [[0,0,.5,1],[.5,0,.5,.5],[.5,.5,.25,.5],[.75,.5,.25,.25],[.75,.75,.25,.25]] },
        { name: "Monocle", sym: "[M]", keys: "Super + M",
          desc: "One window fills the whole screen; the others wait behind it (Super + J / K to flip through). Maximum focus. The bar shows how many windows there are.",
          r: [[0,0,1,1]] },
        { name: "Floating", sym: "><>", keys: "Super + Shift + →",
          desc: "Windows keep their own size and position, like a classic desktop. Move with Super + drag, resize with Super + right-drag.",
          r: [[.06,.08,.52,.48],[.4,.34,.54,.56],[.14,.56,.36,.36]] }
    ]

    function refresh() { stateProcess.running = true }

    Process {
        id: stateProcess
        running: true
        command: ["dwm-layout", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const kv of this.text.trim().split(" ")) {
                    const i = kv.indexOf("=")
                    if (i < 0) continue
                    const k = kv.slice(0, i), v = kv.slice(i + 1)
                    if (k === "layout") root.current = Number(v)
                    else if (k === "symbol") root.symbol = v
                    else if (k === "mfact") root.mfact = Number(v)
                    else if (k === "nmaster") root.nmaster = Number(v)
                    else if (k === "windows") root.windows = Number(v)
                    else if (k === "gaps") root.gaps = v === "1"
                    else if (k === "gapinner") root.gapInner = Number(v)
                    else if (k === "gapouter") root.gapOuter = Number(v)
                    else if (k === "smartgaps") root.smartGaps = v === "1"
                }
            }
        }
    }

    // every click starts its own command (rapid clicks are never dropped), then refresh
    Timer { id: refreshSoon; interval: 350; onTriggered: root.refresh() }

    function run(args) {
        Quickshell.execDetached(["dwm-layout"].concat(args))
        refreshSoon.restart()
    }

    Timer { interval: 1500; running: true; repeat: true; onTriggered: root.refresh() }

    Rectangle {
        id: card
        width: parent.width
        height: header.height + (root.expanded ? body.implicitHeight + 14 : 0) + 28
        radius: 15
        color: "#24283b"
        clip: true
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // ---------------------------------------------------------------- header
        Item {
            id: header
            x: 14
            y: 14
            width: parent.width - 28
            height: 40

            Diagram {
                id: headDia
                width: 46
                height: 32
                anchors.verticalCenter: parent.verticalCenter
                rects: root.layouts[Math.max(0, Math.min(8, root.current))].r
            }

            Column {
                anchors.left: headDia.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    text: root.layouts[Math.max(0, Math.min(8, root.current))].name + "   " + root.symbol
                    color: "#c0caf5"
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    text: root.windows + (root.windows === 1 ? " window" : " windows") + "  ·  master "
                          + root.nmaster + "  ·  " + Math.round(root.mfact * 100) + "%  ·  "
                          + (root.gaps ? "gaps " + root.gapInner + "/" + root.gapOuter : "no gaps")
                    width: header.width - 46 - 12 - 40
                    elide: Text.ElideRight
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
                onClicked: { root.expanded = !root.expanded; root.refresh() }
            }
        }

        // ---------------------------------------------------------------- body
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

            // 3 x 3 layout tiles
            Grid {
                id: tiles
                width: parent.width
                columns: 3
                spacing: 8
                readonly property real cell: (width - 2 * spacing) / 3

                Repeater {
                    model: root.layouts.length
                    Rectangle {
                        required property int index
                        readonly property bool on: index === root.current
                        width: tiles.cell
                        height: tiles.cell * 0.78
                        radius: 10
                        color: on ? "#7aa2f7" : (tm.containsMouse ? "#2f3549" : "#1f2335")
                        border.width: 1
                        border.color: on || tm.containsMouse ? "#7aa2f7" : "#414868"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Diagram {
                            x: 10
                            y: 9
                            width: parent.width - 20
                            height: parent.height - 34
                            rects: root.layouts[index].r
                            active: parent.on
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            text: root.layouts[index].name
                            font.pixelSize: 10
                            font.bold: parent.on
                            color: parent.on ? "#1a1b26" : "#a9b1d6"
                        }
                        MouseArea {
                            id: tm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.hovered = index
                            onExited: if (root.hovered === index) root.hovered = -1
                            onClicked: { root.current = index; root.run(["set", String(index)]) }
                        }
                    }
                }
            }

            // description of the hovered (or current) layout
            Rectangle {
                width: parent.width
                height: desc.implicitHeight + 24
                radius: 10
                color: "#1f2335"
                border.width: 1
                border.color: "#414868"
                Column {
                    id: desc
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 6
                    readonly property var l: root.layouts[root.hovered >= 0 ? root.hovered : Math.max(0, Math.min(8, root.current))]
                    Row {
                        width: parent.width
                        Text { text: desc.l.name + "  " + desc.l.sym; color: "#c0caf5"; font.pixelSize: 13; font.bold: true; width: parent.width - k.width }
                        Text { id: k; text: desc.l.keys; color: "#7aa2f7"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Text {
                        width: parent.width
                        text: desc.l.desc
                        color: "#a9b1d6"
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        lineHeight: 1.15
                    }
                }
            }

            // master count
            Row {
                width: parent.width
                spacing: 8
                Column {
                    width: parent.width - 3 * 34 - 2 * 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Master windows"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true }
                    Text { text: "share the big area · Super+I/U"; color: "#565f89"; font.pixelSize: 9; width: parent.width; elide: Text.ElideRight }
                }
                ActionButton {
                    width: 34; height: 30; implicitHeight: 30; radius: 8
                    glyph: 0xF0374; iconSize: 14; label: ""
                    onClicked: root.run(["nmaster", "-1"])
                }
                Text {
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.nmaster
                    color: "#7aa2f7"
                    font.pixelSize: 13
                    font.bold: true
                }
                ActionButton {
                    width: 34; height: 30; implicitHeight: 30; radius: 8
                    glyph: 0xF0415; iconSize: 14; label: ""
                    onClicked: root.run(["nmaster", "+1"])
                }
            }

            // master size
            Row {
                width: parent.width
                spacing: 8
                Column {
                    width: parent.width - 3 * 34 - 2 * 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Master size"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true }
                    Text { text: "of the screen · Super+←/→"; color: "#565f89"; font.pixelSize: 9; width: parent.width; elide: Text.ElideRight }
                }
                ActionButton {
                    width: 34; height: 30; implicitHeight: 30; radius: 8
                    glyph: 0xF0374; iconSize: 14; label: ""
                    onClicked: root.run(["mfact", "-0.05"])
                }
                Text {
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: Math.round(root.mfact * 100) + "%"
                    color: "#7aa2f7"
                    font.pixelSize: 12
                    font.bold: true
                }
                ActionButton {
                    width: 34; height: 30; implicitHeight: 30; radius: 8
                    glyph: 0xF0415; iconSize: 14; label: ""
                    onClicked: root.run(["mfact", "+0.05"])
                }
            }

            // ---------------------------------------------------------------- gaps
            Rectangle { width: parent.width; height: 1; color: "#414868" }

            Row {
                width: parent.width
                spacing: 8
                Column {
                    width: parent.width - 58 - 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Gaps"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true }
                    Text { text: "space around windows · Super+Shift+G"; color: "#565f89"; font.pixelSize: 9; width: parent.width; elide: Text.ElideRight }
                }
                Switch2 { on: root.gaps; onToggled: root.run(["gaps", root.gaps ? "off" : "on"]) }
            }

            Row {
                width: parent.width
                spacing: 8
                opacity: root.gaps ? 1 : 0.4
                Column {
                    width: parent.width - 3 * 34 - 2 * 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Inner gap"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true }
                    Text { text: "between windows"; color: "#565f89"; font.pixelSize: 9 }
                }
                ActionButton {
                    width: 34; height: 30; implicitHeight: 30; radius: 8
                    glyph: 0xF0374; iconSize: 14; label: ""
                    onClicked: root.run(["inner", "-2"])
                }
                Text {
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.gapInner + "px"
                    color: "#7aa2f7"
                    font.pixelSize: 12
                    font.bold: true
                }
                ActionButton {
                    width: 34; height: 30; implicitHeight: 30; radius: 8
                    glyph: 0xF0415; iconSize: 14; label: ""
                    onClicked: root.run(["inner", "+2"])
                }
            }

            Row {
                width: parent.width
                spacing: 8
                opacity: root.gaps ? 1 : 0.4
                Column {
                    width: parent.width - 3 * 34 - 2 * 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Outer gap"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true }
                    Text { text: "to the screen edge"; color: "#565f89"; font.pixelSize: 9 }
                }
                ActionButton {
                    width: 34; height: 30; implicitHeight: 30; radius: 8
                    glyph: 0xF0374; iconSize: 14; label: ""
                    onClicked: root.run(["outer", "-2"])
                }
                Text {
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.gapOuter + "px"
                    color: "#7aa2f7"
                    font.pixelSize: 12
                    font.bold: true
                }
                ActionButton {
                    width: 34; height: 30; implicitHeight: 30; radius: 8
                    glyph: 0xF0415; iconSize: 14; label: ""
                    onClicked: root.run(["outer", "+2"])
                }
            }

            Row {
                width: parent.width
                spacing: 8
                opacity: root.gaps ? 1 : 0.4
                Column {
                    width: parent.width - 58 - 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Smart gaps"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true }
                    Text { text: "no gaps when only one window is open"; color: "#565f89"; font.pixelSize: 9; width: parent.width; elide: Text.ElideRight }
                }
                Switch2 { on: root.smartGaps; onToggled: root.run(["smart", root.smartGaps ? "off" : "on"]) }
            }

            Text {
                width: parent.width
                text: "Super + Shift + ← / → cycles layouts · Super + Shift + L opens the layout menu · Super + Shift + ↑ / ↓ resizes gaps"
                color: "#565f89"
                font.pixelSize: 9
                wrapMode: Text.WordWrap
            }

            ResetButton {
                what: "layout & gaps"
                onConfirmed: root.run(["reset"])
            }
        }
    }
}
