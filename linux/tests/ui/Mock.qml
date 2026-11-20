import QtQuick 2.15

QtObject {
    id: app
    property string scenario: "pro3"
    property bool airpodsConnected: true
    property bool hideOnStart: false
    property int earDetectionBehavior: 0
    property bool crossDeviceEnabled: false
    property bool notificationsEnabled: true
    property int retryAttempts: 3
    property string phoneMacStatus: ""
    property bool hearingAidEnabled: false
    property var autoStartManager: QtObject { property bool autoStartEnabled: true }
    property var deviceInfo: QtObject {
        id: di
        property string deviceName: "Air4"
        property string podIcon: "podpro.png"
        property string caseIcon: "podpro_case.png"
        property int noiseControlMode: 1
        property bool adaptiveModeActive: noiseControlMode === 3
        property int adaptiveNoiseLevel: 50
        property bool conversationalAwareness: true
        property bool hearingAidEnabled: false
        property bool oneBudANCMode: false
        property bool leftPodInEar: true
        property bool rightPodInEar: true
        property string magicAccEncKey: "00"
        property string magicAccIRK: "00"
        property var battery: QtObject {
            id: bat
            property bool leftPodAvailable: true
            property int leftPodLevel: 94
            property bool leftPodCharging: false
            property bool rightPodAvailable: true
            property int rightPodLevel: 96
            property bool rightPodCharging: false
            property bool caseAvailable: true
            property int caseLevel: 80
            property bool caseCharging: true
            property bool headsetAvailable: false
            property int headsetLevel: 0
            property bool headsetCharging: false
        }
    }
    function setNoiseControlModeInt(i) {}
    function setAdaptiveNoiseLevel(v) {}
    function setConversationalAwareness(b) {}
    function setHearingAidEnabled(b) {}
    function setCrossDeviceEnabled(b) {}
    function setPhoneMac(s) {}
    function renameAirPods(s) {}

    Component.onCompleted: {
        switch (scenario) {
        case "long_name":
            di.deviceName = "Jonathan's AirPods Pro with a really long custom name"; break
        case "adaptive":
            di.noiseControlMode = 3; break
        case "left_only":
            bat.rightPodAvailable = false; bat.caseAvailable = false; di.rightPodInEar = false; break
        case "case_only":
            bat.leftPodAvailable = false; bat.rightPodAvailable = false; break
        case "all_low":
            bat.leftPodLevel = 8; bat.rightPodLevel = 100; bat.caseLevel = 3; bat.caseCharging = false; di.leftPodInEar = false; break
        case "max":
            bat.leftPodAvailable = false; bat.rightPodAvailable = false; bat.caseAvailable = false
            bat.headsetAvailable = true; bat.headsetLevel = 64
            di.podIcon = "podmax.png"; di.deviceName = "AirPods Max"; break
        case "disconnected":
            app.airpodsConnected = false
            bat.leftPodAvailable = false; bat.rightPodAvailable = false; bat.caseAvailable = false; break
        }
    }
}
