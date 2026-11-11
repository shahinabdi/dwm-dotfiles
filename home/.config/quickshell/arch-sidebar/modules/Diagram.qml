import QtQuick

// mini layout diagram: rects are [x, y, w, h] in 0..1 units; the first one is the master
Item {
    id: dia
    property var rects: []
    property bool active: false
    Repeater {
        model: dia.rects
        Rectangle {
            required property var modelData
            required property int index
            x: modelData[0] * dia.width + 1
            y: modelData[1] * dia.height + 1
            width: modelData[2] * dia.width - 2
            height: modelData[3] * dia.height - 2
            radius: 3
            color: dia.active ? (index === 0 ? "#1a1b26" : "#2f3549")
                              : (index === 0 ? "#7aa2f7" : "#414868")
            opacity: dia.active ? 0.9 : (index === 0 ? 0.85 : 1)
            border.width: 1
            border.color: dia.active ? "#1a1b26" : "#24283b"
        }
    }
}
