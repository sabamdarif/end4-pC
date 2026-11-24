pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Simple notes manager.
 * Each item is an object with "id", "content", "attachments" (array of file paths), "createdAt".
 */
Singleton {
    id: root
    property var filePath: Directories.desktopNotesPath
    property var list: []
    property bool ready: false
    property string errorText: ""

    function addNote(content, attachments) {
        if (!ready) return;
        const item = {
            "id": Date.now().toString() + "-" + Math.floor(Math.random() * 10000),
            "content": content ?? "",
            "attachments": attachments ?? [],
            "createdAt": Date.now()
        }
        list.push(item)
        root.list = list.slice(0)
        notesFileView.setText(JSON.stringify(root.list))
        return item.id
    }

    function updateNote(id, content, attachments) {
        if (!ready) return;
        const idx = list.findIndex(n => n.id === id)
        if (idx >= 0) {
            list[idx].content = content
            if (attachments !== undefined)
                list[idx].attachments = attachments
            root.list = list.slice(0)
            notesFileView.setText(JSON.stringify(root.list))
        }
    }

    function deleteNote(id) {
        if (!ready) return;
        const idx = list.findIndex(n => n.id === id)
        if (idx >= 0) {
            list.splice(idx, 1)
            root.list = list.slice(0)
            notesFileView.setText(JSON.stringify(root.list))
        }
    }

    function refresh() {
        notesFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    FileView {
        id: notesFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            const fileContents = notesFileView.text()
            try {
                const parsed = JSON.parse(fileContents)
                if (!Array.isArray(parsed) || !parsed.every(note => note && typeof note.id === "string"
                    && typeof note.content === "string" && Array.isArray(note.attachments)
                    && note.attachments.every(path => typeof path === "string")))
                    throw new Error("Invalid notes format");
                root.list = parsed
                root.ready = true
                root.errorText = ""
            } catch (e) {
                root.ready = false
                root.errorText = Translation.tr("Could not load notes. Repair the data file and reload the shell.")
                console.error("[Notes] Preserving unreadable file:", root.filePath, e)
            }
            console.log("[Notes] File loaded")
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                console.log("[Notes] File not found, creating new file.")
                root.list = []
                root.ready = true
                root.errorText = ""
                notesFileView.setText(JSON.stringify(root.list))
            } else {
                root.ready = false
                root.errorText = Translation.tr("Could not load notes. Repair the data file and reload the shell.")
                console.error("[Notes] Error loading file:", error)
            }
        }
    }
}
