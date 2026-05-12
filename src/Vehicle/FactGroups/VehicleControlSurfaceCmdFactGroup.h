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

class VehicleControlSurfaceCmdFactGroup : public FactGroup
{
    Q_OBJECT
    Q_PROPERTY(Fact *leftAileron      READ leftAileron      CONSTANT)
    Q_PROPERTY(Fact *rightAileron     READ rightAileron     CONSTANT)
    Q_PROPERTY(Fact *leftRuddervator  READ leftRuddervator  CONSTANT)
    Q_PROPERTY(Fact *rightRuddervator READ rightRuddervator CONSTANT)

public:
    explicit VehicleControlSurfaceCmdFactGroup(QObject *parent = nullptr);

    Fact *leftAileron()      { return &_leftAileronFact; }
    Fact *rightAileron()     { return &_rightAileronFact; }
    Fact *leftRuddervator()  { return &_leftRuddervatorFact; }
    Fact *rightRuddervator() { return &_rightRuddervatorFact; }

    void handleMessage(Vehicle *vehicle, const mavlink_message_t &message) final;

private:
    Fact _leftAileronFact      = Fact(0, QStringLiteral("leftAileron"),      FactMetaData::valueTypeFloat);
    Fact _rightAileronFact     = Fact(0, QStringLiteral("rightAileron"),     FactMetaData::valueTypeFloat);
    Fact _leftRuddervatorFact  = Fact(0, QStringLiteral("leftRuddervator"),  FactMetaData::valueTypeFloat);
    Fact _rightRuddervatorFact = Fact(0, QStringLiteral("rightRuddervator"), FactMetaData::valueTypeFloat);
};
