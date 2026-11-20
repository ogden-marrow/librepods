import QtQuick 2.15
import QtQuick.Controls 2.15

// Switch whose label wraps instead of being clipped on narrow windows.
Switch {
    id: control

    contentItem: Label {
        text: control.text
        wrapMode: Text.WordWrap
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator ? control.indicator.width + control.spacing : 0
        opacity: control.enabled ? 1.0 : 0.5
    }
}
