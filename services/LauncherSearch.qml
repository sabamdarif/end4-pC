pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.ii.settings

Singleton {
    id: root

    property string query: ""

    onQueryChanged: {
        if (Config.options.search.providers?.files ?? true) {
            FileSearch.query = root.query;
        } else {
            FileSearch.query = "";
        }
    }

    // Mirrors the settings nav tree so the two never drift
    readonly property var settingsIndex: SettingsPages.leaves.map(l => ({
        key: l.key,
        page: l.name,
        group: l.groupName,
        path: l.component
    }))

    property var settingsKeywordsCache: ({})

    Process {
        id: keywordHarvester
        property var pendingPages: []
        property string currentPageName: ""

        function startHarvesting() {
            root.settingsKeywordsCache = {};
            pendingPages = root.settingsIndex.slice();
            next();
        }

        function next() {
            if (pendingPages.length === 0)
                return;

            let currentPage = pendingPages.shift();
            let fullPath = FileUtils.trimFileProtocol(String(currentPage.path));
            let rawCommand = "grep -oP \"title:\\s*Translation.tr\\(['\\\"].*?['\\\"]\\)\" " + fullPath + " | sed -E \"s/title:\\s*Translation.tr\\(['\\\"](.*)['\\\"]\\)/\\1/g\" | tr '\\n' ' '";

            command = ["bash", "-c", rawCommand];
            keywordHarvester.currentPageName = currentPage.key;
            running = true;
        }

        onExited: (exitCode, exitStatus) => {
            keywordHarvester.next();
        }

        stdout: SplitParser {
            onRead: data => {
                let cache = root.settingsKeywordsCache;
                cache[keywordHarvester.currentPageName] = (cache[keywordHarvester.currentPageName] || "") + " " + data;
                root.settingsKeywordsCache = cache;
            }
        }
    }

    Component.onCompleted: {
        keywordHarvester.startHarvesting();
    }

    // Math evaluation
    function evaluateMath(rawExpr: string): var {
        if (!rawExpr || rawExpr.trim().length === 0)
            return null;
        let expr = rawExpr.trim();
        if (expr.startsWith("="))
            expr = expr.slice(1).trim();

        let sanitized = expr.replace(/\^/g, "**");
        sanitized = sanitized.replace(/\bpi\b/gi, "Math.PI").replace(/\be\b/gi, "Math.E");
        sanitized = sanitized.replace(/\b(sqrt|sin|cos|tan|abs|log|round|floor|ceil)\b/gi, "Math.$1");

        let check = sanitized.replace(/Math\.(sqrt|sin|cos|tan|abs|log|round|floor|ceil|PI|E)/g, "").replace(/[\d\.\+\-\*\/\%\(\)\s]/g, "");
        if (check.length > 0)
            return null;

        if (!/\d/.test(sanitized) || !(/[\+\-\*\/\%]|Math\./.test(sanitized)))
            return null;

        try {
            let fn = new Function("return (" + sanitized + ")");
            let val = fn();
            if (typeof val === "number" && !isNaN(val) && isFinite(val)) {
                return {
                    expression: expr,
                    result: String(Math.round(val * 1000000000) / 1000000000)
                };
            }
        } catch (e) {}
        return null;
    }

    readonly property var mathResult: {
        if (!(Config.options.search.providers?.calculator ?? true))
            return null;
        return evaluateMath(root.query);
    }

    readonly property list<var> appResults: {
        if (root.query === "")
            return [];
        if (root.query === " ") {
            return AppSearch.list
                .slice()
                .sort((a, b) => a.name.localeCompare(b.name))
                .map(entry => createEntryObject(entry));
        }
        return AppSearch.fuzzyQuery(root.query.trim()).map(entry => createEntryObject(entry));
    }

    function createEntryObject(entry) {
        return {
            type: Translation.tr("App"),
            id: entry.id,
            name: entry.name,
            iconName: entry.icon,
            iconType: LauncherSearchResult.IconType.System,
            verb: Translation.tr("Open"),
            comment: entry.comment,
            runInTerminal: entry.runInTerminal,
            execute: () => {
                if (!entry.runInTerminal)
                    entry.execute();
                else
                    Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
            }
        };
    }

    readonly property list<var> fileResults: {
        if (!(Config.options.search.providers?.files ?? true))
            return [];
        return FileSearch.results;
    }

    readonly property list<var> iconResults: {
        if (!(Config.options.search.providers?.icons ?? true))
            return [];
        const q = root.query.trim();
        if (q.length === 0 || q === " ")
            return [];
        return MaterialSymbolsSearch.fuzzyQuery(q).slice(0, 12).map(entry => {
            const tabIdx = entry.indexOf("\t");
            const symName = tabIdx >= 0 ? entry.slice(0, tabIdx) : entry;
            return {
                name: symName,
                iconName: symName,
                iconType: LauncherSearchResult.IconType.Material,
                verb: Translation.tr("Copy"),
                type: Translation.tr("Symbol"),
                execute: () => {
                    Quickshell.clipboardText = symName;
                }
            };
        });
    }

    readonly property list<var> settingsResults: {
        if (!(Config.options.search.providers?.settings ?? true))
            return [];
        const q = root.query.toLowerCase().trim();
        if (q.length === 0 || q === " ")
            return [];

        return root.settingsIndex.reduce((acc, page) => {
            const dynamicKeywords = (root.settingsKeywordsCache[page.key] || "").toLowerCase();
            if (page.page.toLowerCase().includes(q) || page.group.toLowerCase().includes(q) || dynamicKeywords.includes(q)) {
                acc.push({
                    name: `${page.group} • ${page.page}`,
                    comment: dynamicKeywords.includes(q) ? Translation.tr("Section: %1").arg(q) : Translation.tr("Settings for %1").arg(page.page),
                    verb: Translation.tr("Go"),
                    type: Translation.tr("Settings"),
                    iconName: "settings",
                    iconType: LauncherSearchResult.IconType.Material,
                    execute: () => {
                        GlobalStates.settingsOpen = true;
                        Qt.callLater(() => {
                            GlobalStates.settingsPage = page.key + ":" + q;
                        });
                        root.query = "";
                    }
                });
            }
            return acc;
        }, []);
    }

    // Flat results list for quick keyboard launch
    readonly property list<var> flatResults: {
        let list = [];
        if (root.mathResult) {
            list.push({
                type: Translation.tr("Math"),
                name: root.mathResult.result,
                execute: () => {
                    Quickshell.clipboardText = root.mathResult.result;
                }
            });
        }
        for (let i = 0; i < root.appResults.length; i++)
            list.push(root.appResults[i]);
        for (let i = 0; i < root.fileResults.length; i++)
            list.push(root.fileResults[i]);
        for (let i = 0; i < root.iconResults.length; i++)
            list.push(root.iconResults[i]);
        for (let i = 0; i < root.settingsResults.length; i++)
            list.push(root.settingsResults[i]);
        return list;
    }

    function launchTop() {
        if (flatResults.length > 0) {
            flatResults[0].execute();
            GlobalStates.overviewOpen = false;
        }
    }
}
