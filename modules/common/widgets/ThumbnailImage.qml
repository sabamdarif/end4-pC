import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Thumbnail image. It currently generates to the right place at the right size, but does not handle metadata/maintenance on modification.
 * See Freedesktop's spec: https://specifications.freedesktop.org/thumbnail-spec/thumbnail-spec-latest.html
 */
StyledImage {
    id: root

    property bool generateThumbnail: true
    required property string sourcePath
    property string thumbnailSizeName: Images.thumbnailSizeNameForDimensions(sourceSize.width, sourceSize.height)
    property string thumbnailPath: {
        if (sourcePath.length == 0) return;
        const resolvedUrlWithoutFileProtocol = FileUtils.trimFileProtocol(`${Qt.resolvedUrl(sourcePath)}`);
        const encodedUrlWithoutFileProtocol = resolvedUrlWithoutFileProtocol.split("/").map(part => encodeURIComponent(part)).join("/");
        const md5Hash = Qt.md5(`file://${encodedUrlWithoutFileProtocol}`);
        return `${Directories.genericCache}/thumbnails/${thumbnailSizeName}/${md5Hash}.png`;
    }
    source: thumbnailPath

    asynchronous: true
    smooth: true
    mipmap: false

    opacity: status === Image.Ready ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    function requestGeneration() {
        if (!root.generateThumbnail || !root.sourcePath || root.sourcePath.length === 0) return;
        thumbnailGeneration.running = false;
        thumbnailGeneration.running = true;
    }

    Component.onCompleted: requestGeneration()
    onSourceSizeChanged: requestGeneration()
    onSourcePathChanged: requestGeneration()

    Process {
        id: thumbnailGeneration
        command: {
            const maxSize = Images.thumbnailSizes[root.thumbnailSizeName] ?? 256;
            const thumbPath = FileUtils.trimFileProtocol(root.thumbnailPath);
            const srcPath = FileUtils.trimFileProtocol(root.sourcePath);
            return [
                "bash", "-c",
                `src="$1"; thumb="$2"; max="$3"
if [ -f "$thumb" ]; then exit 0; fi
mkdir -p "$(dirname "$thumb")"
tmp="$thumb.$$.tmp.png"
case "\${src,,}" in
    *.mp4|*.webm|*.mkv|*.avi|*.mov)
        (ffmpegthumbnailer -i "$src" -o "$tmp" -s "$max" -f 2>/dev/null || ffmpeg -y -i "$src" -vframes 1 -vf "scale=\${max}:-1" "$tmp" 2>/dev/null) && mv -f "$tmp" "$thumb" && exit 1
        ;;
    *)
        nice -n 19 magick "$src" -resize "\${max}x\${max}" "$tmp" 2>/dev/null && mv -f "$tmp" "$thumb" && exit 1
        ;;
esac
rm -f "$tmp"
exit 2`,
                "bash",
                srcPath,
                thumbPath,
                `${maxSize}`
            ];
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 1) { // Force reload if thumbnail had to be generated
                root.source = "";
                root.source = root.thumbnailPath; // Force reload
            }
        }
    }
}
