/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QElapsedTimer>
#include <QtCore/QFile>
#include <QtCore/QPointer>
#include <QtCore/QTimer>

#include "FactGroup.h"

class Vehicle;

class VehicleLinkStatsFactGroup : public FactGroup
{
    Q_OBJECT
    Q_PROPERTY(Fact *msSinceLastPacket READ msSinceLastPacket CONSTANT)
    Q_PROPERTY(Fact *receiveRate       READ receiveRate       CONSTANT)
    Q_PROPERTY(Fact *messageRate       READ messageRate       CONSTANT)
    Q_PROPERTY(Fact *lossPercent       READ lossPercent       CONSTANT)
    Q_PROPERTY(Fact *lossPerSec        READ lossPerSec        CONSTANT)

public:
    explicit VehicleLinkStatsFactGroup(QObject *parent = nullptr);
    ~VehicleLinkStatsFactGroup() override;

    Fact *msSinceLastPacket() { return &_msSinceLastPacketFact; }
    Fact *receiveRate()       { return &_receiveRateFact; }
    Fact *messageRate()       { return &_messageRateFact; }
    Fact *lossPercent()       { return &_lossPercentFact; }
    Fact *lossPerSec()        { return &_lossPerSecFact; }

    void handleMessage(Vehicle *vehicle, const mavlink_message_t &message) final;

private slots:
    void _periodicUpdate();

private:
    void _openCsvIfNeeded();
    void _writeCsvRow(float receiveRate, float messageRate, float lossPercent, float lossPerSec);

    Fact _msSinceLastPacketFact = Fact(0, QStringLiteral("msSinceLastPacket"), FactMetaData::valueTypeUint32);
    Fact _receiveRateFact       = Fact(0, QStringLiteral("receiveRate"),       FactMetaData::valueTypeFloat);
    Fact _messageRateFact       = Fact(0, QStringLiteral("messageRate"),       FactMetaData::valueTypeFloat);
    Fact _lossPercentFact       = Fact(0, QStringLiteral("lossPercent"),       FactMetaData::valueTypeFloat);
    Fact _lossPerSecFact        = Fact(0, QStringLiteral("lossPerSec"),        FactMetaData::valueTypeFloat);

    QPointer<Vehicle> _vehicle;
    QElapsedTimer     _lastPacketTimer;
    QElapsedTimer     _rateWindowTimer;
    uint32_t          _messagesInWindow = 0;
    uint64_t          _prevLossCount    = 0;
    QTimer            _updateTimer;

    // CSV logging — separate "link_quality" file, complements .tlog (raw) without duplicating it
    QFile             _csvFile;
    bool              _csvOpenAttempted    = false;  // try open once; sticky failure if open fails
    bool              _haveDroneTimeBootMs = false;
    uint32_t          _lastDroneTimeBootMs = 0;
};
