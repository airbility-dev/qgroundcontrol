/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VehicleTiltStatusFactGroup.h"
#include "Vehicle.h"

#include <cmath>

namespace {
// Firmware fills in a large dummy value (~1e8+) when a real reading is unavailable.
// Map those (and any non-finite input) to NaN so float Facts render as QGC's standard
// "--.--" instead of a huge number that stretches the FlyView overlay over the map.
// Same sentinel->qQNaN() convention used by VehicleGPSFactGroup / VehicleGeneratorFactGroup.
constexpr float kAirbilityInvalidThreshold = 1.0e8f;
inline float sanitizeF(float v)
{
    return (std::isfinite(v) && (std::fabs(v) < kAirbilityInvalidThreshold)) ? v : qQNaN();
}
}

VehicleTiltStatusFactGroup::VehicleTiltStatusFactGroup(QObject *parent)
    : FactGroup(1000, QStringLiteral(":/json/Vehicle/TiltStatusFact.json"), parent)
{
    _addFact(&_realtimeTickFlFact);
    _addFact(&_realtimeTickFrFact);
    _addFact(&_realtimeTickRlFact);
    _addFact(&_realtimeTickRrFact);
    _addFact(&_errorStatusFlFact);
    _addFact(&_errorStatusFrFact);
    _addFact(&_errorStatusRlFact);
    _addFact(&_errorStatusRrFact);
    _addFact(&_angleFlFact);
    _addFact(&_angleFrFact);
    _addFact(&_angleRlFact);
    _addFact(&_angleRrFact);
    _addFact(&_angularVelFlFact);
    _addFact(&_angularVelFrFact);
    _addFact(&_angularVelRlFact);
    _addFact(&_angularVelRrFact);
    _addFact(&_voltageFlFact);
    _addFact(&_voltageFrFact);
    _addFact(&_voltageRlFact);
    _addFact(&_voltageRrFact);
    _addFact(&_currentFlFact);
    _addFact(&_currentFrFact);
    _addFact(&_currentRlFact);
    _addFact(&_currentRrFact);
    _addFact(&_temperatureFlFact);
    _addFact(&_temperatureFrFact);
    _addFact(&_temperatureRlFact);
    _addFact(&_temperatureRrFact);

    _angleFlFact.setRawValue(qQNaN());
    _angleFrFact.setRawValue(qQNaN());
    _angleRlFact.setRawValue(qQNaN());
    _angleRrFact.setRawValue(qQNaN());
    _angularVelFlFact.setRawValue(qQNaN());
    _angularVelFrFact.setRawValue(qQNaN());
    _angularVelRlFact.setRawValue(qQNaN());
    _angularVelRrFact.setRawValue(qQNaN());
    _voltageFlFact.setRawValue(qQNaN());
    _voltageFrFact.setRawValue(qQNaN());
    _voltageRlFact.setRawValue(qQNaN());
    _voltageRrFact.setRawValue(qQNaN());
    _temperatureFlFact.setRawValue(qQNaN());
    _temperatureFrFact.setRawValue(qQNaN());
    _temperatureRlFact.setRawValue(qQNaN());
    _temperatureRrFact.setRawValue(qQNaN());
}

void VehicleTiltStatusFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t &message)
{
    Q_UNUSED(vehicle);

    if (message.msgid != MAVLINK_MSG_ID_TILT_STATUS) {
        return;
    }

    mavlink_tilt_status_t status{};
    mavlink_msg_tilt_status_decode(&message, &status);

    // Index convention: 0=FL, 1=FR, 2=RL, 3=RR
    _realtimeTickFlFact.setRawValue(status.realtime_tick[0]);
    _realtimeTickFrFact.setRawValue(status.realtime_tick[1]);
    _realtimeTickRlFact.setRawValue(status.realtime_tick[2]);
    _realtimeTickRrFact.setRawValue(status.realtime_tick[3]);

    _errorStatusFlFact.setRawValue(status.error_status[0]);
    _errorStatusFrFact.setRawValue(status.error_status[1]);
    _errorStatusRlFact.setRawValue(status.error_status[2]);
    _errorStatusRrFact.setRawValue(status.error_status[3]);

    _angleFlFact.setRawValue(sanitizeF(status.angle[0]));
    _angleFrFact.setRawValue(sanitizeF(status.angle[1]));
    _angleRlFact.setRawValue(sanitizeF(status.angle[2]));
    _angleRrFact.setRawValue(sanitizeF(status.angle[3]));

    _angularVelFlFact.setRawValue(sanitizeF(status.angular_vel[0]));
    _angularVelFrFact.setRawValue(sanitizeF(status.angular_vel[1]));
    _angularVelRlFact.setRawValue(sanitizeF(status.angular_vel[2]));
    _angularVelRrFact.setRawValue(sanitizeF(status.angular_vel[3]));

    _voltageFlFact.setRawValue(sanitizeF(status.voltage[0]));
    _voltageFrFact.setRawValue(sanitizeF(status.voltage[1]));
    _voltageRlFact.setRawValue(sanitizeF(status.voltage[2]));
    _voltageRrFact.setRawValue(sanitizeF(status.voltage[3]));

    // current[] is int32 (mA) and is not shown on the overlay, so it is left as-is.
    _currentFlFact.setRawValue(status.current[0]);
    _currentFrFact.setRawValue(status.current[1]);
    _currentRlFact.setRawValue(status.current[2]);
    _currentRrFact.setRawValue(status.current[3]);

    _temperatureFlFact.setRawValue(sanitizeF(status.temperature[0]));
    _temperatureFrFact.setRawValue(sanitizeF(status.temperature[1]));
    _temperatureRlFact.setRawValue(sanitizeF(status.temperature[2]));
    _temperatureRrFact.setRawValue(sanitizeF(status.temperature[3]));

    _setTelemetryAvailable(true);
}
