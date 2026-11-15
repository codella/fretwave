// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella
#include "appsettings.h"
#include <QApplication>
#include <QTemporaryDir>
#include <QPalette>

int main(int argc, char **argv) {
    QApplication app(argc, argv);
    QTemporaryDir config;
    QCoreApplication::setOrganizationName("FretwaveTests");
    QCoreApplication::setApplicationName("Theme");
    QSettings::setDefaultFormat(QSettings::IniFormat);
    QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, config.path());
    AppSettings settings;
    settings.apply();
    if (settings.theme() != "system") return 1;
    const auto systemPalette = app.palette();
    if (!settings.favoriteKeys().isEmpty()) return 10;
    settings.setFavoriteKeys({"0::x,3,2,0,1,0", "0::x,3,2,0,1,0"});
    { AppSettings restored; if (restored.favoriteKeys().size() != 1) return 11; }
    settings.setFavoriteKeys({});
    { AppSettings restored; if (!restored.favoriteKeys().isEmpty()) return 12; }
    settings.setTheme("dark");
    if (app.palette().color(QPalette::Window).lightness() >= 128) return 2;
    { AppSettings restored; if (restored.theme() != "dark") return 3; }
    settings.setTheme("light");
    if (app.palette().color(QPalette::Window).lightness() <= 128) return 4;
    settings.setTheme("invalid");
    if (settings.theme() != "light") return 5;
    settings.setTheme("system");
    if (app.palette().color(QPalette::Window) != systemPalette.color(QPalette::Window)) return 6;
    AppSettings restored;
    if (restored.theme() != "system") return 7;
    QSettings().clear();
    QSettings legacy(QSettings::defaultFormat(), QSettings::UserScope, "Fretwave", "fretwave");
    legacy.setValue("appearance/theme", "dark");
    legacy.sync();
    AppSettings migrated;
    if (migrated.theme() != "dark") return 8;
    migrated.setTheme("light");
    AppSettings current;
    return current.theme() == "light" ? 0 : 9;
}
