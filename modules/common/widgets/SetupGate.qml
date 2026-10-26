import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Rectangle {
    id: root

    // "ok" | "misplaced" | "missing"
    property string includeStatus: "ok"

    visible: root.includeStatus !== "ok"
    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colPrimaryContainer

    Component.onCompleted: includeCheckProc.running = true

    ColumnLayout {
        id: mainLayout
        anchors {
            fill: parent
            margins: 14
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 36
                height: 36
                radius: Appearance.rounding.small
                color: Appearance.colors.colPrimary
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.includeStatus === "misplaced" ? "build" : "auto_fix_high"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnPrimary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: root.includeStatus === "misplaced"
                        ? Translation.tr("Niri Includes Misplaced")
                        : Translation.tr("Niri Integration Setup")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnPrimaryContainer
                }

                StyledText {
                    text: root.includeStatus === "misplaced"
                        ? Translation.tr("qssettings include lines are not at the end of config.kdl. Later config wins in niri, so your own settings override these.")
                        : Translation.tr("Settings write to ~/.config/niri/qssettings/. Setup adds the required include lines to your config.kdl (a backup is made first).")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnPrimaryContainer
                    opacity: 0.85
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            RippleButtonWithIcon {
                id: copyButton
                property bool justCopied: false
                buttonRadius: Appearance.rounding.small
                materialIcon: justCopied ? "check" : "content_copy"
                mainText: justCopied ? Translation.tr("Copied") : Translation.tr("Copy lines")
                colBackground: Appearance.colors.colSecondaryContainer
                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                onClicked: {
                    copyButton.justCopied = true
                    Quickshell.clipboardText = NiriConfig.includeLines
                    revertCopyTimer.restart()
                }
                Timer {
                    id: revertCopyTimer
                    interval: 1500
                    onTriggered: copyButton.justCopied = false
                }
            }

            RippleButtonWithIcon {
                buttonRadius: Appearance.rounding.small
                materialIcon: root.includeStatus === "misplaced" ? "build" : "auto_fix_high"
                mainText: root.includeStatus === "misplaced" ? Translation.tr("Fix now") : Translation.tr("Setup")
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover
                colRipple: Appearance.colors.colPrimaryActive
                onClicked: setupIncludesProc.running = true
            }
        }
    }

    Process {
        id: includeCheckProc
        command: ["sh", "-c", `cfg="$HOME/.config/niri/config.kdl"
missing=0
for f in shell outputs autostart binds; do
    grep -qs "qssettings/$f.kdl" "$cfg" || missing=1
done
if [ "$missing" = 1 ]; then echo missing
elif awk '/qssettings\\/shell.kdl/ {found=1; next} found && NF && $0 !~ /qssettings/ && $0 !~ /^[ \\t]*\\/\\// {bad=1} END {exit bad}' "$cfg"; then echo ok
else echo misplaced
fi`]
        stdout: StdioCollector {
            onStreamFinished: root.includeStatus = text.trim()
        }
    }

    Process {
        id: setupIncludesProc
        command: ["sh", "-c", `cfg="$HOME/.config/niri/config.kdl"
cp -L "$cfg" "$cfg.backup.$(date +%s)" || exit 1
tmp=$(mktemp)
grep -vE 'qssettings/(shell|outputs|autostart|binds)\\.kdl' "$cfg" > "$tmp"
printf '\\ninclude optional=true "qssettings/shell.kdl"\\ninclude optional=true "qssettings/outputs.kdl"\\ninclude optional=true "qssettings/autostart.kdl"\\ninclude optional=true "qssettings/binds.kdl"\\n' >> "$tmp"
cat "$tmp" > "$cfg"
rm -f "$tmp"`]
        onExited: includeCheckProc.running = true
    }
}
