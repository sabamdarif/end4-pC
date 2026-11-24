pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * Simple to-do list manager.
 * Each item is an object with "content" and "done" properties.
 */
Singleton {
    id: root
    property var filePath: Directories.todoPath
    property var list: []
    property bool ready: false
    property string errorText: ""
    
    function addItem(item) {
        if (!ready) return;
        list.push(item)
        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        todoFileView.setText(JSON.stringify(root.list))
    }

    function addTask(desc) {
        const item = {
            "content": desc,
            "done": false,
        }
        addItem(item)
    }

    function markDone(index) {
        if (!ready) return;
        if (index >= 0 && index < list.length) {
            list[index].done = true
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function markUnfinished(index) {
        if (!ready) return;
        if (index >= 0 && index < list.length) {
            list[index].done = false
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function deleteItem(index) {
        if (!ready) return;
        if (index >= 0 && index < list.length) {
            list.splice(index, 1)
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function refresh() {
        todoFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    FileView {
        id: todoFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            const fileContents = todoFileView.text()
            try {
                const parsed = JSON.parse(fileContents)
                if (!Array.isArray(parsed) || !parsed.every(task => task && typeof task.content === "string"
                    && typeof task.done === "boolean"))
                    throw new Error("Invalid task format");
                root.list = parsed
                root.ready = true
                root.errorText = ""
                console.log("[To Do] File loaded")
            } catch (e) {
                root.ready = false
                root.errorText = Translation.tr("Could not load tasks. Repair the data file and reload the shell.")
                console.error("[To Do] Preserving unreadable file:", root.filePath, e)
            }
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[To Do] File not found, creating new file.")
                root.list = []
                root.ready = true
                root.errorText = ""
                todoFileView.setText(JSON.stringify(root.list))
            } else {
                root.ready = false
                root.errorText = Translation.tr("Could not load tasks. Repair the data file and reload the shell.")
                console.error("[To Do] Error loading file:", error)
            }
        }
    }
}
