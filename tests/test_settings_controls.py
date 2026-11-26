import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class SettingsControlTests(unittest.TestCase):
    def test_spinbox_only_reports_user_input_and_keeps_external_binding(self):
        with tempfile.TemporaryDirectory(prefix="config-spinbox-") as directory:
            root = Path(directory)
            common = root / "modules/common"
            widgets = common / "widgets"
            widgets.mkdir(parents=True)
            functions = common / "functions"
            functions.mkdir()
            (functions / "Unused.qml").write_text("import QtQuick\nQtObject {}")
            for name in ("ConfigSpinBox.qml", "StyledSpinBox.qml", "StyledTextInput.qml"):
                shutil.copy(REPOSITORY / "modules/common/widgets" / name, widgets)
            (common / "Appearance.qml").write_text('''pragma Singleton
import Quickshell
Singleton {
    property var font: ({ pixelSize: { small: 14 }, family: { main: "Sans", numbers: "Sans" }, variableAxes: { main: {}, numbers: {} } })
    property var rounding: ({ small: 10, unsharpen: 3 })
    property var colors: ({ colOnSecondaryContainer: "white", colOnLayer1: "white", colOnLayer2: "white", colLayer2: "gray", colLayer2Hover: "gray", colLayer2Active: "gray", colSecondaryContainer: "gray" })
    property var m3colors: ({ m3outline: "gray", m3onSecondaryContainer: "white" })
    property var animation: ({ elementMoveFast: { colorAnimation: null } })
}
''')
            # Keep the real input/control behavior without requiring appearance animation factories.
            for name, contents in {
                "StyledText.qml": 'import QtQuick\nText {}',
                "OptionalMaterialSymbol.qml": 'import QtQuick\nItem { property string icon }',
                "MaterialSymbol.qml": 'import QtQuick\nText { property real iconSize }',
            }.items():
                (widgets / name).write_text(contents)
            spinbox = widgets / "StyledSpinBox.qml"
            source = spinbox.read_text()
            source = source.replace('Behavior on color {\n            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)\n        }', '')
            source = source.replace('ColorUtils.transparentize(Appearance.colors.colLayer2)', 'Appearance.colors.colLayer2')
            spinbox.write_text(source)
            (root / "shell.qml").write_text('''import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "modules/common/widgets"
ShellRoot {
    Window {
        id: window
        visible: true; width: 600; height: 200
        property int externalValue: 20
        property int modifications: 0
        function check(condition, message) { if (!condition) console.error("ASSERTION_FAILED", message); }
        ConfigSpinBox {
            id: control
            anchors.centerIn: parent
            value: window.externalValue
            from: 0; to: 100
            onValueModified: { window.modifications++; window.externalValue = value; }
        }
        TestCase {
            name: "SpinboxInput"
            when: window.visible
            function test_input() {
                wait(100);
                window.externalValue = 30;
                window.check(control.value === 30 && window.modifications === 0, "external updates are not user input");
                const spin = control.children[1];
                spin.forceActiveFocus();
                keyClick(Qt.Key_Up);
                window.check(window.externalValue === 31 && window.modifications === 1, "arrow keys report user input");
                window.externalValue = 40;
                window.check(control.value === 40, "binding survives arrow input");
                spin.contentItem.forceActiveFocus();
                spin.contentItem.selectAll();
                keyClick(Qt.Key_4);
                keyClick(Qt.Key_2);
                keyClick(Qt.Key_Return);
                wait(20);
                window.check(window.externalValue === 42 && window.modifications === 2, "typed input uses native SpinBox editing");
                window.externalValue = 50;
                window.check(control.value === 50, "binding survives typed input");
                console.log("SPINBOX_TEST_DONE");
                Qt.quit();
            }
        }
    }
    Timer { interval: 2000; running: true; onTriggered: { console.error("ASSERTION_FAILED", "test timed out"); Qt.quit(); } }
}
''')
            result = subprocess.run(["qs", "-p", str(root)], capture_output=True, text=True,
                                    timeout=8, env=dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_CONTROLS_STYLE="Basic"))
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("SPINBOX_TEST_DONE", output)
            for error in ("ASSERTION_FAILED", "TypeError", "ReferenceError", "FAIL!"):
                self.assertNotIn(error, output)

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
                "RippleButton.qml": 'import QtQuick\nimport QtQuick.Controls\nButton { property color colBackgroundHover; property color colRipple; property bool rippleEnabled }',
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
Singleton { signal configReloaded(); function generateOutputsKdl(monitors) {} }
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
