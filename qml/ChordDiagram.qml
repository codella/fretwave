// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: diagram
    objectName: "chordDiagram"
    property real zoom: 1
    readonly property real stringSpacing: Math.min((width / zoom - 90) / 5, 48)
    readonly property real neckHeight: Math.min(height / zoom - 90, 280)
    readonly property real neckLeft: (width / zoom - stringSpacing * 5) / 2
    readonly property real neckTop: 44
    function fretY(boundary) {
        return neckTop + neckHeight * (1 - Math.pow(2, -boundary / 12))
            / (1 - Math.pow(2, -5 / 12))
    }
    function fretCenter(offset) {
        return (fretY(offset) + fretY(offset + 1)) / 2
    }
    function noteAt(stringIndex, fret) {
        if (stringIndex < 0 || stringIndex > 5 || fret < 0) return ""
        const midi = [40, 45, 50, 55, 59, 64][stringIndex] + fret
        const octave = Math.floor(midi / 12) - 1
        const names = ["C", "C♯ / D♭", "D", "D♯ / E♭", "E", "F", "F♯ / G♭", "G", "G♯ / A♭", "A", "A♯ / B♭", "B"]
        return names[midi % 12].split(" / ").map(name => name + octave).join(" / ")
    }
    function positionAt(px, py) {
        px /= zoom
        py /= zoom
        if (!chord || stringSpacing <= 0) return null
        const stringIndex = Math.round((px - neckLeft) / stringSpacing)
        if (stringIndex < 0 || stringIndex > 5
            || Math.abs(px - neckLeft - stringIndex * stringSpacing) > 15) return null
        if (py >= neckTop - 35 && py <= neckTop - 10 && chord.frets[stringIndex] <= 0)
            return { stringIndex: stringIndex, fret: chord.frets[stringIndex] }
        for (let offset = 0; offset < 5; ++offset) {
            if (py >= fretY(offset) && py <= fretY(offset + 1))
                return { stringIndex: stringIndex, fret: chord.firstFret + offset }
        }
        return null
    }
    function midiAt(px, py) {
        const position = positionAt(px, py)
        return !position || position.fret < 0 ? -1
            : [40, 45, 50, 55, 59, 64][position.stringIndex] + position.fret
    }
    function tooltipAt(px, py) {
        const position = positionAt(px, py)
        if (!position) return ""
        return position.fret < 0 ? "Muted in this chord\nOpen: " + noteAt(position.stringIndex, 0)
            : noteAt(position.stringIndex, position.fret)
    }
    property var chord: null
    property color ink: Kirigami.Theme.textColor
    property color accent: "#62c0b1"
    implicitWidth: 340
    implicitHeight: 390
    Accessible.role: Accessible.Graphic
    Accessible.name: chord ? chord.name + ", frets from low E to high E: " + chord.frets.map(f => f < 0 ? "muted" : f === 0 ? "open" : f).join(", ") : "Chord diagram"
    onChordChanged: canvas.requestPaint()
    onInkChanged: canvas.requestPaint()
    onAccentChanged: canvas.requestPaint()
    onZoomChanged: canvas.requestPaint()
    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"); c.reset()
            // Draw directly into a canvas at its final size, never stretch its texture.
            c.scale(diagram.zoom, diagram.zoom)
            if (!diagram.chord) return
            const ch = diagram.chord
            const dx = diagram.stringSpacing
            const neckHeight = diagram.neckHeight
            const left = diagram.neckLeft, top = diagram.neckTop
            const start = ch.firstFret
            const right = left + dx * 5, bottom = top + neckHeight
            c.textAlign = "center"; c.textBaseline = "middle"; c.font = '14px "' + appFontFamily + '"'

            // Roman numerals identify the actual fret, including upper octaves.
            function roman(number) {
                const values = [10, 9, 5, 4, 1]
                const symbols = ["X", "IX", "V", "IV", "I"]
                let result = ""
                for (let i = 0; i < values.length; ++i) {
                    while (number >= values[i]) {
                        result += symbols[i]
                        number -= values[i]
                    }
                }
                return result
            }
            c.save()
            c.fillStyle = diagram.ink
            c.globalAlpha = 0.55
            c.font = '500 15px "' + appFontFamily + '"'
            for (let f = 0; f < 5; ++f) {
                const fret = start + f
                if (f === 0) continue // The first row is already identified by the fret reference.
                if ([0, 3, 5, 7, 9].indexOf(fret % 12) < 0) continue
                c.fillText(roman(fret), left - 28, diagram.fretCenter(f), 42)
            }
            c.restore()

            // Rounded metal fret crowns with a bright centre and shaded lower edge.
            for (let f = 0; f <= 5; ++f) {
                if (f === 0 && start === 1) continue
                const y = diagram.fretY(f)
                const metal = c.createLinearGradient(0, y - 2, 0, y + 3)
                metal.addColorStop(0, "#76818a"); metal.addColorStop(0.35, "#f4f6f7")
                metal.addColorStop(0.6, "#bdc5ca"); metal.addColorStop(1, "#68747d")
                c.strokeStyle = metal; c.lineWidth = 5; c.lineCap = "round"
                c.beginPath(); c.moveTo(left - 6, y); c.lineTo(right + 6, y); c.stroke()
            }
            const gauges = [3.8, 3.1, 2.5, 1.8, 1.3, 0.9]
            if (start === 1) {
                const ivory = c.createLinearGradient(0, top - 5, 0, top + 5)
                ivory.addColorStop(0, "#fffdf1"); ivory.addColorStop(0.5, "#eee5ca"); ivory.addColorStop(1, "#c4b797")
                c.fillStyle = ivory; c.strokeStyle = "#a99c7f"; c.lineWidth = 1
                c.fillRect(left - 8, top - 5, right - left + 16, 10)
                c.strokeRect(left - 8, top - 5, right - left + 16, 10)
                // Narrow slots seat each string in the nut, with a softly shaded edge.
                for (let s = 0; s < 6; ++s) {
                    const x = left + s * dx
                    c.strokeStyle = "#9c9077"; c.lineWidth = gauges[s] + 1.2
                    c.lineCap = "butt"
                    c.beginPath(); c.moveTo(x, top - 5); c.lineTo(x, top + 5); c.stroke()
                }
            }

            // Continue past the nut toward the headstock instead of ending inside it.
            const stringTop = start === 1 ? top - 11 : top - 4
            for (let s = 0; s < 6; ++s) {
                const x = left + s * dx, gauge = gauges[s]
                const steel = c.createLinearGradient(x - gauge / 2, 0, x + gauge / 2, 0)
                steel.addColorStop(0, "#626d76"); steel.addColorStop(0.45, "#edf1f3"); steel.addColorStop(1, "#77838d")
                c.strokeStyle = steel; c.lineWidth = gauge; c.lineCap = "butt"
                c.beginPath(); c.moveTo(x, stringTop); c.lineTo(x, bottom + 3); c.stroke()
                // Fine winding on the three bass strings.
                if (s < 3) {
                    c.strokeStyle = "#808b94"; c.lineWidth = 0.5
                    for (let y = stringTop + 3; y < bottom; y += 4) {
                        c.beginPath(); c.moveTo(x - gauge / 2, y + 1); c.lineTo(x + gauge / 2, y); c.stroke()
                    }
                }
                if (start === 1) {
                    // The recessed part catches less light than the free string.
                    c.strokeStyle = "rgba(104, 91, 68, 0.28)"
                    c.lineWidth = gauge
                    c.beginPath(); c.moveTo(x, top - 5); c.lineTo(x, top + 4); c.stroke()
                }
                c.fillStyle = diagram.ink
                c.save()
                c.globalAlpha = 0.5
                c.fillText(["E", "A", "D", "G", "B", "e"][s], x, bottom + 24)
                c.restore()
                if (ch.frets[s] <= 0) {
                    const markerY = top - 23
                    c.save()
                    c.lineWidth = 1.8
                    c.lineCap = "round"
                    if (ch.frets[s] === 0) {
                        c.strokeStyle = "#318b80"
                        c.fillStyle = "rgba(98, 192, 177, 0.14)"
                        c.beginPath(); c.arc(x, markerY, 6, 0, Math.PI * 2)
                        c.fill(); c.stroke()
                    } else {
                        c.globalAlpha = 0.55
                        c.strokeStyle = diagram.ink
                        c.beginPath(); c.moveTo(x - 4.5, markerY - 4.5)
                        c.lineTo(x + 4.5, markerY + 4.5)
                        c.moveTo(x - 4.5, markerY + 4.5)
                        c.lineTo(x + 4.5, markerY - 4.5); c.stroke()
                    }
                    c.restore()
                }
            }
            c.save()
            c.fillStyle = "#318b80"
            c.font = '500 14px "' + displayFontFamily + '"'
            c.fillText(start + " fr", left - 28, diagram.fretCenter(0))
            c.restore()
            if (ch.barre > 0) {
                c.strokeStyle = diagram.accent; c.lineWidth = 22; c.lineCap = "round"
                const y = diagram.fretCenter(ch.barre - start)
                c.beginPath(); c.moveTo(left + ch.barreStart * dx, y); c.lineTo(left + 5 * dx, y); c.stroke()
            }
            for (let s = 0; s < 6; ++s) {
                if (ch.frets[s] <= 0) continue
                const x = left + s * dx, y = diagram.fretCenter(ch.frets[s] - start)
                c.fillStyle = "#00000022"; c.beginPath(); c.arc(x, y + 2, 15, 0, Math.PI * 2); c.fill()
                c.fillStyle = diagram.accent; c.strokeStyle = "#2e7e73"; c.lineWidth = 1
                c.beginPath(); c.arc(x, y, 14, 0, Math.PI * 2); c.fill(); c.stroke()
                c.font = 'bold 15px "' + appFontFamily + '"'; c.fillStyle = "#102e2a"; c.fillText(ch.fingers[s], x, y)
            }
        }
    }
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: diagram.midiAt(mouseX, mouseY) >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            const midi = diagram.midiAt(mouse.x, mouse.y)
            if (midi >= 0) audioEngine.playNote(midi)
        }
        QQC2.ToolTip {
            id: noteTip
            objectName: "noteTooltip"
            text: diagram.tooltipAt(hoverArea.mouseX, hoverArea.mouseY)
            visible: hoverArea.containsMouse && text.length > 0
            delay: 300
            timeout: -1
            x: Math.max(0, Math.min(hoverArea.mouseX + 16, diagram.width - implicitWidth))
            y: hoverArea.mouseY + 20
            font.family: appFontFamily
            font.pointSize: 10
            horizontalPadding: 14
            verticalPadding: 7
            topInset: 0
            bottomInset: 0
            leftInset: 0
            rightInset: 0
            contentItem: QQC2.Label {
                textFormat: Text.RichText
                text: noteTip.text.replace(/([A-G][♯♭]?)([0-9]+)/g,
                    '$1<span style="font-size: 8pt;">$2</span>').replace(/\n/g, "<br>")
                font.family: appFontFamily
                font.pointSize: 10
                font.weight: Font.Medium
                color: "#f7f8fa"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
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

}
