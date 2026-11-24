import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Dialog {
    id: root
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(440, parent.width - 32)
    modal: true
    closePolicy: saveProc.running ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 24
    property var details: ({})
    property string errorText: ""
    property bool saved: false

    function share(uuid) {
        if (generateProc.running) return;
        root.details = ({});
        root.errorText = "";
        root.saved = false;
        reveal.checked = false;
        root.open();
        generateProc.exec(["python3", Quickshell.shellPath("scripts/network/wifi_qr.py"), uuid]);
    }

    function clearImage() {
        if (root.details.path) Quickshell.execDetached(["rm", "-f", "--", root.details.path]);
        root.details = ({});
    }
    onClosed: root.clearImage()
    Component.onDestruction: root.clearImage()

    background: Rectangle {
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer1
    }
    Process {
        id: generateProc
        stdout: StdioCollector {
            onStreamFinished: {
                let data;
                try { data = JSON.parse(text); } catch (e) { data = { error: "operation-failed" }; }
                if (!root.visible) {
                    if (data.path) Quickshell.execDetached(["rm", "-f", "--", data.path]);
                    return;
                }
                if (data.error) {
                    root.errorText = data.error === "unsupported-security"
                        ? Translation.tr("QR sharing supports open, WEP and personal WPA networks only.")
                        : data.error === "missing-secret"
                            ? Translation.tr("The saved password is unavailable. Check NetworkManager permissions.")
                            : data.error === "missing-tool"
                                ? Translation.tr("Install qrencode and NetworkManager to share Wi-Fi.")
                                : Translation.tr("Could not generate the Wi-Fi QR code.");
                } else root.details = data;
            }
        }
    }
    Process {
        id: saveProc
        onExited: code => {
            root.saved = code === 0;
            if (code !== 0) root.errorText = Translation.tr("Could not save the QR image.");
        }
    }
    FileDialog {
        id: saveDialog
        title: Translation.tr("Save Wi-Fi QR image")
        fileMode: FileDialog.SaveFile
        nameFilters: [Translation.tr("PNG images (*.png)")]
        onAccepted: saveProc.exec(["python3", Quickshell.shellPath("scripts/network/wifi_qr.py"), "--save",
            root.details.path, FileUtils.trimFileProtocol(selectedFile.toString())])
    }
    contentItem: ColumnLayout {
        spacing: 16
        StyledText {
            Layout.fillWidth: true
            text: root.details.ssid || Translation.tr("Share Wi-Fi")
            font.pixelSize: Appearance.font.pixelSize.larger
            wrapMode: Text.Wrap
        }
        StyledIndeterminateProgressBar { Layout.fillWidth: true; visible: generateProc.running }
        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 260
            Layout.preferredHeight: 260
            visible: !!root.details.path
            source: root.details.path ? "file://" + root.details.path : ""
            fillMode: Image.PreserveAspectFit
            smooth: false
            cache: false
        }
        StyledText {
            Layout.fillWidth: true
            visible: !!root.details.path
            text: root.details.security === "nopass" ? Translation.tr("Open network") : root.details.security || ""
        }
        MaterialTextField {
            Layout.fillWidth: true
            visible: !!root.details.password
            text: root.details.password || ""
            readOnly: true
            echoMode: reveal.checked ? TextInput.Normal : TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData
        }
        ConfigSwitch {
            id: reveal
            visible: !!root.details.password
            text: Translation.tr("Show password")
        }
        StyledText {
            Layout.fillWidth: true
            visible: root.errorText !== "" || root.saved
            text: root.errorText || Translation.tr("Image saved. It contains your Wi-Fi password.")
            wrapMode: Text.Wrap
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            DialogButton {
                visible: !!root.details.password
                buttonText: Translation.tr("Copy password")
                onClicked: Quickshell.clipboardText = root.details.password
            }
            DialogButton {
                enabled: !!root.details.path && !saveProc.running
                buttonText: Translation.tr("Save image")
                onClicked: saveDialog.open()
            }
            DialogButton { buttonText: Translation.tr("Done"); enabled: !saveProc.running; onClicked: root.close() }
        }
    }
}
