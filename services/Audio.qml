pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    // Misc props
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00 // People keep joking about setting volume to 5172% so...
    readonly property real maxVolume: Config.options.audio.overamplify ? 1.5 : 1.0
    property string audioTheme: Config.options.sounds.theme
    property real value: sink?.audio.volume ?? 0
    
    function friendlyDeviceName(node) {
        return (node.nickname || node.description || Translation.tr("Unknown"));
    }
    function appNodeDisplayName(node) {
        return (node.properties["application.name"] || node.description || node.name)
    }

    // Lists
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
            return root.correctType(node, isSink) && node.isStream
        })
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream
        })
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    // Signals
    signal sinkProtectionTriggered(string reason);

    // Controls
    function toggleMute() {
        Audio.sink.audio.muted = !Audio.sink.audio.muted
    }

    function toggleMicMute() {
        Audio.source.audio.muted = !Audio.source.audio.muted
    }

    function incrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume = Math.min(root.maxVolume, Audio.sink.audio.volume + step);
    }
    
    function decrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume -= step;
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Internals
    PwObjectTracker {
        objects: [sink, source]
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!Config.options.audio.protection.enable) return;
            const newVolume = sink.audio.volume;
            // when resuming from suspend, we should not write volume to avoid pipewire volume reset issues
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100; 
            const maxAllowed = Config.options.audio.protection.maxAllowed / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered(Translation.tr("Illegal increment"));
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                sink.audio.volume = Math.min(lastVolume, maxAllowed);
            }
            lastVolume = sink.audio.volume;
        }
    }

    Timer { // Debounce so scrolling doesn't spam the sound
        id: volumeChangedSoundTimer
        interval: 90
        onTriggered: root.playSystemSound("audio-volume-change")
    }

    Connections { // Volume changed feedback sound
        target: sink?.audio ?? null
        property bool lastReady: false
        function onVolumeChanged() {
            const newVolume = sink.audio.volume;
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                return;
            }
            if (!lastReady) { // Skip startup/initial value
                lastReady = true;
                return;
            }
            if (!Config.options.sounds.volumeChanged) return;
            volumeChangedSoundTimer.restart();
        }
    }

    function playSystemSound(soundName) {
        // Prefer canberra-gtk-play: it resolves sound themes and fallbacks per the
        // XDG sound theme spec by itself. Otherwise resolve the theme dir manually
        // (configured theme -> system/GNOME theme -> freedesktop) and play the file.
        const script = `
snd="$1"; theme="$2"
if command -v canberra-gtk-play >/dev/null 2>&1; then
    if [ -n "$theme" ]; then
        exec canberra-gtk-play -i "$snd" --property=canberra.xdg-theme.name="$theme"
    fi
    exec canberra-gtk-play -i "$snd"
fi
[ -d "/usr/share/sounds/$theme/stereo" ] || theme="$(gsettings get org.gnome.desktop.sound theme-name 2>/dev/null | tr -d \\')"
[ -d "/usr/share/sounds/$theme/stereo" ] || theme="freedesktop"
for f in "/usr/share/sounds/$theme/stereo/$snd.oga" "/usr/share/sounds/$theme/stereo/$snd.ogg" "/usr/share/sounds/freedesktop/stereo/$snd.oga"; do
    if [ -f "$f" ]; then
        if command -v ffplay >/dev/null 2>&1; then exec ffplay -nodisp -autoexit -loglevel quiet "$f"; fi
        if command -v pw-play >/dev/null 2>&1; then exec pw-play "$f"; fi
        if command -v paplay >/dev/null 2>&1; then exec paplay "$f"; fi
    fi
done
`;
        Quickshell.execDetached(["bash", "-c", script, "playSystemSound", soundName, root.audioTheme]);
    }
}
