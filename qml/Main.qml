// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root
    width: 900
    height: 840
    minimumWidth: 720
    minimumHeight: 780
    font.family: appFontFamily
    font.pointSize: 11
    title: "Fretwave"
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.None
    property bool focusMode: false
    Shortcut { sequence: "Escape"; enabled: root.focusMode; onActivated: root.focusMode = false }
    property var results: []
    property var selected: null
    function refresh() {
        results = chordLibrary.browse(rootFilter.currentIndex - 1, typeFilter.currentIndex - 1)
        chordList.currentIndex = 0
        selected = results.length ? results[0] : null
    }
    Component.onCompleted: refresh()
    pageStack.initialPage: Kirigami.Page {
        ColumnLayout {
            anchors.fill: parent
            spacing: 16
            QQC2.TabBar {
                id: tabs
                objectName: "mainTabs"
                Layout.fillWidth: true
                implicitHeight: 56
                padding: 5
                spacing: 12
                contentItem: ListView {
                    implicitHeight: 46
                    model: tabs.contentModel
                    currentIndex: tabs.currentIndex
                    orientation: ListView.Horizontal
                    spacing: tabs.spacing
                    interactive: false
                    boundsBehavior: Flickable.StopAtBounds
                }
                background: Rectangle {
                    radius: 14
                    color: Kirigami.Theme.alternateBackgroundColor
                    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.10)
                }
                component NavigationTab: T.TabButton {
                    id: tab
                    implicitHeight: 46
                    height: 46
                    topInset: 0
                    bottomInset: 0
                    leftInset: 0
                    rightInset: 0
                    width: (tabs.availableWidth - tabs.spacing * 2) / 3
                    hoverEnabled: true
                    contentItem: QQC2.Label {
                        text: tab.text.toUpperCase()
                        font.family: displayFontFamily
                        font.pointSize: 12
                        font.letterSpacing: 1.1
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: tab.checked ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    }
                    background: Rectangle {
                        radius: 10
                        color: tab.checked ? Kirigami.Theme.highlightColor
                            : tab.hovered ? Qt.alpha(Kirigami.Theme.highlightColor, 0.12) : "transparent"
                        border.width: tab.visualFocus ? 2 : 0
                        border.color: Kirigami.Theme.textColor
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
                NavigationTab { text: "Chords" }
                NavigationTab { text: "Notes wheel" }
                NavigationTab { text: "Circle of fifths" }
            }
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabs.currentIndex
                ColumnLayout {
                    spacing: 16
            RowLayout {
                Layout.fillWidth: true
                visible: !root.focusMode
                spacing: 12
                QQC2.Label { text: "Root"; font.weight: Font.Medium; opacity: 0.7 }
                QQC2.ComboBox { id: rootFilter; implicitHeight: 36; objectName: "rootFilter"; model: ["All roots"].concat(chordLibrary.roots); Accessible.name: "Root note"; onActivated: root.refresh() }
                QQC2.Label { text: "Type"; font.weight: Font.Medium; opacity: 0.7 }
                QQC2.ComboBox { id: typeFilter; implicitHeight: 36; objectName: "typeFilter"; model: ["All types"].concat(chordLibrary.qualities); Accessible.name: "Chord type"; onActivated: root.refresh() }
                Item { Layout.fillWidth: true }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 24
                QQC2.ScrollView {
                    visible: !root.focusMode
                    Layout.preferredWidth: 240
                    Layout.fillHeight: true
                    clip: true
                    ListView {
                        id: chordList
                        objectName: "chordList"
                        model: root.results
                        spacing: 4
                        currentIndex: 0
                        delegate: QQC2.ItemDelegate {
                            id: chordRow
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 62
                            padding: 12
                            text: modelData.name + "  ·  " + modelData.shape
                            contentItem: Column {
                                spacing: 3
                                QQC2.Label {
                                    text: chordRow.modelData.name
                                    font.family: displayFontFamily
                                    font.pointSize: 16
                                    font.weight: Font.Medium
                                    color: chordRow.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                }
                                QQC2.Label {
                                    text: chordRow.modelData.shape
                                    font.family: appFontFamily
                                    font.pointSize: 9
                                    color: chordRow.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                    opacity: 0.75
                                }
                            }
                            background: Rectangle {
                                radius: 8
                                color: chordRow.highlighted ? Kirigami.Theme.highlightColor
                                    : chordRow.hovered ? Qt.alpha(Kirigami.Theme.highlightColor, 0.08) : "transparent"
                                border.width: chordRow.visualFocus ? 2 : 0
                                border.color: Kirigami.Theme.textColor
                            }
                            highlighted: chordList.currentIndex === index
                            onClicked: { chordList.currentIndex = index; root.selected = modelData }
                        }
                        onCurrentIndexChanged: { if (currentIndex >= 0 && currentIndex < root.results.length) root.selected = root.results[currentIndex] }
                        Keys.onUpPressed: decrementCurrentIndex()
                        Keys.onDownPressed: incrementCurrentIndex()
                    }
                }
                QQC2.Frame {
                    padding: 20
                    background: Rectangle {
                        radius: 12
                        color: Kirigami.Theme.backgroundColor
                        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.10)
                    }
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8
                        Kirigami.Heading { Layout.alignment: Qt.AlignHCenter; text: root.selected ? root.selected.name : "No chords"; font.family: displayFontFamily; font.pointSize: 40; font.weight: Font.Medium }
                        QQC2.Label { Layout.alignment: Qt.AlignHCenter; text: root.selected ? root.selected.shape : ""; opacity: 0.65 }
                        QQC2.Label {
                            visible: audioEngine.error.length > 0
                            text: audioEngine.error
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            color: Kirigami.Theme.negativeTextColor
                            font.pointSize: 10
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 370
                            ChordDiagram {
                                anchors.centerIn: parent
                                zoom: root.focusMode ? Math.min(parent.width / 360, parent.height / 390, 1.5) : 1
                                width: Math.min(parent.width, 360 * zoom)
                                height: Math.min(parent.height, 390 * zoom)
                                chord: root.selected
                            }
                        }
                        QQC2.Label { Layout.alignment: Qt.AlignHCenter; text: root.selected ? "Notes   " + root.selected.notes : ""; font.pointSize: 13; font.weight: Font.Medium }
                        QQC2.Label {
                            id: intervalLabel
                            Layout.bottomMargin: 14
                            objectName: "intervalLabel"
                            Layout.alignment: Qt.AlignHCenter
                            text: root.selected ? "Intervals   " + root.selected.formula : ""
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.7)
                            MouseArea {
                                id: intervalHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                                cursorShape: Qt.WhatsThisCursor
                            }
                            QQC2.ToolTip {
                                id: intervalTip
                                objectName: "intervalTooltip"
                                visible: intervalHover.containsMouse && root.selected !== null
                                delay: 300
                                timeout: -1
                                padding: 16
                                topInset: 0
                                bottomInset: 0
                                leftInset: 0
                                rightInset: 0
                                x: (intervalLabel.width - implicitWidth) / 2
                                y: -implicitHeight - 12
                                text: {
                                    if (!root.selected) return ""
                                    const rows = root.selected.intervalDetails.map(item =>
                                        item.symbol + " → " + item.note + ": " + item.name + " · " + item.semitones + " semitones")
                                    return "<b>" + root.selected.title + "</b><br>" + rows.join("<br>")
                                }
                                contentItem: QQC2.Label {
                                    text: intervalTip.text
                                    textFormat: Text.RichText
                                    font.family: appFontFamily
                                    font.pointSize: 10
                                    lineHeight: 1.5
                                    color: "#f7f8fa"
                                }
                                background: Item {
                                    Repeater {
                                        model: 5
                                        Rectangle {
                                            required property int index
                                            x: -(index + 1)
                                            y: 3 - (index + 1)
                                            width: parent.width + (index + 1) * 2
                                            height: parent.height + (index + 1) * 2
                                            radius: 12 + index
                                            color: "#09000000"
                                        }
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: "#272b33"
                                        border.width: 1
                                        border.color: "#454b57"
                                    }
                                }
                            }
                        }
                    }
                    QQC2.ToolButton {
                        id: playButton
                        objectName: "playChordButton"
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: 40
                        height: 40
                        padding: 11
                        hoverEnabled: true
                        text: audioEngine.playing ? "Stop sound" : "Play chord"
                        enabled: root.selected !== null
                        Accessible.name: text
                        onClicked: audioEngine.playing ? audioEngine.stop() : audioEngine.playChord(root.selected.frets)
                        contentItem: Canvas {
                            property bool playing: audioEngine.playing
                            property color ink: playing ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            onPlayingChanged: requestPaint()
                            onInkChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            onPaint: {
                                const c = getContext("2d"); c.reset()
                                c.scale(width / 20, height / 20)
                                c.fillStyle = ink
                                if (playing) c.fillRect(4, 4, 12, 12)
                                else {
                                    c.beginPath(); c.moveTo(5, 3); c.lineTo(17, 10)
                                    c.lineTo(5, 17); c.closePath(); c.fill()
                                }
                            }
                        }
                        background: Rectangle {
                            radius: 10
                            color: Qt.alpha(Kirigami.Theme.highlightColor,
                                playButton.down ? 0.22 : playButton.hovered ? 0.16 : audioEngine.playing ? 0.10 : 0.04)
                            border.width: playButton.visualFocus ? 2 : 1
                            border.color: playButton.visualFocus ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.10)
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        QQC2.ToolTip {
                            id: playbackTip
                            text: playButton.text
                            visible: playButton.hovered
                            delay: 400
                            timeout: -1
                            x: 0
                            y: playButton.height + 8
                            horizontalPadding: 14
                            verticalPadding: 8
                            topInset: 0
                            bottomInset: 0
                            leftInset: 0
                            rightInset: 0
                            contentItem: QQC2.Label {
                                text: playbackTip.text
                                font.family: appFontFamily
                                font.pointSize: 10
                                font.weight: Font.Medium
                                color: "#f7f8fa"
                            }
                            background: Item {
                                Repeater {
                                    model: 5
                                    Rectangle {
                                        required property int index
                                        x: -(index + 1)
                                        y: 3 - (index + 1)
                                        width: parent.width + (index + 1) * 2
                                        height: parent.height + (index + 1) * 2
                                        radius: height / 2
                                        color: "#09000000"
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: "#272b33"
                                    border.width: 1
                                    border.color: "#454b57"
                                }
                            }
                        }
                    }
                    QQC2.ToolButton {
                        id: focusToggle
                        objectName: "focusToggle"
                        anchors.top: parent.top
                        anchors.right: parent.right
                        width: 40
                        height: 40
                        padding: 10
                        hoverEnabled: true
                        text: root.focusMode ? "Show browser" : "Focus chord"
                        Accessible.name: text
                        onClicked: root.focusMode = !root.focusMode
                        contentItem: Canvas {
                            property bool focused: root.focusMode
                            property color ink: root.focusMode ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            onFocusedChanged: requestPaint()
                            onInkChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            onPaint: {
                                const c = getContext("2d")
                                c.reset()
                                c.scale(width / 20, height / 20)
                                c.translate(10, 10)
                                c.strokeStyle = ink
                                c.lineWidth = 1.7
                                c.lineCap = "round"
                                c.lineJoin = "round"
                                for (let i = 0; i < 4; ++i) {
                                    c.beginPath()
                                    c.moveTo(-7, -7); c.lineTo(-3, -3)
                                    if (focused) {
                                        c.moveTo(-7, -3); c.lineTo(-3, -3); c.lineTo(-3, -7)
                                    } else {
                                        c.moveTo(-7, -3); c.lineTo(-7, -7); c.lineTo(-3, -7)
                                    }
                                    c.stroke()
                                    c.rotate(Math.PI / 2)
                                }
                            }
                        }
                        background: Rectangle {
                            radius: 10
                            color: Qt.alpha(Kirigami.Theme.highlightColor,
                                focusToggle.down ? 0.22 : focusToggle.hovered ? 0.16 : root.focusMode ? 0.10 : 0.04)
                            border.width: focusToggle.visualFocus ? 2 : 1
                            border.color: focusToggle.visualFocus ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.10)
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: root.focusMode ? "Show browser (Esc)" : "Focus chord"
                        QQC2.ToolTip.delay: 500
                    }
                }
            }
                }
                NotesWheel { objectName: "chromaticWheel" }
                NotesWheel { objectName: "fifthsWheel"; fifths: true }
            }
        }
    }
}
