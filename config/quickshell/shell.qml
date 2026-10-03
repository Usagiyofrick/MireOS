import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    property int activeWorkspace: 1
    property string clockText: ""

    // -----------------------------
    // Existing Mire components
    // -----------------------------

    Notifications {
        id: notifications
    }

    Osd {
        id: osd
    }

    Controls {
        id: controls
        osd: osd
    }

    Launcher {
        id: launcher
    }

    // -----------------------------
    // Global shortcuts
    // -----------------------------

    GlobalShortcut {
        name: "launcher"
        onPressed: launcher.toggle()
    }

    GlobalShortcut {
        name: "volume-up"
        onPressed: controls.volumeUp()
    }

    GlobalShortcut {
        name: "volume-down"
        onPressed: controls.volumeDown()
    }

    GlobalShortcut {
        name: "volume-mute"
        onPressed: controls.toggleMute()
    }

    GlobalShortcut {
        name: "brightness-up"
        onPressed: controls.brightnessUp()
    }

    GlobalShortcut {
        name: "brightness-down"
        onPressed: controls.brightnessDown()
    }

    // -----------------------------
    // Active workspace reader
    // -----------------------------

    Process {
        id: workspaceProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseInt(text.trim())

                if (!isNaN(value))
                    root.activeWorkspace = value
            }
        }
    }

    Timer {
        interval: 300
        running: true
        repeat: true

        onTriggered: {
            workspaceProcess.exec([
                "sh",
                "-c",
                "hyprctl activeworkspace -j | jq -r '.id'"
            ])
        }
    }

    // -----------------------------
    // Clock
    // -----------------------------

    function updateClock() {
        const now = new Date()

        root.clockText =
            String(now.getHours()).padStart(2, "0")
            + ":"
            + String(now.getMinutes()).padStart(2, "0")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: root.updateClock()
    }

    // -----------------------------
    // Top panel
    // -----------------------------

    PanelWindow {
        id: panel

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 34

        color: "transparent"

        Rectangle {
            anchors.fill: parent

            color: "#15111c"

            // ---------------------
            // Left: workspaces
            // ---------------------

            Row {
                id: workspaceRow

                anchors {
                    left: parent.left
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                spacing: 4

                Repeater {
                    model: 9

                    Rectangle {
                        required property int index

                        property int workspaceNumber: index + 1

                        width: 24
                        height: 24

                        radius: 7

                        color:
                            root.activeWorkspace === workspaceNumber
                            ? "#9b6cff"
                            : "transparent"

                        Text {
                            anchors.centerIn: parent

                            text: parent.workspaceNumber

                            color:
                                root.activeWorkspace === parent.workspaceNumber
                                ? "#15111c"
                                : "#8e8798"

                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.bold:
                                root.activeWorkspace === parent.workspaceNumber
                        }

                        MouseArea {
                            anchors.fill: parent

                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                Quickshell.execDetached([
                                    "hyprctl",
                                    "dispatch",
                                    "workspace",
                                    String(parent.workspaceNumber)
                                ])
                            }
                        }
                    }
                }
            }

            // ---------------------
            // Center: Mire
            // ---------------------

            Text {
                anchors.centerIn: parent

                text: "Mire"

                color: "#b794f4"

                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
            }

            // ---------------------
            // Right: battery + clock
            // ---------------------

            Row {
                anchors {
                    right: parent.right
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }

                spacing: 14

                Battery {
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.clockText

                    color: "#e8e4ee"

                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                }
            }
        }
    }
}
