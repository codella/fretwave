// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella
#pragma once
#include <QObject>
#include <QSettings>
#include <QModelIndex>
#include <QApplication>
#include <QPalette>
#include <KColorSchemeManager>

class AppSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(QStringList favoriteKeys READ favoriteKeys WRITE setFavoriteKeys NOTIFY favoriteKeysChanged)
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QPalette palette READ palette NOTIFY paletteChanged)
public:
    explicit AppSettings(QObject *parent = nullptr) : QObject(parent) {
        connect(qApp, &QApplication::paletteChanged, this, &AppSettings::paletteChanged);
        QSettings settings;
        if (!settings.contains("appearance/theme")) {
            QSettings legacy(QSettings::defaultFormat(), QSettings::UserScope, "Fretwave", "fretwave");
            if (legacy.contains("appearance/theme"))
                settings.setValue("appearance/theme", legacy.value("appearance/theme"));
        }
        m_favoriteKeys = settings.value("chords/favorites").toStringList();
        m_theme = settings.value("appearance/theme", "system").toString();
        if (m_theme != "light" && m_theme != "dark") m_theme = "system";
        KColorSchemeManager::instance()->setAutosaveChanges(false);
    }
    QStringList favoriteKeys() const { return m_favoriteKeys; }
    void setFavoriteKeys(QStringList keys) {
        keys.removeDuplicates();
        if (m_favoriteKeys == keys) return;
        m_favoriteKeys = keys;
        QSettings().setValue("chords/favorites", keys);
        emit favoriteKeysChanged();
    }
    QString theme() const { return m_theme; }
    QPalette palette() const { return qApp->palette(); }
    void setTheme(const QString &value) {
        if (value != "system" && value != "light" && value != "dark") return;
        if (m_theme == value) return;
        m_theme = value;
        apply();
        QSettings().setValue("appearance/theme", m_theme);
        emit themeChanged();
    }
signals:
    void favoriteKeysChanged();
    void themeChanged();
    void paletteChanged();
public:
    void apply() {
        auto manager = KColorSchemeManager::instance();
        manager->activateScheme(manager->indexForSchemeId(m_theme == "light" ? "BreezeLight"
            : m_theme == "dark" ? "BreezeDark" : QString()));
    }
private:
    QString m_theme;
    QStringList m_favoriteKeys;
};
