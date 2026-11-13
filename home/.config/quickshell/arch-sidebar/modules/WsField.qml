import QtQuick

// Small labelled text field (Workspaces page).
Column {
    id: f
    property string label
    property string placeholder
    property alias text: input.text
    readonly property bool activeFocusInside: input.activeFocus
    property int fontSize: 12
    property string fontFamily: ""
    signal edited()
    spacing: 4

    Text { visible: f.label.length > 0; text: f.label; color: "#565f89"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
    Rectangle {
        width: f.width
        height: 32
        radius: 8
        color: "#1f2335"
        border.width: 1
        border.color: input.activeFocus ? "#7aa2f7" : "#414868"
        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: "#c0caf5"
            font.pixelSize: f.fontSize
            font.family: f.fontFamily.length ? f.fontFamily : font.family
            clip: true
            selectByMouse: true
            onTextEdited: f.edited()
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !input.text && !input.activeFocus
                text: f.placeholder
                color: "#565f89"
                font.pixelSize: 11
            }
        }
    }
}
