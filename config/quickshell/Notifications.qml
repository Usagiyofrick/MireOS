import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Item {
    id: root

    property var currentNotification: null

    NotificationServer {
        id: server

        bodySupported: true
        keepOnReload: true

        onNotification: notification => {
            console.log(
                "NOTIFY:",
                notification.summary,
                notification.body
            )

            notification.tracked = true

            root.currentNotification = notification
            popup.visible = true

            hideTimer.restart()
        }
    }

    PanelWindow {
        id: popup

        anchors {
            top: true
            right: true
        }

        margins {
            top: 48
            right: 14
        }

        implicitWidth: 300
        implicitHeight: 55

        visible: false
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true

        Rectangle {
            anchors.fill: parent

            radius: 12
            color: "#1d1826"

            border.width: 0.5
            border.color: "#9b6cff"

            Column {
                anchors {
                    fill: parent
                    margins: 12
                }

                spacing: 5

                Text {
                    width: parent.width

                    text: root.currentNotification
                        ? root.currentNotification.summary
                        : ""

                    color: "#b794f4"

                    font.pixelSize: 14
                    font.bold: true

                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width

                    text: root.currentNotification
                        ? root.currentNotification.body
                        : ""

                    color: "#e8e4ee"

                    font.pixelSize: 13

                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    hideTimer.stop()

                    const notification = root.currentNotification

                    popup.visible = false
                    root.currentNotification = null

                    if (notification)
                        notification.dismiss()
                }
            }
        }
    }

    Timer {
        id: hideTimer

        interval: 4000
        repeat: false

        onTriggered: {
            const notification = root.currentNotification

            popup.visible = false
            root.currentNotification = null

            if (notification)
                notification.expire()
        }
    }
}
