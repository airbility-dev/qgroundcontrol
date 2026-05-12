/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VehicleControlSurfaceCmdFactGroup.h"
#include "Vehicle.h"

VehicleControlSurfaceCmdFactGroup::VehicleControlSurfaceCmdFactGroup(QObject *parent)
    : FactGroup(1000, QStringLiteral(":/json/Vehicle/ControlSurfaceCmdFact.json"), parent)
{
    _addFact(&_leftAileronFact);
    _addFact(&_rightAileronFact);
    _addFact(&_leftRuddervatorFact);
    _addFact(&_rightRuddervatorFact);

    _leftAileronFact.setRawValue(qQNaN());
    _rightAileronFact.setRawValue(qQNaN());
    _leftRuddervatorFact.setRawValue(qQNaN());
    _rightRuddervatorFact.setRawValue(qQNaN());
}

void VehicleControlSurfaceCmdFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t &message)
{
    Q_UNUSED(vehicle);

    if (message.msgid != MAVLINK_MSG_ID_CONTROL_SURFACE_CMD) {
        return;
    }

    mavlink_control_surface_cmd_t cmd{};
    mavlink_msg_control_surface_cmd_decode(&message, &cmd);

    _leftAileronFact.setRawValue(cmd.left_aileron);
    _rightAileronFact.setRawValue(cmd.right_aileron);
    _leftRuddervatorFact.setRawValue(cmd.left_ruddervator);
    _rightRuddervatorFact.setRawValue(cmd.right_ruddervator);

    _setTelemetryAvailable(true);
}
