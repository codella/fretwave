// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

#include "chords.h"
#include <algorithm>

QStringList Chords::roots() const { return {"C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"}; }
QStringList Chords::qualities() const { return {"Major", "Minor", "Dominant 7", "Minor 7", "Sus2", "Sus4"}; }

Chords::Chords(QObject *parent) : QObject(parent) {
    const QStringList suffixes {"", "m", "7", "m7", "sus2", "sus4"};
    const QStringList formulas {"1 · 3 · 5", "1 · ♭3 · 5", "1 · 3 · 5 · ♭7", "1 · ♭3 · 5 · ♭7", "1 · 2 · 5", "1 · 4 · 5"};
    const QList<QList<int>> intervals {{0,4,7}, {0,3,7}, {0,4,7,10}, {0,3,7,10}, {0,2,7}, {0,5,7}};
    const QList<QList<int>> degrees {{0,2,4}, {0,2,4}, {0,2,4,6}, {0,2,4,6}, {0,1,4}, {0,3,4}};
    auto add = [&](int root, int quality, const QString &shape, QList<int> frets, QList<int> fingers, int barre, int barreStart = -1) {
        QVariantList fretValues, fingerValues, pitchClasses;
        int first = 99;
        for (int f : frets) { fretValues << f; if (f > 0) first = std::min(first, f); }
        for (int f : fingers) fingerValues << f;
        QStringList notes;
        const QString letters = "CDEFGAB";
        const QList<int> natural {0,2,4,5,7,9,11};
        int letter = letters.indexOf(roots()[root][0]);
        for (int i = 0; i < intervals[quality].size(); ++i) {
            int pitch = (root + intervals[quality][i]) % 12;
            pitchClasses << pitch;
            int noteLetter = (letter + degrees[quality][i]) % 7;
            int accidental = (pitch - natural[noteLetter] + 18) % 12 - 6;
            QString note(letters[noteLetter]);
            while (accidental > 0) { note += "#"; --accidental; }
            while (accidental < 0) { note += "b"; ++accidental; }
            notes << note;
        }
        QVariantList intervalDetails;
        const QStringList symbols = formulas[quality].split(" · ");
        const QMap<int, QString> intervalNames {{0,"Root"}, {2,"Major second"}, {3,"Minor third"},
            {4,"Major third"}, {5,"Perfect fourth"}, {7,"Perfect fifth"}, {10,"Minor seventh"}};
        for (int i = 0; i < intervals[quality].size(); ++i) {
            int semitones = intervals[quality][i];
            intervalDetails << QVariantMap{{"symbol", symbols[i]}, {"note", notes[i]},
                {"name", intervalNames[semitones]}, {"semitones", semitones}};
        }
        m_chords << QVariantMap{{"id", QString::number(m_chords.size())}, {"name", roots()[root] + suffixes[quality]},
            {"root", root}, {"quality", quality}, {"shape", shape}, {"frets", fretValues}, {"fingers", fingerValues},
            {"firstFret", *std::max_element(frets.begin(), frets.end()) <= 5 ? 1 : first}, {"barre", barre}, {"barreStart", barreStart >= 0 ? barreStart : (frets[0] < 0 ? 1 : 0)},
            {"intervalDetails", intervalDetails}, {"title", roots()[root] + " " + qualities()[quality].toLower()},
            {"notes", notes.join(" · ")}, {"formula", formulas[quality]}, {"pitchClasses", pitchClasses}};
    };
    add(0,0,"Open C",{-1,3,2,0,1,0},{0,3,2,0,1,0},0);
    add(2,0,"Open D",{-1,-1,0,2,3,2},{0,0,0,1,3,2},0);
    add(2,1,"Open D minor",{-1,-1,0,2,3,1},{0,0,0,2,3,1},0);
    add(4,0,"Open E",{0,2,2,1,0,0},{0,2,3,1,0,0},0);
    add(4,1,"Open E minor",{0,2,2,0,0,0},{0,2,3,0,0,0},0);
    add(7,0,"Open G",{3,2,0,0,0,3},{2,1,0,0,0,3},0);
    add(9,0,"Open A",{-1,0,2,2,2,0},{0,0,1,2,3,0},0);
    add(9,1,"Open A minor",{-1,0,2,2,1,0},{0,0,2,3,1,0},0);
    add(0,2,"Open C7",{-1,3,2,3,1,0},{0,3,2,4,1,0},0);
    add(2,2,"Open D7",{-1,-1,0,2,1,2},{0,0,0,2,1,3},0);
    add(4,2,"Open E7",{0,2,0,1,0,0},{0,2,0,1,0,0},0);
    add(7,2,"Open G7",{3,2,0,0,0,1},{3,2,0,0,0,1},0);
    add(9,2,"Open A7",{-1,0,2,0,2,0},{0,0,1,0,2,0},0);
    add(2,3,"Open D minor 7",{-1,-1,0,2,1,1},{0,0,0,2,1,1},1);
    add(4,3,"Open E minor 7",{0,2,0,0,0,0},{0,2,0,0,0,0},0);
    add(9,3,"Open A minor 7",{-1,0,2,0,1,0},{0,0,2,0,1,0},0);
    // The Dm7 mini-barre covers only B and high E.
    auto dm = m_chords[13].toMap(); dm["barreStart"] = 4; m_chords[13] = dm;
    add(0,4,"Open C sus2",{-1,3,0,0,1,3},{0,3,0,0,1,4},0);
    add(2,4,"Open D sus2",{-1,-1,0,2,3,0},{0,0,0,1,3,0},0);
    add(9,4,"Open A sus2",{-1,0,2,2,0,0},{0,0,2,3,0,0},0);
    add(2,5,"Open D sus4",{-1,-1,0,2,3,3},{0,0,0,1,3,4},0);
    add(4,5,"Open E sus4",{0,2,2,2,0,0},{0,2,3,4,0,0},0);
    add(9,5,"Open A sus4",{-1,0,2,2,3,0},{0,0,1,2,3,0},0);
    for (int r = 0; r < 12; ++r) {
        int e = (r - 4 + 12) % 12; if (!e) e = 12;
        int a = (r - 9 + 12) % 12; if (!a) a = 12;
        int d = (r - 2 + 12) % 12; if (!d) d = 12;
        add(r,0,"E-shape barre",{e,e+2,e+2,e+1,e,e},{1,3,4,2,1,1},e);
        add(r,1,"E-shape barre",{e,e+2,e+2,e,e,e},{1,3,4,1,1,1},e);
        add(r,2,"E-shape barre",{e,e+2,e,e+1,e,e},{1,3,1,2,1,1},e);
        add(r,3,"E-shape barre",{e,e+2,e,e,e,e},{1,3,1,1,1,1},e);
        add(r,0,"A-shape barre",{-1,a,a+2,a+2,a+2,a},{0,1,2,3,4,1},a);
        add(r,1,"A-shape barre",{-1,a,a+2,a+2,a+1,a},{0,1,3,4,2,1},a);
        add(r,2,"A-shape barre",{-1,a,a+2,a,a+2,a},{0,1,3,1,4,1},a);
        add(r,3,"A-shape barre",{-1,a,a+2,a,a+1,a},{0,1,3,1,2,1},a);
        add(r,4,"A-shape barre",{-1,a,a+2,a+2,a,a},{0,1,3,4,1,1},a);
        add(r,4,"D-shape barre",{-1,-1,d,d+2,d+3,d},{0,0,1,3,4,1},d,2);
        add(r,5,"E-shape barre",{e,e+2,e+2,e+2,e,e},{1,2,3,4,1,1},e);
        add(r,5,"A-shape barre",{-1,a,a+2,a+2,a+3,a},{0,1,2,3,4,1},a);
    }
}
QVariantList Chords::browse(int root, int quality) const {
    QVariantList result;
    for (const auto &entry : m_chords) {
        auto chord = entry.toMap();
        if ((root < 0 || chord["root"].toInt() == root) && (quality < 0 || chord["quality"].toInt() == quality)) result << entry;
    }
    std::stable_sort(result.begin(), result.end(), [](const QVariant &a, const QVariant &b) {
        const auto left = a.toMap(), right = b.toMap();
        for (const auto &key : {"root", "quality", "firstFret"}) {
            if (left[key].toInt() != right[key].toInt()) return left[key].toInt() < right[key].toInt();
        }
        return false;
    });
    return result;
}
