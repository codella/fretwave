// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.ComboBox {
    id: control
    implicitWidth: Math.max(160, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: 36
    leftPadding: 14
    rightPadding: 32
    hoverEnabled: true
    background: Rectangle {
        radius: 10
        color: control.down ? Qt.alpha(Kirigami.Theme.highlightColor, 0.16)
            : control.hovered ? Qt.alpha(Kirigami.Theme.highlightColor, 0.08)
            : Kirigami.Theme.alternateBackgroundColor
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? Kirigami.Theme.highlightColor
            : Qt.alpha(Kirigami.Theme.textColor, control.hovered ? 0.24 : 0.14)
        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
