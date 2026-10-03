import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellRoot {
    Colors {
        id: colors
    }

    Notifications {}

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

    GlobalShortcut {
        name: "launcher"
        description: "Open Mire launcher"
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

    PanelWindow {
        id: bar

        property string currentTime: Qt.formatDateTime(new Date(), "HH:mm")

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 34
        color: "transparent"

        Timer {
            interval: 1000
            running: true
            repeat: true

            onTriggered: {
                bar.currentTime = Qt.formatDateTime(
                    new Date(),
                    "HH:mm"
                )
            }
        }

        Rectangle {
            anchors.fill: parent
            color: colors.background

            RowLayout {
                anchors.fill: parent

                anchors.leftMargin: 10
                anchors.rightMargin: 10

                spacing: 14

                Row {
                    spacing: 6

                    Repeater {
                        model: Hyprland.workspaces

                        Rectangle {
                            required property var modelData

                            width: 28
                            height: 24
                            radius: 6

                            color:
                                modelData.focused
                                ? colors.primary
                                : colors.surface2

                            Text {
                                anchors.centerIn: parent

                                text: modelData.name
                                color: colors.text

                                font.pixelSize: 13
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    modelData.activate()
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "Mire"

                    color: colors.primarySoft

                    font.pixelSize: 15
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: bar.currentTime

                    color: colors.text
                    font.pixelSize: 14
                }
            }
        }
    }
}
