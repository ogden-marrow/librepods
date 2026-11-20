pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: mainWindow
    visible: !airPodsTrayApp.hideOnStart
    width: 460
    height: 640
    minimumWidth: 440
    minimumHeight: 560
    title: "LibrePods"
    Material.theme: Material.Dark
    Material.accent: "#0A84FF"
    Material.background: "#16181F"
    Material.primary: "#1F2330"
    objectName: "mainWindowObject"

    onClosing: mainWindow.visible = false

    function reopen(pageToLoad) {
        if (pageToLoad == "settings")
        {
            if (stackView.depth == 1)
            {
                stackView.push(settingsPage)
            }
        }
        else
        {
            if (stackView.depth > 1)
            {
                stackView.pop()
            }
        }

        if (!mainWindow.visible) {
            mainWindow.visible = true
        }
        raise()
        requestActivate()
    }

    // Mouse area for handling back/forward navigation
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.BackButton && stackView.depth > 1) {
                stackView.pop()
            } else if (mouse.button === Qt.ForwardButton) {
                console.log("Forward button pressed")
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainPage
    }

    FontLoader {
        id: iconFont
        source: "qrc:/icons/assets/fonts/SF-Symbols-6.ttf"
    }

    Component {
        id: mainPage
        Item {
            // Header
            Row {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 20
                spacing: 12
                Image {
                    source: "qrc:/icons/assets/librepods-icon.png"
                    width: 40; height: 40
                    mipmap: true
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        text: airPodsTrayApp.airpodsConnected && airPodsTrayApp.deviceInfo.deviceName !== ""
                              ? airPodsTrayApp.deviceInfo.deviceName : "LibrePods"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    Row {
                        spacing: 6
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: airPodsTrayApp.airpodsConnected ? "#30D158" : "#FF453A"
                        }
                        Label {
                            text: airPodsTrayApp.airpodsConnected ? qsTr("Connected") : qsTr("Disconnected")
                            font.pixelSize: 12
                            opacity: 0.7
                        }
                    }
                }
            }

            // Battery card
            Rectangle {
                id: batteryCard
                anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 20
                anchors.topMargin: 20
                height: batteryRow.implicitHeight + 40
                radius: 18
                color: "#1F2330"
                border.width: 1
                border.color: "#2B3042"

                Row {
                    id: batteryRow
                    anchors.centerIn: parent
                    spacing: 18

                    PodColumn {
                        visible: airPodsTrayApp.deviceInfo.battery.leftPodAvailable
                        inEar: airPodsTrayApp.deviceInfo.leftPodInEar
                        iconSource: "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.podIcon
                        batteryLevel: airPodsTrayApp.deviceInfo.battery.leftPodLevel
                        isCharging: airPodsTrayApp.deviceInfo.battery.leftPodCharging
                        indicator: "L"
                    }

                    PodColumn {
                        visible: airPodsTrayApp.deviceInfo.battery.rightPodAvailable
                        inEar: airPodsTrayApp.deviceInfo.rightPodInEar
                        iconSource: "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.podIcon
                        batteryLevel: airPodsTrayApp.deviceInfo.battery.rightPodLevel
                        isCharging: airPodsTrayApp.deviceInfo.battery.rightPodCharging
                        indicator: "R"
                    }

                    PodColumn {
                        visible: airPodsTrayApp.deviceInfo.battery.caseAvailable
                        inEar: true
                        iconSource: "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.caseIcon
                        batteryLevel: airPodsTrayApp.deviceInfo.battery.caseLevel
                        isCharging: airPodsTrayApp.deviceInfo.battery.caseCharging
                    }

                    PodColumn {
                        visible: airPodsTrayApp.deviceInfo.battery.headsetAvailable
                        inEar: true
                        iconSource: "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.podIcon
                        batteryLevel: airPodsTrayApp.deviceInfo.battery.headsetLevel
                        isCharging: airPodsTrayApp.deviceInfo.battery.headsetCharging
                    }

                    Label {
                        visible: !airPodsTrayApp.airpodsConnected
                        text: qsTr("Connect your AirPods to see battery status")
                        opacity: 0.6
                    }
                }
            }

            // Controls card
            Rectangle {
                id: controlsCard
                visible: airPodsTrayApp.airpodsConnected
                anchors.top: batteryCard.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 20
                anchors.topMargin: 16
                height: controlsColumn.implicitHeight + 40
                radius: 18
                color: "#1F2330"
                border.width: 1
                border.color: "#2B3042"

                Column {
                    id: controlsColumn
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    Label {
                        text: qsTr("Noise Control")
                        font.pixelSize: 13
                        opacity: 0.6
                    }

                    SegmentedControl {
                        width: parent.width
                        model: [qsTr("Off"), qsTr("Noise Cancellation"), qsTr("Transparency"), qsTr("Adaptive")]
                        currentIndex: airPodsTrayApp.deviceInfo.noiseControlMode
                        onCurrentIndexChanged: airPodsTrayApp.setNoiseControlModeInt(currentIndex)
                    }

                    Slider {
                        width: parent.width
                        visible: airPodsTrayApp.deviceInfo.adaptiveModeActive
                        from: 0
                        to: 100
                        stepSize: 1
                        value: airPodsTrayApp.deviceInfo.adaptiveNoiseLevel

                        Timer {
                            id: debounceTimer
                            interval: 500
                            onTriggered: if (!parent.pressed) airPodsTrayApp.setAdaptiveNoiseLevel(parent.value)
                        }

                        onPressedChanged: if (!pressed) airPodsTrayApp.setAdaptiveNoiseLevel(value)
                        onValueChanged: if (pressed) debounceTimer.restart()

                        Label {
                            text: qsTr("Adaptive Noise Level: ") + parent.value
                            anchors.top: parent.bottom
                            font.pixelSize: 12
                            opacity: 0.6
                        }
                    }

                    Switch {
                        width: parent.width
                        text: qsTr("Conversational Awareness")
                        checked: airPodsTrayApp.deviceInfo.conversationalAwareness
                        onCheckedChanged: airPodsTrayApp.setConversationalAwareness(checked)
                    }

                    Switch {
                        width: parent.width
                        text: qsTr("Hearing Aid")
                        checked: airPodsTrayApp.deviceInfo.hearingAidEnabled
                        onCheckedChanged: airPodsTrayApp.setHearingAidEnabled(checked)
                    }
                }
            }

            // Heart rate card (AirPods Pro 3 and later)
            Rectangle {
                id: heartRateCard
                visible: airPodsTrayApp.airpodsConnected
                anchors.top: controlsCard.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 20
                anchors.topMargin: 16
                height: hrRow.implicitHeight + 40
                radius: 18
                color: "#1F2330"
                border.width: 1
                border.color: "#2B3042"

                Row {
                    id: hrRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    Label {
                        id: heartGlyph
                        anchors.verticalCenter: parent.verticalCenter
                        text: "♥"
                        font.pixelSize: 34
                        color: airPodsTrayApp.deviceInfo.heartRate > 0 ? "#FF453A" : "#5A5F73"

                        SequentialAnimation on scale {
                            running: airPodsTrayApp.deviceInfo.heartRate > 0
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.2; duration: 200; easing.type: Easing.OutQuad }
                            NumberAnimation { to: 1.0; duration: 200; easing.type: Easing.InQuad }
                            PauseAnimation { duration: Math.max(100, 60000 / Math.max(airPodsTrayApp.deviceInfo.heartRate, 1) - 400) }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - heartGlyph.width - hrSwitch.width - 28

                        Row {
                            spacing: 6
                            Label {
                                text: airPodsTrayApp.deviceInfo.heartRate > 0 ? airPodsTrayApp.deviceInfo.heartRate : "--"
                                font.pixelSize: 30
                                font.weight: Font.DemiBold
                            }
                            Label {
                                text: qsTr("BPM")
                                font.pixelSize: 13
                                opacity: 0.6
                                anchors.baseline: parent.children[0].baseline
                            }
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            font.pixelSize: 11
                            opacity: 0.6
                            text: !airPodsTrayApp.deviceInfo.heartRateMonitoring
                                  ? qsTr("Heart rate monitoring is off")
                                  : (airPodsTrayApp.deviceInfo.heartRate > 0
                                     ? qsTr("Live reading")
                                     : qsTr("Waiting for a reading. Wear both AirPods Pro 3 and stay still."))
                        }
                    }

                    Switch {
                        id: hrSwitch
                        anchors.verticalCenter: parent.verticalCenter
                        checked: airPodsTrayApp.deviceInfo.heartRateMonitoring
                        onToggled: airPodsTrayApp.setHeartRateEnabled(checked)
                    }
                }
            }

            RoundButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 16
                flat: true
                font.family: iconFont.name
                font.pixelSize: 18
                text: "\uf958"
                onClicked: stackView.push(settingsPage)
            }
        }
    }

    Component {
        id: settingsPage
        Page {
            id: settingsPageItem
            title: qsTr("Settings")

            ScrollView {
                anchors.fill: parent

                Column {
                    width: parent.width
                    spacing: 20
                    padding: 20

                    Label {
                        text: qsTr("Settings")
                        font.pixelSize: 24
                        // center the label
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Column {
                        spacing: 5 // Small gap between label and ComboBox

                        Label {
                            text: qsTr("Pause Behavior When Removing AirPods:")
                        }

                        ComboBox {
                            width: parent.width // Ensures full width
                            model: [qsTr("One Removed"), qsTr("Both Removed"), qsTr("Never")]
                            currentIndex: airPodsTrayApp.earDetectionBehavior
                            onActivated: airPodsTrayApp.earDetectionBehavior = currentIndex
                        }
                    }

                    Switch {
                        text: qsTr("Cross-Device Connectivity with Android")
                        checked: airPodsTrayApp.crossDeviceEnabled
                        onCheckedChanged: {
                            airPodsTrayApp.setCrossDeviceEnabled(checked)
                        }
                    }

                    Switch {
                        text: qsTr("Auto-Start on Login")
                        checked: airPodsTrayApp.autoStartManager.autoStartEnabled
                        onCheckedChanged: airPodsTrayApp.autoStartManager.autoStartEnabled = checked
                    }

                    Switch {
                        text: qsTr("Enable System Notifications")
                        checked: airPodsTrayApp.notificationsEnabled
                        onCheckedChanged: airPodsTrayApp.notificationsEnabled = checked
                    }

                    Switch {
                        visible: airPodsTrayApp.airpodsConnected
                        text: qsTr("One Bud ANC Mode")
                        checked: airPodsTrayApp.deviceInfo.oneBudANCMode
                        onCheckedChanged: airPodsTrayApp.deviceInfo.oneBudANCMode = checked

                        ToolTip {
                            visible: parent.hovered
                            text: qsTr("Enable ANC when using one AirPod\n(More noise reduction, but uses more battery)")
                            delay: 500
                        }
                    }

                    Row {
                        spacing: 5
                        Label {
                            text: qsTr("Bluetooth Retry Attempts:")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        SpinBox {
                            from: 1
                            to: 10
                            value: airPodsTrayApp.retryAttempts
                            onValueChanged: airPodsTrayApp.retryAttempts = value
                        }
                    }

                    Row {
                        spacing: 10
                        visible: airPodsTrayApp.airpodsConnected

                        TextField {
                            id: newNameField
                            placeholderText: airPodsTrayApp.deviceInfo.deviceName
                            maximumLength: 32
                        }

                        Button {
                            text: qsTr("Rename")
                            onClicked: airPodsTrayApp.renameAirPods(newNameField.text)
                        }
                    }

                    Row {
                        spacing: 10
                        visible: airPodsTrayApp.airpodsConnected

                        TextField {
                            id: newPhoneMacField
                            placeholderText: (PHONE_MAC_ADDRESS !== "" ? PHONE_MAC_ADDRESS : "00:00:00:00:00:00")
                            maximumLength: 32
                        }

                        Button {
                            text: qsTr("Change Phone MAC")
                            onClicked: airPodsTrayApp.setPhoneMac(newPhoneMacField.text)
                        }
                    }


                    Button {
                        text: qsTr("Show Magic Cloud Keys QR")
                        onClicked: keysQrDialog.show()
                    }

                    KeysQRDialog {
                        id: keysQrDialog
                        encKey: airPodsTrayApp.deviceInfo.magicAccEncKey
                        irk: airPodsTrayApp.deviceInfo.magicAccIRK
                    }
                }
            }

            // Floating back button
            RoundButton {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 10
                font.family: iconFont.name
                font.pixelSize: 18
                text: "\uecb1" // U+ECB1
                onClicked: stackView.pop()
            }
        }
    }
}
