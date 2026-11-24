import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class SettingsControlTests(unittest.TestCase):
    def test_switch_clicks_preserve_external_binding(self):
        with tempfile.TemporaryDirectory(prefix="config-switch-", dir=os.environ.get("TMPDIR")) as directory:
            root = Path(directory)
            common = root / "modules/common"
            widgets = common / "widgets"
            widgets.mkdir(parents=True)
            shutil.copy(REPOSITORY / "modules/common/widgets/ConfigSwitch.qml", widgets)
            (common / "Appearance.qml").write_text('''pragma Singleton
import Quickshell
Singleton {
    property var font: ({ pixelSize: { small: 14, smaller: 12, larger: 18 } })
    property var colors: ({ colOnSecondaryContainer: "white", colSubtext: "gray" })
}
''')
            for name, contents in {
                "RippleButton.qml": 'import QtQuick\nimport QtQuick.Controls\nButton { property color colBackgroundHover }',
                "StyledSwitch.qml": 'import QtQuick.Controls\nSwitch {}',
                "StyledText.qml": 'import QtQuick\nText {}',
                "OptionalMaterialSymbol.qml": 'import QtQuick\nItem { property string icon; property real iconSize }',
            }.items():
                (widgets / name).write_text(contents)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "modules/common/widgets"
ShellRoot {
    id: root
    property bool externalState: false
    function check(condition, message) {
        if (!condition) console.error("ASSERTION_FAILED", message);
    }
    ConfigSwitch {
        id: control
        checked: root.externalState
        onCheckedChanged: root.externalState = checked
    }
    Timer {
        interval: 100
        running: true
        onTriggered: {
            control.click();
            check(root.externalState && control.checked, "row click toggles state");
            root.externalState = false;
            check(!control.checked, "external changes still update the row");
            const thumb = control.contentItem.children[2];
            thumb.click();
            check(control.checked && thumb.checked, "thumb click toggles once");
            root.externalState = false;
            check(!control.checked && !thumb.checked, "thumb binding survives click");
            console.log("SWITCH_TEST_DONE");
            Qt.quit();
        }
    }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True,
                                    timeout=8, env=dict(os.environ, QT_QPA_PLATFORM="offscreen",
                                                       QT_QUICK_CONTROLS_STYLE="Basic"))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("SWITCH_TEST_DONE", output)
            self.assertNotIn("ASSERTION_FAILED", output)
            self.assertNotIn("TypeError", output)

    def test_scaled_and_rotated_monitor_geometry(self):
        with tempfile.TemporaryDirectory(prefix="monitor-geometry-", dir=os.environ.get("TMPDIR")) as directory:
            root = Path(directory)
            models = root / "modules/common/models"
            models.mkdir(parents=True)
            services = root / "services"
            services.mkdir()
            for name in ("MonitorConfigOption.qml", "NestableObject.qml"):
                shutil.copy(REPOSITORY / f"modules/common/models/{name}", models)
            (services / "NiriData.qml").write_text('''pragma Singleton
import Quickshell
Singleton { readonly property bool isNiri: false }
''')
            (services / "NiriConfig.qml").write_text('''pragma Singleton
import Quickshell
Singleton { function generateOutputsKdl(monitors) {} }
''')
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "modules/common/models"
ShellRoot {
    MonitorConfigOption { id: monitors }
    function check(condition, message) {
        if (!condition) console.error("ASSERTION_FAILED", message);
    }
    Component.onCompleted: {
        const output = { width: 3840, height: 2160, scale: 2, transform: 0 };
        check(monitors.logicalWidth(output) === 1920, "HiDPI width");
        check(monitors.logicalHeight(output) === 1080, "HiDPI height");
        output.transform = 1;
        check(monitors.logicalWidth(output) === 1080, "rotated HiDPI width");
        check(monitors.logicalHeight(output) === 1920, "rotated HiDPI height");
        output.transform = 0;
        output.scale = 1.25;
        output.width = 1921;
        check(monitors.logicalWidth(output) === 1537, "fractional size rounds to nearest pixel");
        output.scale = 0;
        check(monitors.logicalWidth(output) === 1921, "invalid scale fallback");
        console.log("MONITOR_TEST_DONE");
        Qt.callLater(() => Qt.quit());
    }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True,
                                    timeout=8, env=dict(os.environ, QT_QPA_PLATFORM="offscreen"))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("MONITOR_TEST_DONE", output)
            self.assertNotIn("ASSERTION_FAILED", output)
            self.assertNotIn("TypeError", output)


if __name__ == "__main__":
    unittest.main()
