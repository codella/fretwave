// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

#pragma once
#include <QObject>
#include <QAudioSink>
#include <QBuffer>
#include <QVariantList>
#include <memory>

class AudioEngine : public QObject {
    Q_OBJECT
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(bool chordPlaying READ chordPlaying NOTIFY playingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
public:
    explicit AudioEngine(QObject *parent = nullptr);
    ~AudioEngine() override;
    qreal volume() const { return m_volume; }
    bool playing() const { return m_playing; }
    bool chordPlaying() const { return m_playing && m_chordPlayback; }
    QString error() const { return m_error; }
    void setVolume(qreal value);
    Q_INVOKABLE void playNote(int midi);
    Q_INVOKABLE void playChord(const QVariantList &frets);
    Q_INVOKABLE void stop();
signals:
    void volumeChanged();
    void playingChanged();
    void errorChanged();
private:
    void play(const QList<int> &notes, bool chord = false);
    void setPlaying(bool playing);
    void setError(const QString &message);
    qreal m_volume = 0.6;
    bool m_playing = false;
    bool m_chordPlayback = false;
    QString m_error;
    QBuffer m_buffer;
    std::unique_ptr<QAudioSink> m_sink;
};
