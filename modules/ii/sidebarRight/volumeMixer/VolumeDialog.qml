pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell

DialogSheet {
    id: root
    property bool isSink: true
    title: root.isSink ? Translation.tr("Audio output") : Translation.tr("Audio input")

    leadingActions: DialogButton {
        buttonText: Translation.tr("Details")
        onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Config.options.apps.volumeMixer}`]);
            GlobalStates.sidebarRightOpen = false;
        }
    }

    VolumeDialogContent {
        isSink: root.isSink
    }
}
