import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Wallpaper accordion: collapsed = current wallpaper, expanded = preview, prev / random / next,
// a grid of wallpapers, fit mode and slideshow. Everything goes through ~/.local/bin/dwm-wall.
Item {
    id: root

    width: 300
    height: card.height

    signal requestClose()

    property bool expanded: false
    property string wall: ""
    property string mode: "fill"
    property bool slideshow: false
    property string interval: "15m"
    property int count: 0
    property var walls: []

    function refresh() { statusProcess.running = true; listProcess.running = true }
    function fileName(p) { return p ? p.split("/").pop() : "" }

    Process {
        id: statusProcess
        running: true
        command: ["dwm-wall", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of this.text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i < 0) continue
                    const k = line.slice(0, i), v = line.slice(i + 1)
                    if (k === "wall") root.wall = v
                    else if (k === "mode") root.mode = v
                    else if (k === "slideshow") root.slideshow = v === "1"
                    else if (k === "interval") root.interval = v
                    else if (k === "count") root.count = Number(v)
                }
            }
        }
    }

    Process {
        id: listProcess
        running: true
        command: ["sh", "-c", "dwm-wall list | head -9"]
        stdout: StdioCollector {
            onStreamFinished: root.walls = this.text.split("\n").filter(l => l.length)
        }
    }

    Timer { id: refreshSoon; interval: 400; onTriggered: root.refresh() }
    Timer { interval: 4000; running: true; repeat: true; onTriggered: root.refresh() }

    function run(args, close) {
        if (close) root.requestClose()
        Quickshell.execDetached(close ? ["sh", "-c", "sleep 0.3; dwm-wall " + args.join(" ")]
                                      : ["dwm-wall"].concat(args))
        refreshSoon.restart()
    }

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

            ClippingRectangle {
                id: thumb
                width: 56
                height: 34
                radius: 7
                anchors.verticalCenter: parent.verticalCenter
                color: "#1f2335"
                Image {
                    anchors.fill: parent
                    source: root.wall ? "file://" + root.wall : ""
                    sourceSize.width: 160
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Column {
                anchors.left: thumb.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - thumb.width - 12 - 40
                spacing: 3
                Text { text: "Wallpaper"; color: "#c0caf5"; font.pixelSize: 14; font.bold: true }
                Text {
                    width: parent.width
                    text: (root.fileName(root.wall) || "none") + "  ·  " + root.mode
                          + (root.slideshow ? "  ·  slideshow " + root.interval : "")
                    color: "#7aa2f7"
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
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

            // big preview of the current wallpaper
            ClippingRectangle {
                width: parent.width
                height: width * 9 / 16
                radius: 10
                color: "#1f2335"
                border.width: 1
                border.color: "#414868"
                Image {
                    anchors.fill: parent
                    source: root.wall ? "file://" + root.wall : ""
                    sourceSize.width: 640
                    fillMode: root.mode === "fit" ? Image.PreserveAspectFit
                            : root.mode === "center" ? Image.Pad
                            : root.mode === "tile" ? Image.Tile : Image.PreserveAspectCrop
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: !root.wall
                    text: "No wallpaper yet — add one"
                    color: "#565f89"
                    font.pixelSize: 11
                }
            }

            // prev / random / next / add / folder
            Row {
                id: wbtns
                width: parent.width
                spacing: 6
                readonly property real cellWidth: (width - 4 * spacing) / 5
                ActionButton { width: wbtns.cellWidth; glyph: 0xF0141; label: "Prev";   onClicked: root.run(["prev"]) }
                ActionButton { width: wbtns.cellWidth; glyph: 0xF049D; label: "Random"; onClicked: root.run(["random"]) }
                ActionButton { width: wbtns.cellWidth; glyph: 0xF0142; label: "Next";   onClicked: root.run(["next"]) }
                ActionButton { width: wbtns.cellWidth; glyph: 0xF0415; label: "Add";    accent: "#9ece6a"; onClicked: root.run(["add"], true) }
                ActionButton { width: wbtns.cellWidth; glyph: 0xF0770; label: "Folder"; accent: "#bb9af7"; onClicked: root.run(["open"], true) }
            }

            // grid of the newest wallpapers
            Grid {
                id: wgrid
                width: parent.width
                columns: 3
                spacing: 6
                visible: root.walls.length > 0
                readonly property real cell: (width - 2 * spacing) / 3

                Repeater {
                    model: root.walls
                    ClippingRectangle {
                        required property string modelData
                        readonly property bool on: modelData === root.wall
                        width: wgrid.cell
                        height: wgrid.cell * 9 / 16
                        radius: 7
                        color: "#1f2335"
                        border.width: on ? 2 : 1
                        border.color: on ? "#7aa2f7" : (gm.containsMouse ? "#7aa2f7" : "#414868")
                        Image {
                            anchors.fill: parent
                            anchors.margins: parent.on ? 2 : 0
                            source: "file://" + modelData
                            sourceSize.width: 220
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        MouseArea {
                            id: gm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.wall = modelData; root.run(["set", modelData]) }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: root.count > 9 ? root.count + " wallpapers — Super + W shows them all"
                                     : root.count + (root.count === 1 ? " wallpaper" : " wallpapers") + " in ~/Pictures/Wallpapers"
                color: "#565f89"
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            // fit mode
            RowTitle { title: "Fit"; value: root.mode }
            ChipRow {
                values: ["fill", "fit", "center", "tile"]
                current: root.mode
                label: v => v
                onPicked: v => { root.mode = v; root.run(["mode", v]) }
            }

            // slideshow
            Row {
                width: parent.width
                spacing: 8
                Column {
                    width: parent.width - 58 - 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Slideshow"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true }
                    Text { text: "random wallpaper every " + root.interval; color: "#565f89"; font.pixelSize: 9 }
                }
                Switch2 { on: root.slideshow; onToggled: root.run(["slideshow", root.slideshow ? "off" : "on"]) }
            }
            ChipRow {
                values: ["5m", "15m", "30m", "1h"]
                current: root.interval
                label: v => v
                opacity: root.slideshow ? 1 : 0.5
                onPicked: v => { root.interval = v; root.run(["slideshow", root.slideshow ? "on" : "off", v]) }
            }
        }
    }
}
