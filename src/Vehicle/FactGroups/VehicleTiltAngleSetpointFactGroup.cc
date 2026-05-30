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

#include <cmath>

namespace {
// Firmware fills in a large dummy value (~1e8+) when a real reading is unavailable.
// Map those (and any non-finite input) to NaN so float Facts render as QGC's standard
// "--.--" instead of a huge number that stretches the FlyView overlay over the map.
constexpr float kAirbilityInvalidThreshold = 1.0e8f;
inline float sanitizeF(float v)
{
    return (std::isfinite(v) && (std::fabs(v) < kAirbilityInvalidThreshold)) ? v : qQNaN();
}
}

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

    _tiltFlFact.setRawValue(sanitizeF(setpoint.tilt_fl));
    _tiltFrFact.setRawValue(sanitizeF(setpoint.tilt_fr));
    _tiltRlFact.setRawValue(sanitizeF(setpoint.tilt_rl));
    _tiltRrFact.setRawValue(sanitizeF(setpoint.tilt_rr));

    _setTelemetryAvailable(true);
}
