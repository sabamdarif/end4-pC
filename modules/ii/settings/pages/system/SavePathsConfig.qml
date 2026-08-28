import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true
    bottomContentPadding: 15

    ContentSection {
        icon: "file_open"
        shape: MaterialShape.Shape.Slanted
        title: Translation.tr("Save paths")

        GroupedList {
            ConfigTextArea {
                id: videoRecordPathField
                Layout.fillWidth: true
                fieldWidth: 250
                buttonIcon: "video_file"
                text: Translation.tr("Video Recording Path")
                value: Config.options.screenRecord.savePath
                onValueChanged: {
                    videoRecordPathDebounceTimer.restart();
                }

                Timer {
                    id: videoRecordPathDebounceTimer
                    interval: 600
                    repeat: false
                    onTriggered: {
                        Config.options.screenRecord.savePath = videoRecordPathField.value;
                    }
                }
            }

            ConfigTextArea {
                id: screenshotPathField
                Layout.fillWidth: true
                fieldWidth: 250
                buttonIcon: "screenshot_monitor"
                text: Translation.tr("Screenshot Path (leave empty to just copy)")
                value: Config.options.screenSnip.savePath
                onValueChanged: {
                    screenshotPathDebounceTimer.restart();
                }

                Timer {
                    id: screenshotPathDebounceTimer
                    interval: 600
                    repeat: false
                    onTriggered: {
                        Config.options.screenSnip.savePath = screenshotPathField.value;
                    }
                }
            }
        }
    }
}
