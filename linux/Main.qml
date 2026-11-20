pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: mainWindow
    visible: !airPodsTrayApp.hideOnStart
    width: 460
    height: 640
    minimumWidth: 320
    minimumHeight: 420
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
            id: pageRoot

            Flickable {
                id: flick
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: content.height + 40
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { }

                Column {
                    id: content
                    y: 20
                    x: Math.round((flick.width - width) / 2)
                    width: Math.min(flick.width - 40, 520)
                    spacing: 16

                    // Header
                    Item {
                        id: header
                        width: parent.width
                        height: 44

                        Image {
                            id: appIcon
                            source: "qrc:/icons/assets/librepods-icon.png"
                            width: 40; height: 40
                            anchors.verticalCenter: parent.verticalCenter
                            mipmap: true
                        }

                        Column {
                            anchors.left: appIcon.right
                            anchors.leftMargin: 12
                            anchors.right: gear.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                width: parent.width
                                elide: Text.ElideRight
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

                        RoundButton {
                            id: gear
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            flat: true
                            font.family: iconFont.name
                            font.pixelSize: 18
                            text: "\uf958"
                            onClicked: stackView.push(settingsPage)
                        }
                    }

                    // Battery card: the pod row shrinks to fit instead of overflowing.
                    Rectangle {
                        id: batteryCard
                        width: parent.width
                        readonly property real fit: Math.min(1, (width - 32) / Math.max(batteryRow.implicitWidth, 1))
                        readonly property bool hasDevice: airPodsTrayApp.airpodsConnected
                        height: (hasDevice ? batteryRow.implicitHeight * fit : emptyLabel.implicitHeight) + 40
                        radius: 18
                        color: "#1F2330"
                        border.width: 1
                        border.color: "#2B3042"

                        Row {
                            id: batteryRow
                            visible: batteryCard.hasDevice
                            anchors.centerIn: parent
                            spacing: 18
                            scale: batteryCard.fit

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
                        }

                        Label {
                            id: emptyLabel
                            visible: !batteryCard.hasDevice
                            anchors.centerIn: parent
                            width: parent.width - 40
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: qsTr("Connect your AirPods to see battery status")
                            opacity: 0.6
                        }
                    }

                    // Controls card
                    Rectangle {
                        id: controlsCard
                        visible: airPodsTrayApp.airpodsConnected
                        width: parent.width
                        height: controlsColumn.implicitHeight + 40
                        radius: 18
                        color: "#1F2330"
                        border.width: 1
                        border.color: "#2B3042"

                        Column {
                            id: controlsColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 20
                            spacing: 14

                            Label {
                                text: qsTr("Noise Control")
                                font.pixelSize: 13
                                opacity: 0.6
                            }

                            SegmentedControl {
                                width: parent.width
                                model: [qsTr("Off"), qsTr("Noise Cancel"), qsTr("Transparency"), qsTr("Adaptive")]
                                currentIndex: airPodsTrayApp.deviceInfo.noiseControlMode
                                onActivated: (index) => airPodsTrayApp.setNoiseControlModeInt(index)
                            }

                            Column {
                                width: parent.width
                                visible: airPodsTrayApp.deviceInfo.adaptiveModeActive
                                spacing: 2

                                Slider {
                                    id: adaptiveSlider
                                    width: parent.width
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                    value: airPodsTrayApp.deviceInfo.adaptiveNoiseLevel

                                    Timer {
                                        id: debounceTimer
                                        interval: 500
                                        onTriggered: if (!adaptiveSlider.pressed) airPodsTrayApp.setAdaptiveNoiseLevel(adaptiveSlider.value)
                                    }

                                    onPressedChanged: if (!pressed) airPodsTrayApp.setAdaptiveNoiseLevel(value)
                                    onValueChanged: if (pressed) debounceTimer.restart()
                                }

                                Label {
                                    text: qsTr("Adaptive Noise Level: ") + adaptiveSlider.value
                                    font.pixelSize: 12
                                    opacity: 0.6
                                }
                            }

                            WrappingSwitch {
                                width: parent.width
                                text: qsTr("Conversational Awareness")
                                checked: airPodsTrayApp.deviceInfo.conversationalAwareness
                                onCheckedChanged: airPodsTrayApp.setConversationalAwareness(checked)
                            }

                            WrappingSwitch {
                                width: parent.width
                                text: qsTr("Hearing Aid")
                                checked: airPodsTrayApp.deviceInfo.hearingAidEnabled
                                onCheckedChanged: airPodsTrayApp.setHearingAidEnabled(checked)
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: settingsPage
        Page {
            id: settingsPageItem
            title: qsTr("Settings")

            Flickable {
                id: settingsFlick
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: settingsColumn.height + 40
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { }

                Column {
                    id: settingsColumn
                    y: 20
                    x: Math.round((settingsFlick.width - width) / 2)
                    width: Math.min(settingsFlick.width - 40, 520)
                    spacing: 18

                    // Header: back button + title
                    Item {
                        width: parent.width
                        height: 44

                        RoundButton {
                            id: backButton
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: iconFont.name
                            font.pixelSize: 18
                            text: "\uecb1" // U+ECB1
                            onClicked: stackView.pop()
                        }

                        Label {
                            anchors.left: backButton.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: qsTr("Settings")
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 5 // Small gap between label and ComboBox

                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: qsTr("Pause Behavior When Removing AirPods:")
                        }

                        ComboBox {
                            width: parent.width
                            model: [qsTr("One Removed"), qsTr("Both Removed"), qsTr("Never")]
                            currentIndex: airPodsTrayApp.earDetectionBehavior
                            onActivated: airPodsTrayApp.earDetectionBehavior = currentIndex
                        }
                    }

                    WrappingSwitch {
                        width: parent.width
                        text: qsTr("Cross-Device Connectivity with Android")
                        checked: airPodsTrayApp.crossDeviceEnabled
                        onCheckedChanged: {
                            airPodsTrayApp.setCrossDeviceEnabled(checked)
                        }
                    }

                    WrappingSwitch {
                        width: parent.width
                        text: qsTr("Auto-Start on Login")
                        checked: airPodsTrayApp.autoStartManager.autoStartEnabled
                        onCheckedChanged: airPodsTrayApp.autoStartManager.autoStartEnabled = checked
                    }

                    WrappingSwitch {
                        width: parent.width
                        text: qsTr("Enable System Notifications")
                        checked: airPodsTrayApp.notificationsEnabled
                        onCheckedChanged: airPodsTrayApp.notificationsEnabled = checked
                    }

                    WrappingSwitch {
                        width: parent.width
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

                    RowLayout {
                        width: parent.width
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: qsTr("Bluetooth Retry Attempts:")
                        }
                        SpinBox {
                            from: 1
                            to: 10
                            value: airPodsTrayApp.retryAttempts
                            onValueChanged: airPodsTrayApp.retryAttempts = value
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 10
                        visible: airPodsTrayApp.airpodsConnected

                        TextField {
                            id: newNameField
                            Layout.fillWidth: true
                            Layout.minimumWidth: 80
                            placeholderText: airPodsTrayApp.deviceInfo.deviceName
                            maximumLength: 32
                        }

                        Button {
                            text: qsTr("Rename")
                            onClicked: airPodsTrayApp.renameAirPods(newNameField.text)
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 10
                        visible: airPodsTrayApp.airpodsConnected

                        TextField {
                            id: newPhoneMacField
                            Layout.fillWidth: true
                            Layout.minimumWidth: 80
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
        }
    }
}
