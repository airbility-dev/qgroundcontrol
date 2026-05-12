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

class VehicleTiltAngleSetpointFactGroup : public FactGroup
{
    Q_OBJECT
    Q_PROPERTY(Fact *tiltFl READ tiltFl CONSTANT)
    Q_PROPERTY(Fact *tiltFr READ tiltFr CONSTANT)
    Q_PROPERTY(Fact *tiltRl READ tiltRl CONSTANT)
    Q_PROPERTY(Fact *tiltRr READ tiltRr CONSTANT)

public:
    explicit VehicleTiltAngleSetpointFactGroup(QObject *parent = nullptr);

    Fact *tiltFl() { return &_tiltFlFact; }
    Fact *tiltFr() { return &_tiltFrFact; }
    Fact *tiltRl() { return &_tiltRlFact; }
    Fact *tiltRr() { return &_tiltRrFact; }

    void handleMessage(Vehicle *vehicle, const mavlink_message_t &message) final;

private:
    Fact _tiltFlFact = Fact(0, QStringLiteral("tiltFl"), FactMetaData::valueTypeFloat);
    Fact _tiltFrFact = Fact(0, QStringLiteral("tiltFr"), FactMetaData::valueTypeFloat);
    Fact _tiltRlFact = Fact(0, QStringLiteral("tiltRl"), FactMetaData::valueTypeFloat);
    Fact _tiltRrFact = Fact(0, QStringLiteral("tiltRr"), FactMetaData::valueTypeFloat);
};
