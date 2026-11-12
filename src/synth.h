// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

#pragma once
#include <QList>
#include <QVariantList>
#include <QVector>

namespace Synth {
QList<int> chordNotes(const QVariantList &frets);
QVector<float> render(const QList<int> &notes, int sampleRate);
}
