// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: wheel
    property bool fifths: false
    signal noteRequested(int midi)
    signal chordRequested(var frets)
    property int selectedNote: 9
    property int chordType: fifths ? 0 : -1
    readonly property var labels: ["C", "C♯ / D♭", "D", "D♯ / E♭", "E", "F", "F♯ / G♭", "G", "G♯ / A♭", "A", "A♯ / B♭", "B"]
    readonly property var solfege: ["Do", "Do♯ / Re♭", "Re", "Re♯ / Mi♭", "Mi", "Fa", "Fa♯ / Sol♭", "Sol", "Sol♯ / La♭", "La", "La♯ / Si♭", "Si"]
    readonly property var selectedChord: chordLibrary.browse(selectedNote, chordType < 0 ? 0 : chordType)[0]
    function noteAt(position) { return (9 + position * (fifths ? 7 : 1)) % 12 }
    function isChordTone(note) {
        return chordType >= 0 && selectedChord.pitchClasses.indexOf(note) >= 0
    }
    spacing: 12
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
                        if (!audioEngine.muted) {
                            if (wheel.fifths) wheel.chordRequested(wheel.selectedChord.frets)
                            else wheel.noteRequested(60 + note)
                        }
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
                    text: wheel.solfege[wheel.selectedNote]
                    font.family: appFontFamily
                    font.pointSize: 16
                    opacity: 0.75
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
