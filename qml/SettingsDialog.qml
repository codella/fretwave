// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

QQC2.Dialog {
    id: dialog
    objectName: "settingsDialog"
    title: "Settings"
    modal: true
    focus: true
    width: Math.min(520, parent.width - 48)
    padding: 28
    closePolicy: QQC2.Popup.CloseOnEscape
    header: Item {}
    footer: Item {}
    background: Rectangle {
        radius: 18
        color: Kirigami.Theme.backgroundColor
        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.14)
    }
    QQC2.Overlay.modal: Rectangle { color: "#66000000" }
    contentItem: ColumnLayout {
        spacing: 22
        ColumnLayout {
            spacing: 6
            QQC2.Label {
                text: "Settings"
                font.family: displayFontFamily
                font.pointSize: 25
                color: Kirigami.Theme.textColor
            }
            QQC2.Label {
                text: "Make Fretwave feel at home."
                color: Kirigami.Theme.textColor
                opacity: 0.65
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Qt.alpha(Kirigami.Theme.textColor, 0.10)
        }
        ColumnLayout {
            spacing: 12
            QQC2.Label { text: "Appearance"; font.weight: Font.Medium; color: Kirigami.Theme.textColor }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: [
                        { key: "system", title: "System", dark: false },
                        { key: "light", title: "Light", dark: false },
                        { key: "dark", title: "Dark", dark: true }
                    ]
                    T.Button {
                        id: choice
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 116
                        padding: 12
                        checkable: true
                        checked: appSettings.theme === modelData.key
                        hoverEnabled: true
                        Accessible.name: modelData.title + " theme"
                        onClicked: appSettings.theme = modelData.key
                        background: Rectangle {
                            radius: 12
                            color: choice.checked ? Qt.alpha("#62c0b1", 0.13)
                                : choice.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.05) : "transparent"
                            border.width: choice.checked || choice.visualFocus ? 2 : 1
                            border.color: choice.checked ? "#318b80" : choice.visualFocus
                                ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.18)
                        }
                        contentItem: ColumnLayout {
                            spacing: 10
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                radius: 6
                                color: choice.modelData.dark ? "#292d30" : "#eff0f1"
                                border.color: "#80969a9d"
                                clip: true
                                Rectangle {
                                    visible: choice.modelData.key === "system"
                                    anchors.right: parent.right
                                    width: parent.width / 2
                                    height: parent.height
                                    color: "#292d30"
                                }
                                Rectangle { x: 8; y: 8; width: parent.width - 16; height: 6; radius: 3; color: "#62c0b1" }
                                Rectangle { x: 8; y: 23; width: parent.width * 0.5; height: 3; radius: 1.5; color: "#879397" }
                                Rectangle { x: 8; y: 32; width: parent.width * 0.65; height: 3; radius: 1.5; color: "#879397" }
                            }
                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: choice.modelData.title
                                font.weight: choice.checked ? Font.DemiBold : Font.Normal
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                text: appSettings.theme === "system" ? "Follows your desktop’s color scheme."
                    : appSettings.theme === "light" ? "A light appearance, whatever your desktop theme."
                    : "A dark appearance, whatever your desktop theme."
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.textColor
                opacity: 0.65
                font.pointSize: 10
            }
        }
        RowLayout {
            Layout.fillWidth: true
            QQC2.Label {
                Layout.fillWidth: true
                text: "Changes are saved automatically."
                font.pointSize: 9
                color: Kirigami.Theme.textColor
                opacity: 0.6
            }
            T.Button {
                id: done
                text: "Done"
                implicitWidth: 86
                implicitHeight: 36
                hoverEnabled: true
                onClicked: dialog.close()
                contentItem: QQC2.Label {
                    text: done.text
                    color: Kirigami.Theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 9
                    color: Qt.alpha("#62c0b1", done.hovered ? 0.3 : 0.2)
                    border.width: done.visualFocus ? 2 : 1
                    border.color: "#318b80"
                }
            }
        }
    }
}
