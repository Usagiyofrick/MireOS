import Quickshell
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: launcher

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: false
    color: "transparent"
    focusable: true

    exclusionMode: ExclusionMode.Ignore

    property int selectedIndex: 0
    property int maxResults: 7

    function scoreApp(app, query) {
        const q = query.toLowerCase().trim()

        if (q.length === 0)
            return 100

        const name = (app.name || "").toLowerCase()
        const generic = (app.genericName || "").toLowerCase()

        if (name === q)
            return 0

        if (name.startsWith(q))
            return 1

        if (name.includes(q))
            return 2

        // Для коротких запросов ищем только по имени.
        if (q.length < 3)
            return 999

        if (generic.startsWith(q))
            return 3

        if (generic.includes(q))
            return 4

        return 999
    }

    ScriptModel {
        id: filteredApps

        values: DesktopEntries.applications.values
            .map(app => ({
                app: app,
                score: launcher.scoreApp(app, search.text)
            }))
            .filter(entry => entry.score < 999)
            .sort((a, b) => {
                if (a.score !== b.score)
                    return a.score - b.score

                return a.app.name.localeCompare(b.app.name)
            })
            .slice(0, launcher.maxResults)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launcher.visible = false
    }

    Rectangle {
        id: launcherBox

        width: 460

        height: 64
            + (
                filteredApps.values.length > 0
                ? filteredApps.values.length * 46 + 8
                : 0
            )

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 52
        }

        radius: 14
        color: "#1d1826"
        border.color: "#9b6cff"
        border.width: 1
        antialiasing: true

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            TextField {
                id: search

                width: parent.width
                height: 48

                placeholderText: "Search applications..."

                color: "#e8e4ee"
                placeholderTextColor: "#8e8798"

                selectionColor: "#9b6cff"
                selectedTextColor: "#15111c"

                leftPadding: 14
                rightPadding: 14

                font.pixelSize: 15

                background: Rectangle {
                    radius: 10
                    color: "#15111c"
                    border.width: 1

                    border.color:
                        search.activeFocus
                        ? "#9b6cff"
                        : "#282033"

                    antialiasing: true
                }

                onTextChanged: {
                    launcher.selectedIndex = 0
                    appList.currentIndex = 0
                }

                Keys.onEscapePressed: {
                    launcher.visible = false
                }

                Keys.onDownPressed: {
                    if (filteredApps.values.length === 0)
                        return

                    launcher.selectedIndex = Math.min(
                        launcher.selectedIndex + 1,
                        filteredApps.values.length - 1
                    )

                    appList.currentIndex = launcher.selectedIndex
                }

                Keys.onUpPressed: {
                    if (filteredApps.values.length === 0)
                        return

                    launcher.selectedIndex = Math.max(
                        launcher.selectedIndex - 1,
                        0
                    )

                    appList.currentIndex = launcher.selectedIndex
                }

                Keys.onReturnPressed: launcher.launchSelected()
                Keys.onEnterPressed: launcher.launchSelected()
            }

            ListView {
                id: appList

                width: parent.width
                height: filteredApps.values.length * 46

                clip: true
                spacing: 4

                model: filteredApps
                currentIndex: launcher.selectedIndex

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: appList.width
                    height: 42
                    radius: 8

                    color:
                        index === launcher.selectedIndex
                        ? "#282033"
                        : "transparent"

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }

                        text: modelData.app.name

                        color:
                            index === launcher.selectedIndex
                            ? "#b794f4"
                            : "#e8e4ee"

                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: {
                            launcher.selectedIndex = index
                            appList.currentIndex = index
                        }

                        onClicked: {
                            modelData.app.execute()
                            launcher.visible = false
                        }
                    }
                }
            }
        }
    }

    function launchSelected() {
        if (filteredApps.values.length === 0)
            return

        filteredApps.values[selectedIndex].app.execute()
        visible = false
    }

    function toggle() {
        visible = !visible

        if (visible) {
            search.text = ""
            selectedIndex = 0
            appList.currentIndex = 0
            search.forceActiveFocus()
        }
    }
}
