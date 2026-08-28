import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "panorama"
        shape: MaterialShape.Shape.SoftBoom 
        title: Translation.tr("Custom Image")
        GroupedList {
            ConfigSwitch {
                Layout.fillWidth: true
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.customImage.enable
                onCheckedChanged: {
                    Config.options.background.widgets.customImage.enable = checked;
                }
            }
            ConfigSelectionShapeArray {
                currentValue: Config.options.background.widgets.customImage.shape
                shapeColor: Appearance.colors.colPrimary
                backgroundColor: Appearance.colors.colPrimaryContainer
                options: [
                    "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
                    "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
                    "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
                    "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
                    "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
                ]
                onSelected: newValue => {
                    Config.options.background.widgets.customImage.shape = newValue
                }
            }
        }
    }
}
