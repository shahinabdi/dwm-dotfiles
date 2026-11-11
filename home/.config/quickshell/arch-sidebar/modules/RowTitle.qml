import QtQuick

Row {
    property string title
    property string value
    width: parent.width
    Text { text: parent.title; color: "#c0caf5"; font.pixelSize: 14; font.bold: true; width: parent.width - v.width }
    Text { id: v; text: parent.value; color: "#7aa2f7"; font.pixelSize: 12 }
}
