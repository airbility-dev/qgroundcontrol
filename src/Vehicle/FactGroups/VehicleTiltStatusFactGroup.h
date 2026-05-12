/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "FactGroup.h"

class VehicleTiltStatusFactGroup : public FactGroup
{
    Q_OBJECT
    Q_PROPERTY(Fact *realtimeTickFl READ realtimeTickFl CONSTANT)
    Q_PROPERTY(Fact *realtimeTickFr READ realtimeTickFr CONSTANT)
    Q_PROPERTY(Fact *realtimeTickRl READ realtimeTickRl CONSTANT)
    Q_PROPERTY(Fact *realtimeTickRr READ realtimeTickRr CONSTANT)
    Q_PROPERTY(Fact *errorStatusFl  READ errorStatusFl  CONSTANT)
    Q_PROPERTY(Fact *errorStatusFr  READ errorStatusFr  CONSTANT)
    Q_PROPERTY(Fact *errorStatusRl  READ errorStatusRl  CONSTANT)
    Q_PROPERTY(Fact *errorStatusRr  READ errorStatusRr  CONSTANT)
    Q_PROPERTY(Fact *angleFl        READ angleFl        CONSTANT)
    Q_PROPERTY(Fact *angleFr        READ angleFr        CONSTANT)
    Q_PROPERTY(Fact *angleRl        READ angleRl        CONSTANT)
    Q_PROPERTY(Fact *angleRr        READ angleRr        CONSTANT)
    Q_PROPERTY(Fact *angularVelFl   READ angularVelFl   CONSTANT)
    Q_PROPERTY(Fact *angularVelFr   READ angularVelFr   CONSTANT)
    Q_PROPERTY(Fact *angularVelRl   READ angularVelRl   CONSTANT)
    Q_PROPERTY(Fact *angularVelRr   READ angularVelRr   CONSTANT)
    Q_PROPERTY(Fact *voltageFl      READ voltageFl      CONSTANT)
    Q_PROPERTY(Fact *voltageFr      READ voltageFr      CONSTANT)
    Q_PROPERTY(Fact *voltageRl      READ voltageRl      CONSTANT)
    Q_PROPERTY(Fact *voltageRr      READ voltageRr      CONSTANT)
    Q_PROPERTY(Fact *currentFl      READ currentFl      CONSTANT)
    Q_PROPERTY(Fact *currentFr      READ currentFr      CONSTANT)
    Q_PROPERTY(Fact *currentRl      READ currentRl      CONSTANT)
    Q_PROPERTY(Fact *currentRr      READ currentRr      CONSTANT)
    Q_PROPERTY(Fact *temperatureFl  READ temperatureFl  CONSTANT)
    Q_PROPERTY(Fact *temperatureFr  READ temperatureFr  CONSTANT)
    Q_PROPERTY(Fact *temperatureRl  READ temperatureRl  CONSTANT)
    Q_PROPERTY(Fact *temperatureRr  READ temperatureRr  CONSTANT)

public:
    explicit VehicleTiltStatusFactGroup(QObject *parent = nullptr);

    Fact *realtimeTickFl() { return &_realtimeTickFlFact; }
    Fact *realtimeTickFr() { return &_realtimeTickFrFact; }
    Fact *realtimeTickRl() { return &_realtimeTickRlFact; }
    Fact *realtimeTickRr() { return &_realtimeTickRrFact; }
    Fact *errorStatusFl()  { return &_errorStatusFlFact; }
    Fact *errorStatusFr()  { return &_errorStatusFrFact; }
    Fact *errorStatusRl()  { return &_errorStatusRlFact; }
    Fact *errorStatusRr()  { return &_errorStatusRrFact; }
    Fact *angleFl()        { return &_angleFlFact; }
    Fact *angleFr()        { return &_angleFrFact; }
    Fact *angleRl()        { return &_angleRlFact; }
    Fact *angleRr()        { return &_angleRrFact; }
    Fact *angularVelFl()   { return &_angularVelFlFact; }
    Fact *angularVelFr()   { return &_angularVelFrFact; }
    Fact *angularVelRl()   { return &_angularVelRlFact; }
    Fact *angularVelRr()   { return &_angularVelRrFact; }
    Fact *voltageFl()      { return &_voltageFlFact; }
    Fact *voltageFr()      { return &_voltageFrFact; }
    Fact *voltageRl()      { return &_voltageRlFact; }
    Fact *voltageRr()      { return &_voltageRrFact; }
    Fact *currentFl()      { return &_currentFlFact; }
    Fact *currentFr()      { return &_currentFrFact; }
    Fact *currentRl()      { return &_currentRlFact; }
    Fact *currentRr()      { return &_currentRrFact; }
    Fact *temperatureFl()  { return &_temperatureFlFact; }
    Fact *temperatureFr()  { return &_temperatureFrFact; }
    Fact *temperatureRl()  { return &_temperatureRlFact; }
    Fact *temperatureRr()  { return &_temperatureRrFact; }

    void handleMessage(Vehicle *vehicle, const mavlink_message_t &message) final;

private:
    Fact _realtimeTickFlFact = Fact(0, QStringLiteral("realtimeTickFl"), FactMetaData::valueTypeUint16);
    Fact _realtimeTickFrFact = Fact(0, QStringLiteral("realtimeTickFr"), FactMetaData::valueTypeUint16);
    Fact _realtimeTickRlFact = Fact(0, QStringLiteral("realtimeTickRl"), FactMetaData::valueTypeUint16);
    Fact _realtimeTickRrFact = Fact(0, QStringLiteral("realtimeTickRr"), FactMetaData::valueTypeUint16);
    Fact _errorStatusFlFact  = Fact(0, QStringLiteral("errorStatusFl"),  FactMetaData::valueTypeUint8);
    Fact _errorStatusFrFact  = Fact(0, QStringLiteral("errorStatusFr"),  FactMetaData::valueTypeUint8);
    Fact _errorStatusRlFact  = Fact(0, QStringLiteral("errorStatusRl"),  FactMetaData::valueTypeUint8);
    Fact _errorStatusRrFact  = Fact(0, QStringLiteral("errorStatusRr"),  FactMetaData::valueTypeUint8);
    Fact _angleFlFact        = Fact(0, QStringLiteral("angleFl"),        FactMetaData::valueTypeFloat);
    Fact _angleFrFact        = Fact(0, QStringLiteral("angleFr"),        FactMetaData::valueTypeFloat);
    Fact _angleRlFact        = Fact(0, QStringLiteral("angleRl"),        FactMetaData::valueTypeFloat);
    Fact _angleRrFact        = Fact(0, QStringLiteral("angleRr"),        FactMetaData::valueTypeFloat);
    Fact _angularVelFlFact   = Fact(0, QStringLiteral("angularVelFl"),   FactMetaData::valueTypeFloat);
    Fact _angularVelFrFact   = Fact(0, QStringLiteral("angularVelFr"),   FactMetaData::valueTypeFloat);
    Fact _angularVelRlFact   = Fact(0, QStringLiteral("angularVelRl"),   FactMetaData::valueTypeFloat);
    Fact _angularVelRrFact   = Fact(0, QStringLiteral("angularVelRr"),   FactMetaData::valueTypeFloat);
    Fact _voltageFlFact      = Fact(0, QStringLiteral("voltageFl"),      FactMetaData::valueTypeFloat);
    Fact _voltageFrFact      = Fact(0, QStringLiteral("voltageFr"),      FactMetaData::valueTypeFloat);
    Fact _voltageRlFact      = Fact(0, QStringLiteral("voltageRl"),      FactMetaData::valueTypeFloat);
    Fact _voltageRrFact      = Fact(0, QStringLiteral("voltageRr"),      FactMetaData::valueTypeFloat);
    Fact _currentFlFact      = Fact(0, QStringLiteral("currentFl"),      FactMetaData::valueTypeInt32);
    Fact _currentFrFact      = Fact(0, QStringLiteral("currentFr"),      FactMetaData::valueTypeInt32);
    Fact _currentRlFact      = Fact(0, QStringLiteral("currentRl"),      FactMetaData::valueTypeInt32);
    Fact _currentRrFact      = Fact(0, QStringLiteral("currentRr"),      FactMetaData::valueTypeInt32);
    Fact _temperatureFlFact  = Fact(0, QStringLiteral("temperatureFl"),  FactMetaData::valueTypeFloat);
    Fact _temperatureFrFact  = Fact(0, QStringLiteral("temperatureFr"),  FactMetaData::valueTypeFloat);
    Fact _temperatureRlFact  = Fact(0, QStringLiteral("temperatureRl"),  FactMetaData::valueTypeFloat);
    Fact _temperatureRrFact  = Fact(0, QStringLiteral("temperatureRr"),  FactMetaData::valueTypeFloat);
};
