import QtQuick
import Quickshell

// Screenshot buttons -> ~/.local/bin/dwm-shot. The sidebar closes first so it is not in the shot.
Item {
    id: root

    width: 300
    height: grid.implicitHeight

    signal requestClose()

    function shot(mode) {
        root.requestClose()
        Quickshell.execDetached(["sh", "-c", "sleep 0.35; dwm-shot " + mode])
    }

    Grid {
        id: grid
        width: parent.width
        columns: 3
        spacing: 8

        readonly property real cellWidth: (width - 2 * spacing) / 3

        ActionButton { width: grid.cellWidth; glyph: 0xF019E; label: "Region";   onClicked: root.shot("region") }
        ActionButton { width: grid.cellWidth; glyph: 0xF0379; label: "Screen";   onClicked: root.shot("full") }
        ActionButton { width: grid.cellWidth; glyph: 0xF05AF; label: "Window";   onClicked: root.shot("window") }
        ActionButton { width: grid.cellWidth; glyph: 0xF03EB; label: "Annotate"; onClicked: root.shot("annotate") }
        ActionButton { width: grid.cellWidth; glyph: 0xF0150; label: "In 5 s";   onClicked: root.shot("delay") }
        ActionButton { width: grid.cellWidth; glyph: 0xF024B; label: "Folder";   onClicked: root.shot("folder") }
    }
}
