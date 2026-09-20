import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        shape: MaterialShape.Shape.Cookie6Sided
        icon: "shield_lock"
        title: Translation.tr("Privacy indicator")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("The indicator only appears while one of these is in use. Add it to the bar from the layout page.")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSurfaceVariant
            opacity: 0.7
            wrapMode: Text.WordWrap
        }

        GroupedList {
            ConfigSwitch {
                buttonIcon: "videocam"; text: Translation.tr("Camera access")
                checked: Config.options.bar.privacy.showCamera
                onCheckedChanged: { Config.options.bar.privacy.showCamera = checked; }
            }
            ConfigSwitch {
                buttonIcon: "mic"; text: Translation.tr("Microphone access")
                checked: Config.options.bar.privacy.showMicrophone
                onCheckedChanged: { Config.options.bar.privacy.showMicrophone = checked; }
            }
            ConfigSwitch {
                buttonIcon: "screen_share"; text: Translation.tr("Screen sharing")
                checked: Config.options.bar.privacy.showScreenShare
                onCheckedChanged: { Config.options.bar.privacy.showScreenShare = checked; }
            }
        }
    }
}
