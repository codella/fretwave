// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

#include "synth.h"
#include <QCoreApplication>
#include <cmath>
#include <cstdio>

int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    auto fail = [](const char *message) { fprintf(stderr, "%s\n", message); return 1; };
    if (Synth::chordNotes({-1,3,2,0,1,0}) != QList<int>{48,52,55,60,64}) return fail("Open C voicing incorrect");
    if (Synth::chordNotes({1,3,3,2,1,1}) != QList<int>{41,48,53,57,60,65}) return fail("Barre voicing incorrect");
    if (!Synth::chordNotes({-1,-1,-1,-1,-1,-1}).isEmpty()) return fail("Muted strings should be silent");
    if (!Synth::chordNotes({0,0}).isEmpty() || !Synth::render({200},48000).isEmpty()) return fail("Invalid input accepted");
    for (int rate : {44100,48000}) {
        auto samples = Synth::render({45}, rate); // A2 = 110 Hz
        if (samples.size() != int(2.8 * rate)) return fail("Wrong duration");
        double energy = 0, lateEnergy = 0;
        for (int n = 0; n < samples.size(); ++n) {
            if (!std::isfinite(samples[n]) || std::abs(samples[n]) > 0.85) return fail("Invalid or clipped sample");
            if (n < rate / 2) energy += samples[n] * samples[n];
            if (n > 2 * rate && n < 2.5 * rate) lateEnergy += samples[n] * samples[n];
        }
        if (energy < 1 || lateEnergy >= energy / 10) return fail("Missing pluck or decay");
        if (samples.first() != 0 || samples.last() != 0) return fail("Missing click-suppression envelope");
        auto magnitude = [&](double frequency) {
            double real = 0, imag = 0;
            for (int n = 0; n < rate / 2; ++n) {
                double angle = 2 * 3.141592653589793 * frequency * n / rate;
                real += samples[n] * std::cos(angle);
                imag += samples[n] * std::sin(angle);
            }
            return std::hypot(real, imag);
        };
        if (magnitude(110) < 4 * magnitude(103.826) || magnitude(110) < 4 * magnitude(116.541))
            return fail("A2 is not tuned to 110 Hz");
        auto chord = Synth::render({40,47,52,56,59,64}, rate);
        for (float sample : chord) if (!std::isfinite(sample) || std::abs(sample) > 0.851) return fail("Chord clips");
    }
    fprintf(stderr, "Voicings, muted strings, pitch, decay and audio headroom verified.\n");
    return 0;
}
