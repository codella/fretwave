// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.Dialog {
    id: picker
    objectName: "addChordDialog"
    title: "Add chord"
    modal: true
    focus: true
    width: Math.min(620, parent.width - 48)
    height: Math.min(620, parent.height - 48)
    padding: 24
    header: Item {}
    footer: Item {}
    property var results: chordLibrary.browse(rootFilter.currentIndex - 1, typeFilter.currentIndex - 1)
    property var selected: matches.currentIndex >= 0 && matches.currentIndex < results.length ? results[matches.currentIndex] : null
    signal chordAdded(var chord)
    onResultsChanged: matches.currentIndex = results.length ? 0 : -1
    background: Rectangle { radius: 18; color: Kirigami.Theme.backgroundColor; border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15) }
    QQC2.Overlay.modal: Rectangle { color: "#66000000" }
    contentItem: ColumnLayout {
        spacing: 16
        QQC2.Label { text: "Add chord"; font.family: displayFontFamily; font.pointSize: 25 }
        QQC2.Label { text: "Choose a chord and the voicing you want to keep."; opacity: 0.65 }
        RowLayout {
            spacing: 12
            QQC2.Label { text: "Root" }
            FilterComboBox { id: rootFilter; objectName: "rootFilter"; model: ["All roots"].concat(chordLibrary.roots); Accessible.name: "Root note" }
            QQC2.Label { text: "Type" }
            FilterComboBox { id: typeFilter; objectName: "typeFilter"; Layout.fillWidth: true; model: ["All types"].concat(chordLibrary.qualities); Accessible.name: "Chord type" }
        }
        QQC2.Label { text: picker.results.length + " voicings"; opacity: 0.6; font.pointSize: 10 }
        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ListView {
                id: matches
                objectName: "availableChords"
                model: picker.results
                spacing: 4
                currentIndex: 0
                delegate: QQC2.ItemDelegate {
                    id: row
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 68
                    highlighted: matches.currentIndex === index
                    onClicked: matches.currentIndex = index
                    contentItem: Column {
                        spacing: 4
                        QQC2.Label { text: row.modelData.name + "  ·  " + row.modelData.shape; font.weight: Font.Medium }
                        QQC2.Label {
                            text: row.modelData.frets.map(f => f < 0 ? "×" : f).join("  ")
                                + (appSettings.favoriteKeys.indexOf(row.modelData.key) >= 0 ? "     Already added" : "")
                            opacity: 0.65
                            font.pointSize: 10
                        }
                    }
                    background: Rectangle {
                        radius: 10
                        color: row.highlighted ? Qt.alpha("#62c0b1", 0.2) : row.hovered ? Qt.alpha("#62c0b1", 0.08) : "transparent"
                        border.width: row.visualFocus ? 2 : 0
                        border.color: Kirigami.Theme.highlightColor
                    }
                }
            }
        }
        RowLayout {
            Item { Layout.fillWidth: true }
            ActionButton { text: "Cancel"; onClicked: picker.close() }
            ActionButton {
                text: picker.selected && appSettings.favoriteKeys.indexOf(picker.selected.key) >= 0 ? "Already added" : "Add chord"
                highlighted: true
                enabled: picker.selected !== null && appSettings.favoriteKeys.indexOf(picker.selected.key) < 0
                onClicked: { picker.chordAdded(picker.selected); picker.close() }
            }
        }
    }
}
