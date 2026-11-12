// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

#include <QApplication>
#include <QFontDatabase>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickItem>
#include <QMouseEvent>
#include <QEventLoop>
#include <QTimer>
#include <QJSValue>
#include <cstdio>
#include "chords.h"
#include "audioengine.h"

int main(int argc, char **argv) {
    QApplication app(argc, argv);
    app.setApplicationName("fretwave");
    app.setApplicationDisplayName("Fretwave");
    app.setOrganizationName("Fretwave");
    app.setDesktopFileName("io.github.codella.fretwave");
    app.setWindowIcon(QIcon(":/icons/fretwave-256.png"));
    for (const QString &file : {QStringLiteral("NotoSans-Regular.ttf"), QStringLiteral("Lato-Regular.ttf"), QStringLiteral("Lato-Bold.ttf"), QStringLiteral("Oswald.ttf")}) {
        if (QFontDatabase::addApplicationFont(":/fonts/" + file) < 0) {
            fprintf(stderr, "Failed to load bundled font.\n");
            return 1;
        }
    }
    QFont interfaceFont(QStringLiteral("Lato"));
    interfaceFont.setPointSize(11);
    app.setFont(interfaceFont);
    Chords chords;
    AudioEngine audioEngine;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("chordLibrary", &chords);
    engine.rootContext()->setContextProperty("audioEngine", &audioEngine);
    engine.rootContext()->setContextProperty("appFontFamily", interfaceFont.family());
    engine.rootContext()->setContextProperty("displayFontFamily", QStringLiteral("Oswald"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule("Fretwave", "Main");
    if (app.arguments().contains("--audio-test")) {
        QTimer::singleShot(200, &app, [&] {
            audioEngine.playNote(45);
            QTimer::singleShot(400, &app, [&] {
                auto button = engine.rootObjects().isEmpty() ? nullptr
                    : engine.rootObjects().first()->findChild<QObject *>("playChordButton");
                if (!audioEngine.playing() || audioEngine.chordPlaying() || !audioEngine.error().isEmpty()
                    || !button || button->property("enabled").toBool()) {
                    fprintf(stderr, "Note playback failed: %s\n", qPrintable(audioEngine.error()));
                    app.exit(3); return;
                }
                audioEngine.playChord({-1,3,2,0,1,0});
                QTimer::singleShot(500, &app, [&] {
                    auto button = engine.rootObjects().first()->findChild<QObject *>("playChordButton");
                    bool ok = audioEngine.playing() && audioEngine.chordPlaying() && audioEngine.error().isEmpty()
                        && button && button->property("enabled").toBool();
                    auto fretArea = engine.rootObjects().first()->findChild<QObject *>("fretPlaybackArea");
                    ok &= fretArea && fretArea->property("acceptedButtons").toInt() == int(Qt::NoButton);
                    audioEngine.playNote(64);
                    ok &= !audioEngine.chordPlaying();
                    ok &= fretArea && fretArea->property("acceptedButtons").toInt() == int(Qt::LeftButton);
                    audioEngine.setVolume(0);
                    ok &= audioEngine.volume() == 0;
                    audioEngine.stop();
                    ok &= !audioEngine.playing() && !audioEngine.chordPlaying();
                    ok &= button && button->property("enabled").toBool();
                    fprintf(stderr, "%s\n", ok ? "Note/chord output, mute and stop verified on the audio device." : "Audio output test failed.");
                    app.exit(ok ? 0 : 3);
                });
            });
        });
    }
    if (app.arguments().contains("--verify-ui")) QTimer::singleShot(300, &app, [&] {
        bool ok = !engine.rootObjects().isEmpty();
        if (ok) {
            auto window = engine.rootObjects().first();
            auto rootFilter = window->findChild<QObject *>("rootFilter");
            auto typeFilter = window->findChild<QObject *>("typeFilter");
            auto list = window->findChild<QObject *>("chordList");
            ok = rootFilter && typeFilter && list;
            if (ok) {
                rootFilter->setProperty("currentIndex", 6); // F
                typeFilter->setProperty("currentIndex", 2); // minor
                QMetaObject::invokeMethod(window, "refresh");
                auto selection = window->property("selected");
                auto selected = selection.canConvert<QJSValue>() ? selection.value<QJSValue>().toVariant().toMap() : selection.toMap();
                ok &= selected["name"].toString() == "Fm";
                for (int type : {5, 6}) {
                    rootFilter->setProperty("currentIndex", 1); // C
                    typeFilter->setProperty("currentIndex", type);
                    QMetaObject::invokeMethod(window, "refresh");
                    auto value = window->property("selected");
                    auto chord = value.canConvert<QJSValue>() ? value.value<QJSValue>().toVariant().toMap() : value.toMap();
                    ok &= chord["name"].toString() == (type == 5 ? "Csus2" : "Csus4");
                }
                rootFilter->setProperty("currentIndex", 0);
                typeFilter->setProperty("currentIndex", 0);
                QMetaObject::invokeMethod(window, "refresh");
                ok &= list->property("count").toInt() == 166;
                list->setProperty("currentIndex", 165);
                auto value = window->property("selected");
                auto chord = value.canConvert<QJSValue>() ? value.value<QJSValue>().toVariant().toMap() : value.toMap();
                ok &= chord["name"].toString() == "Bsus4";
                auto tabs = window->findChild<QObject *>("mainTabs");
                ok &= tabs != nullptr;
                for (int tab = 1; tabs && tab <= 2; ++tab) {
                    tabs->setProperty("currentIndex", tab);
                    auto wheel = window->findChild<QObject *>(tab == 1 ? "chromaticWheel" : "fifthsWheel");
                    ok &= wheel != nullptr;
                    if (!wheel) continue;
                    for (int position = 0; position < 12; ++position) {
                        QVariant note;
                        ok &= QMetaObject::invokeMethod(wheel, "noteAt", Q_RETURN_ARG(QVariant, note), Q_ARG(QVariant, QVariant(position)));
                        ok &= note.toInt() == (9 + position * (tab == 1 ? 1 : 7)) % 12;
                    }
                    wheel->setProperty("selectedNote", 9);
                    wheel->setProperty("chordType", 1);
                    auto value = wheel->property("selectedChord");
                    auto triad = value.canConvert<QJSValue>() ? value.value<QJSValue>().toVariant().toMap() : value.toMap();
                    ok &= triad["notes"].toString() == "A · C · E";
                }
                if (tabs) tabs->setProperty("currentIndex", 0);
                ok &= list->property("currentIndex").toInt() == 165;
                window->setProperty("focusMode", true);
                ok &= !list->property("visible").toBool() && !rootFilter->property("visible").toBool();
                ok &= list->property("currentIndex").toInt() == 165;
                window->setProperty("focusMode", false);
                ok &= list->property("visible").toBool() && rootFilter->property("visible").toBool();
                auto diagram = window->findChild<QObject *>("chordDiagram");
                ok &= diagram != nullptr;
                if (diagram) {
                    auto invoke = [&](const char *method, QVariant a, QVariant b) {
                        QVariant result;
                        ok &= QMetaObject::invokeMethod(diagram, method, Q_RETURN_ARG(QVariant, result),
                            Q_ARG(QVariant, a), Q_ARG(QVariant, b));
                        return result.toString();
                    };
                    const QStringList openNotes {"E2", "A2", "D3", "G3", "B3", "E4"};
                    const QStringList octaveNotes {"E3", "A3", "D4", "G4", "B4", "E5"};
                    for (int string = 0; string < 6; ++string) {
                        ok &= invoke("noteAt", string, 0) == openNotes[string];
                        ok &= invoke("noteAt", string, 12) == octaveNotes[string];
                    }
                    ok &= invoke("noteAt", 0, 2) == "F♯2 / G♭2";
                    list->setProperty("currentIndex", 0); // Open C
                    double left = diagram->property("neckLeft").toDouble();
                    double dx = diagram->property("stringSpacing").toDouble();
                    auto center = [&](int offset) {
                        QVariant result;
                        ok &= QMetaObject::invokeMethod(diagram, "fretCenter", Q_RETURN_ARG(QVariant, result), Q_ARG(QVariant, QVariant(offset)));
                        return result.toDouble();
                    };
                    ok &= invoke("tooltipAt", left + dx, center(2)) == "C3";
                    ok &= invoke("midiAt", left + dx, center(2)) == "48";
                    ok &= invoke("midiAt", left, 21) == "-1";
                    ok &= invoke("midiAt", left + 5 * dx, 21) == "64";
                    ok &= invoke("tooltipAt", left + 5 * dx, 21) == "E4";
                    ok &= invoke("tooltipAt", left, 21).startsWith("Muted in this chord");
                    ok &= invoke("tooltipAt", -10, center(2)).isEmpty();
                    ok &= invoke("tooltipAt", left, 389).isEmpty();
                    list->setProperty("currentIndex", 165); // Bsus4, E-shape at fret 7
                    ok &= invoke("tooltipAt", left, center(0)) == "B2";
                    list->setProperty("currentIndex", 0);
                    if (auto item = qobject_cast<QQuickItem *>(diagram)) {
                        auto quickWindow = item->window();
                        auto position = item->mapToScene(QPointF(left + dx, center(2)));
                        QMouseEvent move(QEvent::MouseMove, position, quickWindow->mapToGlobal(position),
                            Qt::NoButton, Qt::NoButton, Qt::NoModifier);
                        QCoreApplication::sendEvent(quickWindow, &move);
                        QEventLoop hoverWait;
                        QTimer::singleShot(500, &hoverWait, &QEventLoop::quit);
                        hoverWait.exec();
                        auto tooltip = diagram->findChild<QObject *>("noteTooltip");
                        ok &= tooltip && tooltip->property("visible").toBool()
                            && tooltip->property("text").toString() == "C3";
                        const int capture = app.arguments().indexOf("--screenshot");
                        if (capture >= 0 && capture + 1 < app.arguments().size())
                            quickWindow->grabWindow().save(app.arguments()[capture + 1]);
                        window->setProperty("focusMode", true);
                        QEventLoop focusWait;
                        QTimer::singleShot(100, &focusWait, &QEventLoop::quit);
                        focusWait.exec();
                        const double zoom = diagram->property("zoom").toDouble();
                        ok &= zoom > 1 && diagram->property("scale").toDouble() == 1;
                        left = diagram->property("neckLeft").toDouble();
                        dx = diagram->property("stringSpacing").toDouble();
                        ok &= invoke("tooltipAt", (left + dx) * zoom, center(2) * zoom) == "C3";
                        ok &= invoke("tooltipAt", (left + 5 * dx) * zoom, 21 * zoom) == "E4";
                        window->setProperty("focusMode", false);
                        QEventLoop layoutWait;
                        QTimer::singleShot(100, &layoutWait, &QEventLoop::quit);
                        layoutWait.exec();
                        auto intervalLabel = window->findChild<QQuickItem *>("intervalLabel");
                        auto intervalTip = window->findChild<QObject *>("intervalTooltip");
                        ok &= intervalLabel && intervalTip;
                        if (intervalLabel && intervalTip) {
                            auto point = intervalLabel->mapToScene(QPointF(intervalLabel->width() / 2, intervalLabel->height() / 2));
                            QMouseEvent intervalMove(QEvent::MouseMove, point, quickWindow->mapToGlobal(point),
                                Qt::NoButton, Qt::NoButton, Qt::NoModifier);
                            QCoreApplication::sendEvent(quickWindow, &intervalMove);
                            QEventLoop intervalWait;
                            QTimer::singleShot(500, &intervalWait, &QEventLoop::quit);
                            intervalWait.exec();
                            const QString explanation = intervalTip->property("text").toString();
                            ok &= intervalTip->property("visible").toBool() && explanation.contains("C major")
                                && explanation.contains("3 → E: Major third · 4 semitones");
                            if (capture >= 0 && capture + 1 < app.arguments().size())
                                quickWindow->grabWindow().save(app.arguments()[capture + 1]);
                            rootFilter->setProperty("currentIndex", 1);
                            typeFilter->setProperty("currentIndex", 2);
                            QMetaObject::invokeMethod(window, "refresh");
                            ok &= intervalTip->property("text").toString().contains("♭3 → Eb: Minor third · 3 semitones");
                        }
                    } else { ok = false; }
                }
            }
        }
        fprintf(stderr, "%s\n", ok ? "UI filtering, chord selection, wheel ordering, tab switching and fretboard note tooltips passed." : "UI verification failed.");
        app.exit(ok ? 0 : 2);
    });
    if (app.arguments().contains("--smoke-test")) QTimer::singleShot(1800, &app, &QCoreApplication::quit);
    if (app.arguments().contains("--focus") && !engine.rootObjects().isEmpty())
        engine.rootObjects().first()->setProperty("focusMode", true);
    const int tabArg = app.arguments().indexOf("--tab");
    if (tabArg >= 0 && tabArg + 1 < app.arguments().size() && !engine.rootObjects().isEmpty()) {
        if (auto tabs = engine.rootObjects().first()->findChild<QObject *>("mainTabs"))
            tabs->setProperty("currentIndex", qBound(0, app.arguments()[tabArg + 1].toInt(), 2));
    }
    const int shot = app.arguments().indexOf("--screenshot");
    if (shot >= 0 && shot + 1 < app.arguments().size()) {
        const QString path = app.arguments()[shot + 1];
        QTimer::singleShot(1200, &app, [&engine, path] {
            if (!engine.rootObjects().isEmpty())
                if (auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first())) window->grabWindow().save(path);
        });
    }
    return app.exec();
}
