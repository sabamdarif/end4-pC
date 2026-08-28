import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.ii.background
import qs.modules.ii.bar
import qs.modules.ii.dock
import qs.modules.ii.screenCorners
import qs.modules.ii.verticalBar

Scope {
    // Panels with a surface on screen from the moment the shell starts.
    PanelLoader { extraCondition: !Config.options.bar.vertical; immediate: true; component: Bar {} }
    PanelLoader { extraCondition: Config.options.bar.vertical; immediate: true; component: VerticalBar {} }
    PanelLoader { component: Background {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { extraCondition: Config.options.dock.enable; immediate: true; component: Dock {} }

    // Everything else lives in DeferredPanels.qml. Referencing those types here
    // would compile their whole type tree before this document could finish
    // loading, which is roughly half a second of work ahead of the first frame.
    // Naming the document by path hands that work to the QML worker thread.
    LazyLoader {
        id: deferredPanels

        Component.onCompleted: {
            const component = Qt.createComponent("DeferredPanels.qml", Component.Asynchronous, deferredPanels);
            const activate = () => {
                if (component.status === Component.Error) {
                    console.error(`[IllogicalImpulseFamily] Could not load DeferredPanels.qml: ${component.errorString()}`);
                    return;
                }
                deferredPanels.component = component;
                deferredPanels.activeAsync = true;
            };
            if (component.status === Component.Loading)
                component.statusChanged.connect(activate);
            else
                activate();
        }
    }
}
