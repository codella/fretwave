// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

#include "chords.h"
#include <QCoreApplication>
#include <QSet>
#include <QDebug>
#include <cstdio>

int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    Chords library;
    auto fail = [](const QString &message) { fprintf(stderr, "%s\n", qPrintable(message)); return 1; };
    const auto all = library.browse(-1,-1);
    if (all.size() != 166) return fail("Expected 166 fingerings");
    const QList<int> tuning {4,9,2,7,11,4};
    QSet<QString> ids;
    for (const auto &entry : all) {
        const auto chord = entry.toMap();
        const auto frets = chord["frets"].toList(), fingers = chord["fingers"].toList();
        const auto details = chord["intervalDetails"].toList();
        const QList<QList<int>> expectedIntervals {{0,4,7}, {0,3,7}, {0,4,7,10}, {0,3,7,10}, {0,2,7}, {0,5,7}};
        const auto expectedDistances = expectedIntervals[chord["quality"].toInt()];
        if (details.size() != expectedDistances.size()) return fail("Missing interval explanation");
        const auto spelledNotes = chord["notes"].toString().split(" · ");
        for (int i = 0; i < details.size(); ++i) {
            const auto detail = details[i].toMap();
            if (detail["semitones"].toInt() != expectedDistances[i] || detail["note"].toString() != spelledNotes[i]
                || detail["name"].toString().isEmpty()) return fail("Incorrect interval explanation");
        }
        if (frets.size() != 6 || fingers.size() != 6) return fail("Expected six strings");
        QSet<int> actual, expected;
        for (const auto &pitch : chord["pitchClasses"].toList()) expected.insert(pitch.toInt());
        for (int s = 0; s < 6; ++s) {
            int fret = frets[s].toInt(), finger = fingers[s].toInt();
            if (fret >= 0) actual.insert((tuning[s] + fret) % 12);
            if ((fret > 0 && (finger < 1 || finger > 4)) || (fret <= 0 && finger != 0)) return fail("Invalid finger");
            int start = chord["firstFret"].toInt();
            if (fret > 0 && (fret < start || fret > start + 4)) return fail("Fret outside diagram");
        }
        // Seventh voicings may omit the perfect fifth, but no other chord tone.
        auto essential = expected;
        if ((chord["quality"].toInt() == 2 || chord["quality"].toInt() == 3)) essential.remove((chord["root"].toInt() + 7) % 12);
        if (!(actual - expected).isEmpty() || !(essential - actual).isEmpty()) return fail("Wrong notes in " + chord["name"].toString() + " " + chord["shape"].toString());
        ids.insert(chord["id"].toString());
    }
    for (int quality : {4,5}) {
        for (const auto &entry : library.browse(0,quality)) {
            auto chord = entry.toMap();
            if (chord["notes"].toString() != (quality == 4 ? "C · D · G" : "C · F · G")) return fail("Incorrect suspended note spelling");
            if (chord["formula"].toString() != (quality == 4 ? "1 · 2 · 5" : "1 · 4 · 5")) return fail("Incorrect suspended formula");
        }
    }
    if (ids.size() != all.size()) return fail("Duplicate ids");
    for (int r=0; r<12; ++r) for (int q=0; q<library.qualities().size(); ++q) {
        auto pool = library.browse(r,q);
        if (pool.size() < 2) return fail("Missing alternate shapes");
        for (const auto &entry : pool) {
            const auto chord = entry.toMap();
            if (chord["root"].toInt() != r || chord["quality"].toInt() != q) return fail("Incorrect filter result");
        }
    }
    if (!library.browse(99,99).isEmpty()) return fail("Invalid filter handling");
    qInfo() << "All 166 fingerings and 72 chord filters verified.";
    return 0;
}
