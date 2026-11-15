// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
QQC2.Button {
    id: control
    implicitHeight: 38
    horizontalPadding: 16
    hoverEnabled: true
    opacity: enabled ? 1 : 0.4
    background: Rectangle {
        radius: 9
        color: control.highlighted ? Qt.alpha("#62c0b1", control.hovered ? 0.3 : 0.2)
            : control.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.08) : "transparent"
        border.width: control.visualFocus ? 2 : 1
        border.color: control.highlighted ? "#318b80" : Qt.alpha(Kirigami.Theme.textColor, 0.18)
    }
}
