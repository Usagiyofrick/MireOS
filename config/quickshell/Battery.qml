import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property int percentage: 0
    property string state: "unknown"
    property bool available: false

    visible: available

    implicitWidth: available ? content.implicitWidth : 0
    implicitHeight: available ? content.implicitHeight : 0

    Process {
        id: batteryRead

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()

                if (output.length === 0) {
                    root.available = false
                    return
                }

                const p = output.match(/percentage:\s+([0-9]+)%/)

                if (!p) {
                    root.available = false
                    return
                }

                root.available = true
                root.percentage = parseInt(p[1])

                const s = output.match(/state:\s+([^\n]+)/)

                if (s)
                    root.state = s[1].trim()
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            batteryRead.exec([
                "sh",
                "-c",
                "BAT=$(upower -e | grep -m1 BAT || true); " +
                "[ -n \"$BAT\" ] && upower -i \"$BAT\""
            ])
        }
    }

    property bool charging:
        state === "charging" || state === "fully-charged"

    property color batteryColor: {
        if (charging)
            return "#b794f4"

        if (percentage <= 15)
            return "#d35f5f"

        if (percentage <= 30)
            return "#d7ba7d"

        return "#e8e4ee"
    }

    Row {
        id: content
        spacing: 6

        Text {
            text: root.charging ? "󰂄" : root.batteryIcon()
            color: root.batteryColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.percentage + "%"
            color: root.batteryColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    function batteryIcon() {
        if (percentage <= 10) return "󰁺"
        if (percentage <= 20) return "󰁻"
        if (percentage <= 30) return "󰁼"
        if (percentage <= 40) return "󰁽"
        if (percentage <= 50) return "󰁾"
        if (percentage <= 60) return "󰁿"
        if (percentage <= 70) return "󰂀"
        if (percentage <= 80) return "󰂁"
        if (percentage <= 90) return "󰂂"
        return "󰁹"
    }
}
