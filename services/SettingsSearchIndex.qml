pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Array of registered row descriptors:
    // { pageKey, sectionTitle, rowId, label, subtitle, keywords, isWip, targetItem }
    property var registeredRows: []

    function registerRow(entry) {
        if (!entry || !entry.rowId) return
        let next = root.registeredRows.filter(r => r.rowId !== entry.rowId)
        next.push(entry)
        root.registeredRows = next
    }

    function unregisterRow(rowId) {
        if (!rowId) return
        root.registeredRows = root.registeredRows.filter(r => r.rowId !== rowId)
    }

    function search(query) {
        const q = String(query ?? "").toLowerCase().trim()
        if (q === "") return []

        let results = []
        for (let i = 0; i < root.registeredRows.length; i++) {
            const r = root.registeredRows[i]
            const label = String(r.label ?? "").toLowerCase()
            const subtitle = String(r.subtitle ?? "").toLowerCase()
            const section = String(r.sectionTitle ?? "").toLowerCase()
            const keywords = Array.isArray(r.keywords) ? r.keywords.map(k => String(k).toLowerCase()) : []

            let matched = false
            let score = 0
            if (label.includes(q)) {
                matched = true
                score += label.startsWith(q) ? 10 : 5
            }
            if (subtitle.includes(q)) {
                matched = true
                score += 3
            }
            if (section.includes(q)) {
                matched = true
                score += 2
            }
            if (keywords.some(k => k.includes(q))) {
                matched = true
                score += 4
            }

            if (matched) {
                results.push({
                    pageKey: r.pageKey,
                    rowId: r.rowId,
                    label: r.label,
                    subtitle: r.subtitle,
                    sectionTitle: r.sectionTitle,
                    isWip: r.isWip,
                    targetItem: r.targetItem,
                    score: score
                })
            }
        }

        results.sort((a, b) => b.score - a.score)
        return results.slice(0, 15)
    }
}
