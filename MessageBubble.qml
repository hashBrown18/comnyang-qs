import QtQuick

Rectangle {
    required property string message
    color: "#fff8e8"
    border.color: "#5a4740"
    border.width: 2
    radius: 4
    implicitWidth: 220
    implicitHeight: label.implicitHeight + 18

    Text {
        id: label
        anchors.fill: parent
        anchors.margins: 9
        text: parent.message
        color: "#3a2d2a"
        font.pixelSize: 12
        wrapMode: Text.Wrap
    }
}
