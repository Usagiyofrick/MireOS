import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: controls

    visible: false

    required property var osd

    Process {
        id: volumeRead

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()

                const match = output.match(/Volume:\s+([0-9.]+)/)

                if (!match)
                    return

                const value = Math.round(
                    parseFloat(match[1]) * 100
                )

                const muted = output.includes("[MUTED]")

                controls.osd.showValue(
                    "Volume",
                    value,
                    muted
                )
            }
        }
    }

    Process {
        id: brightnessRead

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()

                const match = output.match(/,([0-9]+)%,/)

                if (!match)
                    return

                controls.osd.showValue(
                    "Brightness",
                    parseInt(match[1]),
                    false
                )
            }
        }
    }

    Timer {
        id: volumeDelay
        interval: 50
        repeat: false

        onTriggered: {
            controls.refreshVolume()
        }
    }

    Timer {
        id: brightnessDelay
        interval: 50
        repeat: false

        onTriggered: {
            controls.refreshBrightness()
        }
    }

    function refreshVolume() {
        volumeRead.exec([
            "wpctl",
            "get-volume",
            "@DEFAULT_AUDIO_SINK@"
        ])
    }

    function refreshBrightness() {
        brightnessRead.exec([
            "brightnessctl",
            "-m"
        ])
    }

    function volumeUp() {
        Quickshell.execDetached([
            "wpctl",
            "set-volume",
            "-l",
            "1.0",
            "@DEFAULT_AUDIO_SINK@",
            "5%+"
        ])

        volumeDelay.restart()
    }

    function volumeDown() {
        Quickshell.execDetached([
            "wpctl",
            "set-volume",
            "@DEFAULT_AUDIO_SINK@",
            "5%-"
        ])

        volumeDelay.restart()
    }

    function toggleMute() {
        Quickshell.execDetached([
            "wpctl",
            "set-mute",
            "@DEFAULT_AUDIO_SINK@",
            "toggle"
        ])

        volumeDelay.restart()
    }

    function brightnessUp() {
        Quickshell.execDetached([
            "brightnessctl",
            "set",
            "+5%"
        ])

        brightnessDelay.restart()
    }

    function brightnessDown() {
        Quickshell.execDetached([
            "brightnessctl",
            "set",
            "5%-"
        ])

        brightnessDelay.restart()
    }
}
