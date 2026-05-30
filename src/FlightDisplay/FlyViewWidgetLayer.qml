/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models
import QtCore

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

// This is the ui overlay layer for the widgets/tools for Fly View
Item {
    id: _root

    property var    parentToolInsets
    property var    totalToolInsets:        _totalToolInsets
    property var    mapControl
    property bool   isViewer3DOpen:         false

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property alias  _gripperMenu:           gripperOptions
    property real   _layoutMargin:          ScreenTools.defaultFontPixelWidth * 0.75
    property bool   _layoutSpacing:         ScreenTools.defaultFontPixelWidth
    property bool   _showSingleVehicleUI:   true
    property bool   _tiltOverlayVisible:    true

    property bool utmspActTrigger

    Shortcut {
        sequence:   "Ctrl+Shift+T"
        context:    Qt.ApplicationShortcut
        onActivated: _root._tiltOverlayVisible = !_root._tiltOverlayVisible
    }

    //-- Value cell for the Airbility debug overlay. Caps width + elides so a stray long
    //   value (e.g. an unsanitized sentinel) can never stretch the panel over the map.
    component TiltValue: QGCLabel {
        Layout.fillWidth:    true
        Layout.maximumWidth: ScreenTools.defaultFontPixelWidth * 8
        horizontalAlignment: Text.AlignRight
        elide:               Text.ElideRight
        color:               "white"
    }

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       toolStrip.leftEdgeTopInset
        leftEdgeCenterInset:    toolStrip.leftEdgeCenterInset
        leftEdgeBottomInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      topRightPanel.rightEdgeTopInset
        rightEdgeCenterInset:   topRightPanel.rightEdgeCenterInset
        rightEdgeBottomInset:   bottomRightRowLayout.rightEdgeBottomInset
        topEdgeLeftInset:       toolStrip.topEdgeLeftInset
        topEdgeCenterInset:     mapScale.topEdgeCenterInset
        topEdgeRightInset:      topRightPanel.topEdgeRightInset
        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  bottomRightRowLayout.bottomEdgeCenterInset
        bottomEdgeRightInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : bottomRightRowLayout.bottomEdgeRightInset
    }

    FlyViewTopRightPanel {
        id:                     topRightPanel
        anchors.top:            parent.top
        anchors.right:          parent.right
        anchors.topMargin:      _layoutMargin
        anchors.rightMargin:    _layoutMargin
        maximumHeight:          parent.height - (bottomRightRowLayout.height + _margins * 5)

        property real topEdgeRightInset:    height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewTopRightColumnLayout {
        id:                 topRightColumnLayout
        anchors.margins:    _layoutMargin
        anchors.top:        parent.top
        anchors.bottom:     bottomRightRowLayout.top
        anchors.right:      parent.right
        spacing:            _layoutSpacing
        visible:           !topRightPanel.visible

        property real topEdgeRightInset:    childrenRect.height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewBottomRightRowLayout {
        id:                 bottomRightRowLayout
        anchors.margins:    _layoutMargin
        anchors.bottom:     parent.bottom
        anchors.right:      parent.right
        spacing:            _layoutSpacing

        property real bottomEdgeRightInset:     height + _layoutMargin
        property real bottomEdgeCenterInset:    bottomEdgeRightInset
        property real rightEdgeBottomInset:     width + _layoutMargin
    }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    GuidedActionConfirm {
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
        guidedValueSlider:          _guidedValueSlider
        utmspSliderTrigger:         utmspActTrigger
    }

    //-- Virtual Joystick
    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        anchors.right:              parent.right
        anchors.rightMargin:        anchors.leftMargin
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       bottomLoaderMargin
        anchors.left:               parent.left   
        anchors.leftMargin:         ( y > toolStrip.y + toolStrip.height ? toolStrip.width / 2 : toolStrip.width * 1.05 + toolStrip.x) 
        source:                     "qrc:/qml/QGroundControl/FlightDisplay/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property real bottomEdgeLeftInset:     parent.height-y
        property bool autoCenterThrottle:      QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
        property bool leftHandedMode:          QGroundControl.settingsManager.appSettings.virtualJoystickLeftHandedMode.rawValue
        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
        property real bottomEdgeRightInset:    parent.height-y
        property var  _pipViewMargin:          _pipView.visible ? parentToolInsets.bottomEdgeLeftInset + ScreenTools.defaultFontPixelHeight * 2 : 
                                               bottomRightRowLayout.height + ScreenTools.defaultFontPixelHeight * 1.5

        property var  bottomLoaderMargin:      _pipViewMargin >= parent.height / 2 ? parent.height / 2 : _pipViewMargin

        // Width is difficult to access directly hence this hack which may not work in all circumstances
        property real leftEdgeBottomInset:  visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rootWidth:            _root.width
        property var  itemX:                virtualJoystickMultiTouch.x   // real X on screen

        onRootWidthChanged: virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth : undefined
        onItemXChanged:     virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiRealX = itemX : undefined

        //Loader status logic
        onLoaded: {
            if (virtualJoystickMultiTouch.visible) {
                virtualJoystickMultiTouch.item.calibration = true 
                virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth
                virtualJoystickMultiTouch.item.uiRealX = itemX
            } else {
                virtualJoystickMultiTouch.item.calibration = false
            }
        }
    }

    FlyViewToolStrip {
        id:                     toolStrip
        anchors.leftMargin:     _toolsMargin + parentToolInsets.leftEdgeCenterInset
        anchors.topMargin:      _toolsMargin + parentToolInsets.topEdgeLeftInset
        anchors.left:           parent.left
        anchors.top:            parent.top
        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
        visible:                !QGroundControl.videoManager.fullScreen

        onDisplayPreFlightChecklist: {
            if (!preFlightChecklistLoader.active) {
                preFlightChecklistLoader.active = true
            }
            preFlightChecklistLoader.item.open()
        }

        property real topEdgeLeftInset:     visible ? y + height : 0
        property real leftEdgeTopInset:     visible ? x + width : 0
        property real leftEdgeCenterInset:  leftEdgeTopInset
    }

    GripperMenu {
        id: gripperOptions
    }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.left:       toolStrip.right
        anchors.top:        parent.top
        mapControl:         _mapControl
        buttonsOnLeft:      true
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && !isViewer3DOpen && mapControl.pipState.state === mapControl.pipState.fullState

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    //-- Airbility Tilt / Control Surface debug overlay (collapsible header, draggable)
    Rectangle {
        id:                     tiltOverlay
        // User-resizable: width/height track these backing properties (mutated by the
        // resize grip / restored from Settings), so the panel no longer auto-resizes
        // as value text lengths change.
        property real _panelWidth:  ScreenTools.defaultFontPixelWidth  * 42
        property real _panelHeight: ScreenTools.defaultFontPixelHeight * 26
        readonly property real _minWidth:  ScreenTools.defaultFontPixelWidth  * 20
        readonly property real _minHeight: ScreenTools.defaultFontPixelHeight * 7
        readonly property real _headerH:   tiltOverlayHeader.implicitHeight + ScreenTools.defaultFontPixelHeight

        width:                  _panelWidth
        height:                 _root._tiltOverlayVisible ? _panelHeight : _headerH
        clip:                   true
        color:                  "#A0000000"
        radius:                 ScreenTools.defaultFontPixelWidth / 2
        visible:                _activeVehicle
        z:                      QGroundControl.zOrderWidgets

        property var _ts:  _activeVehicle ? _activeVehicle.tiltStatus        : null
        property var _tsp: _activeVehicle ? _activeVehicle.tiltAngleSetpoint : null
        property var _csc: _activeVehicle ? _activeVehicle.controlSurfaceCmd : null
        property var _ls:  _activeVehicle ? _activeVehicle.linkStats         : null

        //-- Persist size + position across restarts (debounced).
        Settings {
            id:         tiltOverlaySettings
            category:   "AirbilityTiltOverlay"
            property real savedX: -1
            property real savedY: -1
            property real savedW: -1
            property real savedH: -1
        }

        Timer {
            id:         saveOverlayTimer
            interval:   500
            repeat:     false
            onTriggered: {
                tiltOverlaySettings.savedX = tiltOverlay.x
                tiltOverlaySettings.savedY = tiltOverlay.y
                tiltOverlaySettings.savedW = tiltOverlay._panelWidth
                tiltOverlaySettings.savedH = tiltOverlay._panelHeight
            }
        }

        onXChanged: saveOverlayTimer.restart()
        onYChanged: saveOverlayTimer.restart()

        Component.onCompleted: {
            if (tiltOverlaySettings.savedW > 0 && tiltOverlaySettings.savedH > 0) {
                _panelWidth  = Math.max(_minWidth,  Math.min(tiltOverlaySettings.savedW, parent.width))
                _panelHeight = Math.max(_minHeight, Math.min(tiltOverlaySettings.savedH, parent.height))
                x = Math.max(0, Math.min(tiltOverlaySettings.savedX, parent.width  - _panelWidth))
                y = Math.max(0, Math.min(tiltOverlaySettings.savedY, parent.height - _panelHeight))
            } else {
                // First run: size to content height (rows are always present, so this is stable).
                _panelHeight = tiltOverlayContent.implicitHeight + _headerH + ScreenTools.defaultFontPixelHeight * 2
                x = toolStrip.x + toolStrip.width + _toolsMargin * 2
                y = Math.max(_toolsMargin, (parent.height - height) / 2)
            }
        }

        ColumnLayout {
            id:                 tiltOverlayColumn
            anchors.fill:       parent
            anchors.margins:    ScreenTools.defaultFontPixelWidth
            spacing:            ScreenTools.defaultFontPixelHeight / 4

            //-- Header: drag to move, click to expand/collapse
            Item {
                id:                     tiltOverlayHeader
                Layout.fillWidth:       true
                Layout.preferredHeight: tiltOverlayHeaderRow.implicitHeight
                Layout.preferredWidth:  tiltOverlayHeaderRow.implicitWidth

                MouseArea {
                    anchors.fill:   parent
                    drag.target:    tiltOverlay
                    drag.axis:      Drag.XAndYAxis
                    drag.minimumX:  0
                    drag.minimumY:  0
                    drag.maximumX:  tiltOverlay.parent.width  - tiltOverlay.width
                    drag.maximumY:  tiltOverlay.parent.height - tiltOverlay.height
                    cursorShape:    drag.active ? Qt.SizeAllCursor : Qt.PointingHandCursor
                    onClicked:      _root._tiltOverlayVisible = !_root._tiltOverlayVisible
                }

                RowLayout {
                    id:             tiltOverlayHeaderRow
                    anchors.left:   parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing:        ScreenTools.defaultFontPixelWidth / 2

                    QGCLabel {
                        text:       _root._tiltOverlayVisible ? "▼" : "▶"
                        color:      "#FFD700"
                        font.bold:  true
                    }
                    QGCLabel {
                        text:       qsTr("Airbility")
                        color:      "#FFD700"
                        font.bold:  true
                    }
                }
            }

            //-- Collapsible content (Tilt Status / Setpoint / Control Surface / Link Quality), scrollable
            QGCFlickable {
                id:                 tiltOverlayFlick
                Layout.fillWidth:   true
                Layout.fillHeight:  true
                visible:            _root._tiltOverlayVisible
                contentWidth:       width
                contentHeight:      tiltOverlayContent.height

                ColumnLayout {
                id:             tiltOverlayContent
                width:          tiltOverlayFlick.width
                spacing:        ScreenTools.defaultFontPixelHeight / 4

                QGCLabel { text: qsTr("Tilt Status"); color: "#FFD700"; font.bold: true }
            GridLayout {
                Layout.fillWidth: true
                columns:        5
                columnSpacing:  ScreenTools.defaultFontPixelWidth
                rowSpacing:     2

                QGCLabel { text: ""; color: "#AAAAAA" }
                QGCLabel { text: "FL"; color: "#AAAAAA"; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
                QGCLabel { text: "FR"; color: "#AAAAAA"; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
                QGCLabel { text: "RL"; color: "#AAAAAA"; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
                QGCLabel { text: "RR"; color: "#AAAAAA"; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }

                QGCLabel { text: qsTr("angle");   color: "white" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.angleFl.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.angleFr.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.angleRl.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.angleRr.valueString : "—" }

                QGCLabel { text: qsTr("ang.vel"); color: "white" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.angularVelFl.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.angularVelFr.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.angularVelRl.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.angularVelRr.valueString : "—" }

                QGCLabel { text: qsTr("voltage"); color: "white" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.voltageFl.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.voltageFr.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.voltageRl.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.voltageRr.valueString : "—" }

                QGCLabel { text: qsTr("temp");    color: "white" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.temperatureFl.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.temperatureFr.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.temperatureRl.valueString : "—" }
                TiltValue { text: tiltOverlay._ts ? tiltOverlay._ts.temperatureRr.valueString : "—" }
            }

            QGCLabel { text: qsTr("Tilt Setpoint"); color: "#FFD700"; font.bold: true }
            GridLayout {
                Layout.fillWidth: true
                columns:        5
                columnSpacing:  ScreenTools.defaultFontPixelWidth
                rowSpacing:     2

                QGCLabel { text: qsTr("angle"); color: "white" }
                TiltValue { text: tiltOverlay._tsp ? tiltOverlay._tsp.tiltFl.valueString : "—" }
                TiltValue { text: tiltOverlay._tsp ? tiltOverlay._tsp.tiltFr.valueString : "—" }
                TiltValue { text: tiltOverlay._tsp ? tiltOverlay._tsp.tiltRl.valueString : "—" }
                TiltValue { text: tiltOverlay._tsp ? tiltOverlay._tsp.tiltRr.valueString : "—" }
            }

            QGCLabel { text: qsTr("Control Surface"); color: "#FFD700"; font.bold: true }
            GridLayout {
                Layout.fillWidth: true
                columns:        2
                columnSpacing:  ScreenTools.defaultFontPixelWidth
                rowSpacing:     2

                QGCLabel { text: qsTr("L.Aileron");  color: "white" }
                TiltValue { text: tiltOverlay._csc ? tiltOverlay._csc.leftAileron.valueString : "—" }
                QGCLabel { text: qsTr("R.Aileron");  color: "white" }
                TiltValue { text: tiltOverlay._csc ? tiltOverlay._csc.rightAileron.valueString : "—" }
                QGCLabel { text: qsTr("L.Rudder");   color: "white" }
                TiltValue { text: tiltOverlay._csc ? tiltOverlay._csc.leftRuddervator.valueString : "—" }
                QGCLabel { text: qsTr("R.Rudder");   color: "white" }
                TiltValue { text: tiltOverlay._csc ? tiltOverlay._csc.rightRuddervator.valueString : "—" }
            }

            QGCLabel { text: qsTr("Link Quality"); color: "#FFD700"; font.bold: true }
            GridLayout {
                Layout.fillWidth: true
                columns:        2
                columnSpacing:  ScreenTools.defaultFontPixelWidth
                rowSpacing:     2

                QGCLabel { text: qsTr("ms since last"); color: "white" }
                TiltValue {
                    color: (tiltOverlay._ls && tiltOverlay._ls.msSinceLastPacket.rawValue > 1000) ? "#FF5050" : "white"
                    text:  tiltOverlay._ls ? tiltOverlay._ls.msSinceLastPacket.valueString : "—"
                }
                QGCLabel { text: qsTr("valid rate");    color: "white" }
                TiltValue { text: tiltOverlay._ls ? tiltOverlay._ls.receiveRate.valueString : "—" }
                QGCLabel { text: qsTr("msg rate");      color: "white" }
                TiltValue { text: tiltOverlay._ls ? tiltOverlay._ls.messageRate.valueString : "—" }
                QGCLabel { text: qsTr("loss %");        color: "white" }
                TiltValue {
                    color: (tiltOverlay._ls && tiltOverlay._ls.lossPercent.rawValue > 5) ? "#FF5050" : "white"
                    text:  tiltOverlay._ls ? tiltOverlay._ls.lossPercent.valueString : "—"
                }
                QGCLabel { text: qsTr("loss/s");        color: "white" }
                TiltValue {
                    color: (tiltOverlay._ls && tiltOverlay._ls.lossPerSec.rawValue > 0) ? "#FF5050" : "white"
                    text:  tiltOverlay._ls ? tiltOverlay._ls.lossPerSec.valueString : "—"
                }
                QGCLabel { text: qsTr("crc fail/s");    color: "white" }
                TiltValue {
                    color: (tiltOverlay._ls && tiltOverlay._ls.crcDropPerSec.rawValue > 0) ? "#FF5050" : "white"
                    text:  tiltOverlay._ls ? tiltOverlay._ls.crcDropPerSec.valueString : "—"
                }
            }
            }
            }
        }

        //-- Bottom-right resize grip (drag to resize width + height)
        Rectangle {
            id:             resizeGrip
            width:          ScreenTools.defaultFontPixelHeight
            height:         ScreenTools.defaultFontPixelHeight
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            color:          "transparent"
            visible:        _root._tiltOverlayVisible
            z:              10

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = "#C0FFFFFF"
                    ctx.lineWidth   = 1
                    var mn = Math.min(width, height)
                    for (var i = 1; i <= 3; ++i) {
                        var d = i * (mn / 4)
                        ctx.beginPath()
                        ctx.moveTo(width - d, height)
                        ctx.lineTo(width, height - d)
                        ctx.stroke()
                    }
                }
            }

            MouseArea {
                anchors.fill:    parent
                cursorShape:     Qt.SizeFDiagCursor
                preventStealing: true
                property real startX: 0
                property real startY: 0
                property real startW: 0
                property real startH: 0
                onPressed: (mouse) => {
                    startX = mouse.x
                    startY = mouse.y
                    startW = tiltOverlay._panelWidth
                    startH = tiltOverlay._panelHeight
                }
                onPositionChanged: (mouse) => {
                    if (!pressed) {
                        return
                    }
                    var maxW = tiltOverlay.parent.width  - tiltOverlay.x
                    var maxH = tiltOverlay.parent.height - tiltOverlay.y
                    tiltOverlay._panelWidth  = Math.max(tiltOverlay._minWidth,  Math.min(startW + (mouse.x - startX), maxW))
                    tiltOverlay._panelHeight = Math.max(tiltOverlay._minHeight, Math.min(startH + (mouse.y - startY), maxH))
                    saveOverlayTimer.restart()
                }
            }
        }
    }

    Loader {
        id: preFlightChecklistLoader
        sourceComponent: preFlightChecklistPopup
        active: false
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }
}
