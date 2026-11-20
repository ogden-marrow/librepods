pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15

// Pill-shaped segmented selector with equal-width segments.
Control {
    id: root

    property var model: ["Option 1", "Option 2"]
    property int currentIndex: 0

    // Emitted only when the user picks a segment (not when currentIndex is bound).
    signal activated(int index)

    readonly property color trackColor: "#2A2F42"
    readonly property color selectedColor: "#0A84FF"
    readonly property color textColor: "#C7CBDA"
    readonly property color selectedTextColor: "#FFFFFF"

    implicitHeight: 40
    padding: 3
    focusPolicy: Qt.StrongFocus
    activeFocusOnTab: true

    background: Rectangle {
        radius: height / 2
        color: root.trackColor
        border.width: root.activeFocus ? 1 : 0
        border.color: root.selectedColor
    }

    contentItem: Item {
        // Sliding highlight
        Rectangle {
            id: highlight
            readonly property real segmentWidth: root.model.length > 0 ? parent.width / root.model.length : 0
            x: root.currentIndex * segmentWidth
            width: segmentWidth
            height: parent.height
            radius: height / 2
            color: root.selectedColor

            Behavior on x {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }

        Row {
            anchors.fill: parent

            Repeater {
                model: root.model

                delegate: Item {
                    id: segment
                    required property int index
                    required property string modelData
                    width: root.model.length > 0 ? parent.width / root.model.length : 0
                    height: parent.height

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 2
                        anchors.rightMargin: 2
                        text: segment.modelData
                        font.pixelSize: 12
                        font.weight: root.currentIndex === segment.index ? Font.DemiBold : Font.Normal
                        color: root.currentIndex === segment.index ? root.selectedTextColor : root.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.select(segment.index)
                    }
                }
            }
        }
    }

    function select(index) {
        if (index < 0 || index >= model.length || index === currentIndex)
            return
        currentIndex = index
        activated(index)
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) {
            select(currentIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            select(currentIndex + 1)
            event.accepted = true
        }
    }
}
