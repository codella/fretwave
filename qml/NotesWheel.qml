// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: wheel
    property bool fifths: false
    property bool muted: false
    signal muteToggled()
    signal noteRequested(int midi)
    property int selectedNote: 9
    property int chordType: -1
    readonly property var labels: ["C", "C♯ / D♭", "D", "D♯ / E♭", "E", "F", "F♯ / G♭", "G", "G♯ / A♭", "A", "A♯ / B♭", "B"]
    readonly property var selectedChord: chordLibrary.browse(selectedNote, chordType < 0 ? 0 : chordType)[0]
    function noteAt(position) { return (9 + position * (fifths ? 7 : 1)) % 12 }
    function isChordTone(note) {
        return chordType >= 0 && selectedChord.pitchClasses.indexOf(note) >= 0
    }
    spacing: 12
    Item {
        Layout.fillWidth: true
        implicitHeight: 40
        RowLayout {
        anchors.centerIn: parent
        QQC2.Label { text: "Show" }
        QQC2.ComboBox {
            model: ["Notes only", "Major chord", "Minor chord"]
            Accessible.name: "Highlight chord tones"
            onCurrentIndexChanged: wheel.chordType = currentIndex - 1
        }
    }
        QQC2.ToolButton {
            id: muteButton
            objectName: "wheelMuteButton"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
            padding: 10
            hoverEnabled: true
            text: wheel.muted ? "Unmute wheel notes" : "Mute wheel notes"
            Accessible.name: text
            onClicked: wheel.muteToggled()
            contentItem: Canvas {
                property bool muted: wheel.muted
                property color ink: wheel.muted ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
                onMutedChanged: requestPaint()
                onInkChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d"); c.reset()
                    c.scale(width / 24, height / 24)
                    c.fillStyle = ink; c.strokeStyle = ink
                    c.lineWidth = 1.7; c.lineCap = "round"; c.lineJoin = "round"
                    c.beginPath(); c.moveTo(3, 9); c.lineTo(7, 9)
                    c.lineTo(12, 5); c.lineTo(12, 19); c.lineTo(7, 15)
                    c.lineTo(3, 15); c.closePath(); c.fill()
                    if (muted) {
                        c.beginPath(); c.moveTo(16, 9); c.lineTo(22, 15)
                        c.moveTo(22, 9); c.lineTo(16, 15); c.stroke()
                    } else {
                        for (let r of [5, 9]) {
                            c.beginPath(); c.arc(12, 12, r, -0.75, 0.75); c.stroke()
                        }
                    }
                }
            }
            background: Rectangle {
                radius: 10
                color: Qt.alpha(Kirigami.Theme.highlightColor,
                    muteButton.down ? 0.22 : muteButton.hovered ? 0.16 : 0.04)
                border.width: muteButton.visualFocus ? 2 : 1
                border.color: muteButton.visualFocus ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.10)
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            QQC2.ToolTip {
                text: muteButton.text
                visible: muteButton.hovered
                delay: 400
                x: muteButton.width - implicitWidth
                y: muteButton.height + 8
                horizontalPadding: 14
                verticalPadding: 8
                contentItem: QQC2.Label {
                    text: muteButton.text
                    font.family: appFontFamily
                    font.pointSize: 10
                    color: "#f7f8fa"
                }
                background: Rectangle {
                    radius: height / 2
                    color: "#272b33"
                    border.color: "#454b57"
                }
            }
        }
    }
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 400
        Item {
            id: face
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height, 530)
            height: width
            readonly property real radius: width / 2 - 48
            Rectangle {
                anchors.centerIn: parent
                width: face.radius * 2
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Kirigami.Theme.disabledTextColor
                opacity: 0.35
            }
            Repeater {
                model: 12
                QQC2.Button {
                    required property int index
                    readonly property int note: wheel.noteAt(index)
                    readonly property real angle: index * Math.PI / 6 - Math.PI / 2
                    width: 84
                    height: 48
                    x: face.width / 2 + face.radius * Math.cos(angle) - width / 2
                    y: face.height / 2 + face.radius * Math.sin(angle) - height / 2
                    text: wheel.labels[note]
                    highlighted: note === wheel.selectedNote || wheel.isChordTone(note)
                    font.family: displayFontFamily
                    font.pointSize: 12
                    font.bold: note === wheel.selectedNote
                    Accessible.name: text + (note === wheel.selectedNote ? ", selected root" : "")
                    onClicked: {
                        wheel.selectedNote = note
                        if (!wheel.muted) wheel.noteRequested(60 + note)
                    }
                    background: Rectangle {
                        radius: 24
                        color: parent.highlighted ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                        border.color: parent.activeFocus || parent.hovered ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                        border.width: parent.activeFocus || parent.note === wheel.selectedNote ? 3 : 1
                    }
                }
            }
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                Kirigami.Heading {
                    Layout.alignment: Qt.AlignHCenter
                    text: wheel.chordType < 0 ? wheel.labels[wheel.selectedNote] : wheel.selectedChord.name
                    font.family: displayFontFamily
                    font.pointSize: 36
                    font.weight: Font.Medium
                }
                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: wheel.chordType < 0 ? "" : wheel.selectedChord.notes
                    font.pointSize: 13
                }
                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: wheel.fifths ? "Clockwise: perfect fifths" : "Clockwise: semitones"
                    opacity: 0.65
                }
            }
        }
    }
}
