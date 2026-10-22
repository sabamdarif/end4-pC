import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

QtObject {
    id: root

    property string query: ""
    property list<var> results: []
    property bool searching: false

    function getFileIcon(ext: string): string {
        switch (ext) {
            case "pdf": return "picture_as_pdf";
            case "md":
            case "markdown":
            case "txt":
            case "log":
            case "org": return "description";
            case "odt":
            case "doc":
            case "docx":
            case "rtf": return "article";
            case "ods":
            case "xls":
            case "xlsx":
            case "csv": return "table_chart";
            case "odp":
            case "ppt":
            case "pptx": return "slideshow";
            case "png":
            case "jpg":
            case "jpeg":
            case "gif":
            case "webp":
            case "svg":
            case "bmp":
            case "ico": return "image";
            case "mp4":
            case "mkv":
            case "webm":
            case "avi":
            case "mov": return "movie";
            case "mp3":
            case "flac":
            case "wav":
            case "m4a":
            case "ogg":
            case "opus": return "audiotrack";
            case "zip":
            case "tar":
            case "gz":
            case "7z":
            case "rar":
            case "xz": return "folder_zip";
            case "qml":
            case "js":
            case "ts":
            case "py":
            case "rs":
            case "go":
            case "c":
            case "cpp":
            case "h":
            case "json":
            case "sh": return "code";
            default: return "draft";
        }
    }

    onQueryChanged: {
        const q = root.query.trim();
        if (q.length < 2) {
            debounceTimer.stop();
            proc.running = false;
            root.results = [];
            root.searching = false;
            return;
        }
        debounceTimer.restart();
    }

    property var debounceTimer: Timer {
        interval: 100
        repeat: false
        onTriggered: root.executeSearch()
    }

    function executeSearch() {
        const q = root.query.trim();
        if (q.length < 2) return;

        proc.running = false;
        proc.buffer = [];
        root.searching = true;

        const home = FileUtils.trimFileProtocol(Directories.home);
        const rawLocations = Config.options.search?.searchLocations ?? ["~"];
        const resolvedLocations = rawLocations.map(loc => {
            if (loc === "~") return home;
            if (loc.startsWith("~/")) return home + loc.slice(1);
            return loc;
        });

        let uniqueLocations = [];
        if (resolvedLocations.includes(home)) {
            uniqueLocations = [home];
        } else {
            uniqueLocations = Array.from(new Set(resolvedLocations));
        }

        const escapedQuery = StringUtils.shellSingleQuoteEscape(q);
        const locArgs = uniqueLocations.map(l => `'${StringUtils.shellSingleQuoteEscape(l)}'`).join(" ");

        const script = `
dirs=()
for d in ${locArgs}; do
    [ -d "$d" ] && dirs+=("$d")
done
if [ \${#dirs[@]} -gt 0 ]; then
    fd -i --max-results 12 --type f --exclude .git --exclude node_modules --exclude .cache --exclude '.cargo' --exclude '.npm' '${escapedQuery}' "\${dirs[@]}" 2>/dev/null
fi
`;

        proc.command = ["bash", "-c", script];
        proc.running = true;
    }

    property var proc: Process {
        property var buffer: []

        stdout: SplitParser {
            onRead: line => {
                if (line && line.trim().length > 0)
                    proc.buffer.push(line.trim());
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.searching = false;
            const home = FileUtils.trimFileProtocol(Directories.home);
            const items = [];
            const seen = new Set();
            for (let i = 0; i < proc.buffer.length; i++) {
                const filePath = proc.buffer[i];
                if (!filePath || seen.has(filePath)) continue;
                seen.add(filePath);

                const fileName = FileUtils.fileNameForPath(filePath);
                const fileDir = FileUtils.parentDirectory(filePath);
                const displayDir = fileDir.startsWith(home) ? ("~" + fileDir.slice(home.length)) : fileDir;
                const parts = fileName.split(".");
                const ext = parts.length > 1 ? parts[parts.length - 1].toLowerCase() : "";

                items.push({
                    name: fileName,
                    path: filePath,
                    dir: displayDir,
                    fullDir: fileDir,
                    ext: ext,
                    icon: root.getFileIcon(ext),
                    execute: () => {
                        Quickshell.execDetached(["xdg-open", filePath]);
                    },
                    openFolder: () => {
                        Quickshell.execDetached(["xdg-open", fileDir]);
                    }
                });
            }
            root.results = items;
        }
    }
}
