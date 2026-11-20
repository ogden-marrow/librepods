pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15

// Segmented selector. Single pill row when there is room, 2-column grid when narrow.
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

    readonly property int segmentHeight: 36
    readonly property int count: model.length
    // Each segment needs roughly 84 px for labels like "Transparency".
    readonly property int columns: count > 0 && availableWidth >= count * 84 ? count : Math.min(2, Math.max(count, 1))
    readonly property int rows: count > 0 ? Math.ceil(count / columns) : 1

    padding: 3
    implicitHeight: rows * segmentHeight + 2 * padding
    focusPolicy: Qt.StrongFocus
    activeFocusOnTab: true

    background: Rectangle {
        radius: root.rows === 1 ? height / 2 : 18
        color: root.trackColor
        border.width: root.activeFocus ? 1 : 0
        border.color: root.selectedColor
    }

    contentItem: Grid {
        columns: root.columns
        Repeater {
            model: root.model

            delegate: Item {
                id: segment
                required property int index
                required property string modelData
                width: root.columns > 0 ? root.availableWidth / root.columns : 0
                height: root.segmentHeight

                Rectangle {
                    anchors.fill: parent
                    radius: root.rows === 1 ? height / 2 : 15
                    color: root.selectedColor
                    visible: root.currentIndex === segment.index
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
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

    function select(index) {
        if (index < 0 || index >= count || index === currentIndex)
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
