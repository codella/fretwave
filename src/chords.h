// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: 2026 Mauro Codella

#pragma once
#include <QObject>
#include <QVariantList>

class Chords : public QObject {
    Q_OBJECT
    Q_PROPERTY(QStringList roots READ roots CONSTANT)
    Q_PROPERTY(QStringList qualities READ qualities CONSTANT)
public:
    explicit Chords(QObject *parent = nullptr);
    QStringList roots() const;
    QStringList qualities() const;
    Q_INVOKABLE QVariantList browse(int root, int quality) const;
private:
    QVariantList m_chords;
};
