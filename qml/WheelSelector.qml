// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

T.TabBar {
    property bool fifths: false
    id: chordSelector
    objectName: "wheelChordSelector"
    implicitWidth: fifths ? 244 : 366
    implicitHeight: 40
    padding: 4
    spacing: 4
    Accessible.name: "Highlight chord tones"
    contentItem: ListView {
        implicitHeight: 32
        model: chordSelector.contentModel
        currentIndex: chordSelector.currentIndex
        orientation: ListView.Horizontal
        spacing: chordSelector.spacing
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
    }
    background: Rectangle {
        radius: 12
        color: Kirigami.Theme.alternateBackgroundColor
        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.10)
    }
    Repeater {
        model: fifths ? ["Major chord", "Minor chord"]
            : ["Notes only", "Major chord", "Minor chord"]
        T.TabButton {
            id: segment
            required property string modelData
            text: modelData
            implicitHeight: 32
            width: (chordSelector.availableWidth - chordSelector.spacing * (fifths ? 1 : 2)) / (fifths ? 2 : 3)
            height: chordSelector.availableHeight
            topInset: 0
            bottomInset: 0
            hoverEnabled: true
            contentItem: QQC2.Label {
                text: segment.text
                font.family: appFontFamily
                font.pointSize: 10
                font.weight: segment.checked ? Font.Medium : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: Kirigami.Theme.textColor
            }
            background: Rectangle {
                radius: 8
                color: segment.checked ? Qt.alpha("#62c0b1", 0.28)
                    : segment.hovered ? Qt.alpha("#62c0b1", 0.12) : "transparent"
                border.width: segment.visualFocus ? 2 : segment.checked ? 1 : 0
                border.color: segment.visualFocus ? Kirigami.Theme.highlightColor : Qt.alpha("#318b80", 0.45)
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
    }
}
