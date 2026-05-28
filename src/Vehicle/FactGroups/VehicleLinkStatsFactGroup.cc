/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VehicleLinkStatsFactGroup.h"

#include <QtCore/QDateTime>
#include <QtCore/QDir>
#include <QtCore/QLoggingCategory>
#include <QtCore/QTextStream>
#include <QtCore/qmath.h>

#include "AppSettings.h"
#include "SettingsManager.h"
#include "Vehicle.h"

static QLoggingCategory linkStatsLog("qgc.linkstats");

VehicleLinkStatsFactGroup::VehicleLinkStatsFactGroup(QObject *parent)
    : FactGroup(100, QStringLiteral(":/json/Vehicle/LinkStatsFact.json"), parent)
{
    _addFact(&_msSinceLastPacketFact);
    _addFact(&_receiveRateFact);
    _addFact(&_messageRateFact);
    _addFact(&_lossPercentFact);
    _addFact(&_lossPerSecFact);

    _msSinceLastPacketFact.setRawValue(0u);
    _receiveRateFact.setRawValue(0.0f);
    _messageRateFact.setRawValue(0.0f);
    _lossPercentFact.setRawValue(0.0f);
    _lossPerSecFact.setRawValue(0.0f);

    connect(&_updateTimer, &QTimer::timeout, this, &VehicleLinkStatsFactGroup::_periodicUpdate);
    _updateTimer.start(100);
}

VehicleLinkStatsFactGroup::~VehicleLinkStatsFactGroup()
{
    if (_csvFile.isOpen()) {
        _csvFile.flush();
        _csvFile.close();
    }
}

void VehicleLinkStatsFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t &message)
{
    if (!_vehicle) {
        _vehicle = vehicle;
        _rateWindowTimer.start();
        _prevLossCount = vehicle ? vehicle->mavlinkLossCount() : 0;
    }
    _lastPacketTimer.restart();
    _messagesInWindow++;
    _setTelemetryAvailable(true);

    // Sniff GLOBAL_POSITION_INT to capture drone-side time_boot_ms; useful for both the CSV
    // log and as a "position freshness" signal in post-flight analysis (constant value
    // across consecutive rows means GPI was lost during that window, so distance is stale).
    if (message.msgid == MAVLINK_MSG_ID_GLOBAL_POSITION_INT) {
        mavlink_global_position_int_t pos{};
        mavlink_msg_global_position_int_decode(&message, &pos);
        _lastDroneTimeBootMs = pos.time_boot_ms;
        _haveDroneTimeBootMs = true;
    }
}

void VehicleLinkStatsFactGroup::_periodicUpdate()
{
    if (_lastPacketTimer.isValid()) {
        _msSinceLastPacketFact.setRawValue(static_cast<uint32_t>(_lastPacketTimer.elapsed()));
    }

    // 이 값이 윈도우 길이(ms) = CSV 기록 주기
    if (_rateWindowTimer.isValid() && _rateWindowTimer.elapsed() >= 1000) {
        const qint64 elapsedMs = _rateWindowTimer.elapsed();
        const uint32_t receivedInWindow = _messagesInWindow;
        _messagesInWindow = 0;
        const float receiveRate = static_cast<float>(receivedInWindow) * 1000.0f / static_cast<float>(elapsedMs);
        _receiveRateFact.setRawValue(receiveRate);

        float    lossPerSec = 0.0f;
        uint64_t deltaLoss  = 0;
        if (_vehicle) {
            const uint64_t currentLoss = _vehicle->mavlinkLossCount();
            deltaLoss  = currentLoss >= _prevLossCount ? currentLoss - _prevLossCount : 0;
            lossPerSec = static_cast<float>(deltaLoss) * 1000.0f / static_cast<float>(elapsedMs);
            _prevLossCount = currentLoss;
            _lossPerSecFact.setRawValue(lossPerSec);
        }

        // Per-window loss ratio: deltaLoss / (deltaReceived + deltaLoss).
        // When the window has no traffic at all, report 0% instead of NaN.
        const uint64_t totalInWindow = static_cast<uint64_t>(receivedInWindow) + deltaLoss;
        const float windowLossPct = totalInWindow > 0
            ? static_cast<float>(deltaLoss) * 100.0f / static_cast<float>(totalInWindow)
            : 0.0f;
        _lossPercentFact.setRawValue(windowLossPct);

        const float messageRate = receiveRate + lossPerSec;
        _messageRateFact.setRawValue(messageRate);

        _writeCsvRow(receiveRate, messageRate, windowLossPct, lossPerSec);

        _rateWindowTimer.restart();
    }
}

void VehicleLinkStatsFactGroup::_openCsvIfNeeded()
{
    if (_csvOpenAttempted || !_vehicle) {
        return;
    }
    _csvOpenAttempted = true;   // sticky: only one open attempt per vehicle session

    const QString telemetryDir = SettingsManager::instance()->appSettings()->telemetrySavePath();
    if (telemetryDir.isEmpty()) {
        qCWarning(linkStatsLog) << "telemetrySavePath() is empty; link_quality CSV disabled";
        return;
    }

    QDir dir(telemetryDir);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    const QString stamp    = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd hh-mm-ss"));
    const QString fileName = QStringLiteral("link_quality %1 vehicle%2.csv").arg(stamp).arg(_vehicle->id());
    _csvFile.setFileName(dir.absoluteFilePath(fileName));

    if (!_csvFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        qCWarning(linkStatsLog) << "Failed to open link_quality CSV:" << _csvFile.fileName()
                                << "error:" << _csvFile.errorString();
        return;
    }

    // Write header only if the file is empty (Append mode preserves existing content).
    if (_csvFile.size() == 0) {
        QTextStream header(&_csvFile);
        header << "qgc_timestamp,drone_time_boot_ms,ms_since_last,valid_rate,msg_rate,"
                  "loss_pct,loss_per_sec,distance_to_home_m\n";
        header.flush();
        _csvFile.flush();
    }

    qCDebug(linkStatsLog) << "link_quality CSV opened:" << _csvFile.fileName();
}

void VehicleLinkStatsFactGroup::_writeCsvRow(float receiveRate, float messageRate, float lossPercent, float lossPerSec)
{
    _openCsvIfNeeded();
    if (!_csvFile.isOpen()) {
        return;
    }

    // distance_to_home is a Vehicle Fact updated when GLOBAL_POSITION_INT decodes successfully;
    // it stays at the last known value when GPI is dropped/corrupted (or NaN before first GPI / no HOME_POSITION).
    const double distanceToHome = _vehicle ? _vehicle->distanceToHome()->rawValue().toDouble() : qQNaN();
    const QString distanceCell = qIsNaN(distanceToHome) ? QString() : QString::number(distanceToHome, 'f', 2);

    const QString droneTimeCell = _haveDroneTimeBootMs
        ? QString::number(_lastDroneTimeBootMs)
        : QString();

    const QString qgcTimestamp = QDateTime::currentDateTime().toString(Qt::ISODateWithMs);
    const uint32_t msSinceLast = _lastPacketTimer.isValid()
        ? static_cast<uint32_t>(_lastPacketTimer.elapsed())
        : 0u;

    QTextStream stream(&_csvFile);
    stream << qgcTimestamp << ','
           << droneTimeCell << ','
           << msSinceLast << ','
           << QString::number(receiveRate,  'f', 1) << ','
           << QString::number(messageRate,  'f', 1) << ','
           << QString::number(lossPercent,  'f', 1) << ','
           << QString::number(lossPerSec,   'f', 1) << ','
           << distanceCell << '\n';
    stream.flush();
    _csvFile.flush();   // push to OS kernel buffer for crash safety
}
