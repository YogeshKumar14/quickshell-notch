import QtQuick
import Qt5Compat.GraphicalEffects
import "../theme"

Item {
    id: root
    property string name: ""
    property color color: Style.textPrimary
    property int size: 24

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        source: name !== "" ? "file:///home/yogesh/.config/quickshell/assets/icons/" + name + ".svg" : ""
        sourceSize: Qt.size(size, size)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: img
        source: img
        color: root.color
        visible: img.status === Image.Ready
        
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
