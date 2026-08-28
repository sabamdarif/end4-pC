import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

// Warns when ~/.config/niri/config.kdl is missing the qssettings include lines,
// or has them somewhere other than the end (later config wins in niri).
NoticeBox {
    id: root

    // "ok" | "misplaced" | "missing"
    property string includeStatus: "ok"

    visible: root.includeStatus !== "ok"
    Layout.fillWidth: true
    text: root.includeStatus === "misplaced"
        ? Translation.tr("The qssettings include lines are in your config.kdl but not at the end. Later config wins in niri, so your own settings currently override these. Fix moves them to the bottom (a backup of config.kdl is made first).")
        : Translation.tr("These settings are saved to ~/.config/niri/qssettings/. Setup adds the include lines at the end of your config.kdl (a backup is made first):") + "\n\n" + NiriConfig.includeLines

    Component.onCompleted: includeCheckProc.running = true

    Item { Layout.fillWidth: true }

    RippleButtonWithIcon {
        Layout.fillWidth: false
        buttonRadius: Appearance.rounding.small
        materialIcon: root.includeStatus === "misplaced" ? "build" : "auto_fix_high"
        mainText: root.includeStatus === "misplaced" ? Translation.tr("Fix") : Translation.tr("Setup")
        onClicked: setupIncludesProc.running = true
        colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
        colBackgroundHover: Appearance.colors.colPrimaryContainerHover
        colRipple: Appearance.colors.colPrimaryContainerActive
    }

    RippleButtonWithIcon {
        id: copyIncludesButton
        property bool justCopied: false
        Layout.fillWidth: false
        buttonRadius: Appearance.rounding.small
        materialIcon: justCopied ? "check" : "content_copy"
        mainText: justCopied ? Translation.tr("Copied!") : Translation.tr("Copy lines")
        onClicked: {
            copyIncludesButton.justCopied = true
            Quickshell.clipboardText = NiriConfig.includeLines
            revertCopyTimer.restart()
        }
        colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
        colBackgroundHover: Appearance.colors.colPrimaryContainerHover
        colRipple: Appearance.colors.colPrimaryContainerActive
        Timer {
            id: revertCopyTimer
            interval: 1500
            onTriggered: copyIncludesButton.justCopied = false
        }
    }

    Process {
        id: includeCheckProc
        // ok = all include lines present and nothing but blanks/comments/includes after them
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
        // Backs up config.kdl, strips qssettings include lines wherever they are,
        // re-appends them at the end. Writes through symlinks (stow-managed dotfiles).
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
