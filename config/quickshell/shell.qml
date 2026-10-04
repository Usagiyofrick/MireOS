import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    property string clockText: ""
    property var activeWorkspaces: ({})

    // ------------------------------------------------------------
    // Sungan components
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // Global shortcuts
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // Active workspace per monitor
    // ------------------------------------------------------------

    Process {
        id: monitorProcess

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const monitors = JSON.parse(text)
                    const result = {}

                    for (let i = 0; i < monitors.length; i++) {
                        const monitor = monitors[i]

                        if (monitor.activeWorkspace)
                            result[monitor.name] = monitor.activeWorkspace.id
                    }

                    root.activeWorkspaces = result
                } catch (e) {
                    console.log("Failed to parse Hyprland monitors:", e)
                }
            }
        }
    }

    Timer {
        interval: 250
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            monitorProcess.exec([
                "hyprctl",
                "monitors",
                "-j"
            ])
        }
    }

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // One panel per monitor
    // ------------------------------------------------------------

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: panel

                required property var modelData

                screen: modelData

                property string screenName: modelData.name

                property var workspaceNumbers: {
                    // Acer KA242Y - odd workspaces
                    if (screenName === "DVI-D-1")
                        return [1, 3, 5, 7, 9]

                    // Samsung S24D300 - even workspaces
                    if (screenName === "HDMI-A-1")
                        return [2, 4, 6, 8]

                    // Fallback for unknown monitors
                    return [1, 2, 3, 4, 5, 6, 7, 8, 9]
                }

                property int activeWorkspace:
                    root.activeWorkspaces[screenName] || 0

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

                    // ------------------------------------------------
                    // Workspaces
                    // ------------------------------------------------

                    Row {
                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }

                        spacing: 4

                        Repeater {
                            model: panel.workspaceNumbers

                            Rectangle {
                                required property int index

                                property int workspaceNumber:
                                    panel.workspaceNumbers[index]

                                width: 24
                                height: 24
                                radius: 7

                                color:
                                    panel.activeWorkspace === workspaceNumber
                                    ? "#9b6cff"
                                    : "transparent"

                                Text {
                                    anchors.centerIn: parent

                                    text: parent.workspaceNumber

                                    color:
                                        panel.activeWorkspace === parent.workspaceNumber
                                        ? "#15111c"
                                        : "#8e8798"

                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12

                                    font.bold:
                                        panel.activeWorkspace === parent.workspaceNumber
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

                    // ------------------------------------------------
                    // Center
                    // ------------------------------------------------

                    Text {
                        anchors.centerIn: parent

                        text: "Sungan"

                        color: "#b794f4"

                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    // ------------------------------------------------
                    // Right
                    // ------------------------------------------------

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
    }
}
