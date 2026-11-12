// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

#include "audioengine.h"
#include "synth.h"
#include <QMediaDevices>
#include <QAudioDevice>
#include <algorithm>
#include <cmath>

AudioEngine::AudioEngine(QObject *parent) : QObject(parent) {}
AudioEngine::~AudioEngine() { stop(); }
void AudioEngine::setPlaying(bool value) {
    if (m_playing == value) return;
    m_playing = value;
    emit playingChanged();
}
void AudioEngine::setError(const QString &message) {
    if (m_error == message) return;
    m_error = message;
    emit errorChanged();
}
void AudioEngine::setVolume(qreal value) {
    if (!std::isfinite(value)) return;
    value = std::clamp(value, 0.0, 1.0);
    if (m_volume == value) return;
    m_volume = value;
    if (m_sink) m_sink->setVolume(value * value);
    emit volumeChanged();
}
void AudioEngine::stop() {
    if (m_sink) {
        disconnect(m_sink.get(), nullptr, this, nullptr);
        m_sink->reset();
        m_sink.reset();
    }
    m_buffer.close();
    setPlaying(false);
}
void AudioEngine::playNote(int midi) { play({midi}); }
void AudioEngine::playChord(const QVariantList &frets) { play(Synth::chordNotes(frets)); }
void AudioEngine::play(const QList<int> &notes) {
    stop();
    setError({});
    if (notes.isEmpty()) return;
    const auto device = QMediaDevices::defaultAudioOutput();
    if (device.isNull()) { setError("No audio output found. Connect speakers or headphones and try again."); return; }
    const auto format = device.preferredFormat();
    if (!format.isValid() || !device.isFormatSupported(format)) {
        setError("The audio output format is unavailable."); return;
    }
    const auto samples = Synth::render(notes, format.sampleRate());
    if (samples.isEmpty()) { setError("This note cannot be played."); return; }
    QByteArray pcm;
    pcm.reserve(samples.size() * format.bytesPerFrame());
    for (float sample : samples) {
        for (int channel = 0; channel < format.channelCount(); ++channel) {
            switch (format.sampleFormat()) {
            case QAudioFormat::Float: pcm.append(reinterpret_cast<const char *>(&sample), sizeof(sample)); break;
            case QAudioFormat::Int16: {
                qint16 value = qint16(std::lround(sample * 32767));
                pcm.append(reinterpret_cast<const char *>(&value), sizeof(value)); break;
            }
            case QAudioFormat::Int32: {
                qint32 value = qint32(std::llround(sample * 2147483647.0));
                pcm.append(reinterpret_cast<const char *>(&value), sizeof(value)); break;
            }
            case QAudioFormat::UInt8: pcm.append(char(std::lround((sample + 1) * 127.5))); break;
            default: setError("The audio output format is unsupported."); return;
            }
        }
    }
    m_buffer.setData(pcm);
    m_buffer.open(QIODevice::ReadOnly);
    m_sink = std::make_unique<QAudioSink>(device, format);
    m_sink->setVolume(m_volume * m_volume);
    connect(m_sink.get(), &QAudioSink::stateChanged, this, [this](QAudio::State state) {
        setPlaying(state == QAudio::ActiveState);
        if (state == QAudio::StoppedState && m_sink && m_sink->error() != QAudio::NoError)
            setError("Audio playback stopped. Check your output device and try again.");
    });
    m_sink->start(&m_buffer);
    if (m_sink->error() != QAudio::NoError)
        setError("Could not play audio. Check your output device and try again.");
}
