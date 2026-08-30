import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Keep awake")
    statusText: Idle.inhibitStatusText

    toggled: Idle.inhibit
    icon: "coffee"
    mainAction: () => {
        Idle.toggleInhibit()
    }
    hasMenu: true
    tooltipText: Translation.tr("Keep system awake | Right-click to configure")
}
