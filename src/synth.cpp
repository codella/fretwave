// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

#include "synth.h"
#include <algorithm>
#include <cmath>

QList<int> Synth::chordNotes(const QVariantList &frets) {
    if (frets.size() != 6) return {};
    const int tuning[] = {40,45,50,55,59,64};
    QList<int> notes;
    for (int s = 0; s < 6; ++s) {
        bool valid = false;
        int fret = frets[s].toInt(&valid);
        if (!valid || fret < -1 || fret > 24) return {};
        if (fret >= 0) notes << tuning[s] + fret;
    }
    return notes;
}

QVector<float> Synth::render(const QList<int> &notes, int sampleRate) {
    if (notes.isEmpty() || notes.size() > 6 || sampleRate < 8000 || sampleRate > 192000) return {};
    for (int note : notes) if (note < 40 || note > 88) return {};
    constexpr double pi = 3.14159265358979323846;
    const int duration = int(2.8 * sampleRate);
    const int stagger = int(0.025 * sampleRate);
    QVector<float> mix(duration + (notes.size() - 1) * stagger, 0.f);
    for (int voice = 0; voice < notes.size(); ++voice) {
        double frequency = 440.0 * std::pow(2.0, (notes[voice] - 69) / 12.0);
        QVector<float> pluck(duration, 0.f);
        // Fast-decaying upper harmonics give a bright attack and a warm string-like tail.
        for (int harmonic = 1; harmonic <= 16 && harmonic * frequency < sampleRate * 0.45; ++harmonic) {
            const double step = 2 * pi * frequency * harmonic / sampleRate;
            const double sine = std::sin(step), cosine = std::cos(step);
            double real = 1, imag = 0;
            double amplitude = 0.42 * std::sin(harmonic * pi * 0.22) / std::pow(harmonic, 1.4);
            const double decay = std::exp(-(1.35 + 0.23 * harmonic) / sampleRate);
            for (int n = 0; n < duration; ++n) {
                pluck[n] += float(imag * amplitude);
                double next = real * cosine - imag * sine;
                imag = imag * cosine + real * sine;
                real = next;
                amplitude *= decay;
            }
        }
        const double gain = 1.0 / std::sqrt(double(notes.size()));
        for (int n = 0; n < duration; ++n) {
            double attack = std::min(1.0, n / (0.002 * sampleRate));
            double release = std::min(1.0, (duration - 1 - n) / (0.035 * sampleRate));
            mix[n + voice * stagger] += float(pluck[n] * gain * attack * release);
        }
    }
    float peak = 0;
    for (float sample : mix) peak = std::max(peak, std::abs(sample));
    if (peak > 0.85f) for (float &sample : mix) sample *= 0.85f / peak;
    return mix;
}
