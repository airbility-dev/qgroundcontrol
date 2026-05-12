/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VehicleTiltAngleSetpointFactGroup.h"
#include "Vehicle.h"

VehicleTiltAngleSetpointFactGroup::VehicleTiltAngleSetpointFactGroup(QObject *parent)
    : FactGroup(1000, QStringLiteral(":/json/Vehicle/TiltAngleSetpointFact.json"), parent)
{
    _addFact(&_tiltFlFact);
    _addFact(&_tiltFrFact);
    _addFact(&_tiltRlFact);
    _addFact(&_tiltRrFact);

    _tiltFlFact.setRawValue(qQNaN());
    _tiltFrFact.setRawValue(qQNaN());
    _tiltRlFact.setRawValue(qQNaN());
    _tiltRrFact.setRawValue(qQNaN());
}

void VehicleTiltAngleSetpointFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t &message)
{
    Q_UNUSED(vehicle);

    if (message.msgid != MAVLINK_MSG_ID_TILT_ANGLE_SETPOINT) {
        return;
    }

    mavlink_tilt_angle_setpoint_t setpoint{};
    mavlink_msg_tilt_angle_setpoint_decode(&message, &setpoint);

    _tiltFlFact.setRawValue(setpoint.tilt_fl);
    _tiltFrFact.setRawValue(setpoint.tilt_fr);
    _tiltRlFact.setRawValue(setpoint.tilt_rl);
    _tiltRrFact.setRawValue(setpoint.tilt_rr);

    _setTelemetryAvailable(true);
}
