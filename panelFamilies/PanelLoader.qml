import QtQuick
import Quickshell

import qs.modules.common

/**
 * Loads a top-level panel once the config can be read.
 *
 * Panels that put a surface on screen right after startup set `immediate: true`
 * so they are built on the UI thread and show up in the first frames. Every
 * other panel is incubated in the background during spare frame time, so a
 * couple dozen panel trees no longer block the first paint.
 */
LazyLoader {
    id: root

    property bool extraCondition: true
    property bool immediate: false

    readonly property bool shouldLoad: Config.ready && root.extraCondition

    function applyLoadState() {
        if (root.immediate)
            root.active = root.shouldLoad;
        else
            root.activeAsync = root.shouldLoad;
    }

    onShouldLoadChanged: root.applyLoadState()
    Component.onCompleted: root.applyLoadState()
}
