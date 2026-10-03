import Quickshell
import QtQuick

PanelWindow {
    id: osd

    anchors {
        left: true
        right: true
        bottom: true
    }

    implicitHeight: 92

    visible: false
    color: "transparent"
    focusable: false

    exclusionMode: ExclusionMode.Ignore

    property string label: ""
    property int value: 0
    property bool muted: false

    Timer {
        id: hideTimer
        interval: 1100
        repeat: false

        onTriggered: osd.visible = false
    }

    Rectangle {
        width: 200
        height: 30

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }

        radius: 12
        color: "#1d1826"

        border.width: 0.5
        border.color: "#9b6cff"

        Row {
            anchors.centerIn: parent
            spacing: 12

            Text {
                text: osd.label
                color: "#b794f4"
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                text: osd.muted
                    ? "Muted"
                    : osd.value + "%"

                color: "#e8e4ee"
                font.pixelSize: 14
            }
        }
    }

    function showValue(newLabel, newValue, newMuted) {
        label = newLabel
        value = newValue
        muted = newMuted

        visible = true
        hideTimer.restart()
    }
}
