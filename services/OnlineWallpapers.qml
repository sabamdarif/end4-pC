pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string provider:   "wallhaven"  // "wallhaven" | "unsplash" | "pexels" | "naive"
    property string resolution: "1080p"      // "1080p" | "2K" | "4K"
    property string query:      ""           // empty keyword = random
    property string colorGroup: ""           // naive: "" = all | "red"|"orange"|"yellow"|"green"|"blue"|"purple"
    property string category:   "general"    // unsplash fallback query when the search field is empty
    property bool   loading:    false
    property bool   appending:  false
    property int    page:       1
    property string seed:       ""
    property var    results:    []           // list [ {thumb, full, id, provider} ]
    property int totalPages: 0
    property bool _refetchQueued: false

    // ─── Wallhaven advanced search ───
    // categories/purity are bitmask strings: general/anime/people and sfw/sketchy/nsfw
    property string wallhavenCategories: "111"
    property string wallhavenPurity: "100"
    property string wallhavenSorting: "relevance" // date_added|relevance|random|views|favorites|toplist|hot
    property string wallhavenOrder: "desc"
    property string wallhavenTopRange: "1y"
    property string wallhavenRatios: ""
    property string wallhavenColors: "" // comma-separated hex list (no '#')

    signal fetched()
    signal fetchError(string message)

    readonly property string userAgent: "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0"

    // ─── APIs ───
    readonly property string unsplashClientId: KeyringStorage.keyringData?.apiKeys?.unsplash  ?? ""
    // Keyring ("/wallhaven <key>") takes precedence; Config is a fallback set from the popup field
    readonly property string wallhavenApiKey:
        KeyringStorage.keyringData?.apiKeys?.wallhaven
        ?? Config.options.wallpaperSelector.wallhavenApiKey
        ?? ""
    readonly property string pexelsApiKey: KeyringStorage.keyringData?.apiKeys?.pexels ?? ""

    Component.onCompleted: loadWallhavenConfig()

    function loadWallhavenConfig() {
        const cfg = Config.options.wallpaperSelector
        wallhavenCategories = cfg.wallhavenCategories || "111"
        wallhavenPurity = cfg.wallhavenPurity || "100"
        wallhavenSorting = cfg.wallhavenSorting || "relevance"
        wallhavenOrder = cfg.wallhavenOrder || "desc"
        wallhavenRatios = cfg.wallhavenRatios || ""
        wallhavenColors = cfg.wallhavenColors || ""
        wallhavenTopRange = cfg.wallhavenTopRange || "1y"
    }

    function saveWallhavenConfig() {
        const cfg = Config.options.wallpaperSelector
        cfg.wallhavenCategories = wallhavenCategories
        cfg.wallhavenPurity = wallhavenPurity
        cfg.wallhavenSorting = wallhavenSorting
        cfg.wallhavenOrder = wallhavenOrder
        cfg.wallhavenRatios = wallhavenRatios
        cfg.wallhavenColors = wallhavenColors
        cfg.wallhavenTopRange = wallhavenTopRange
    }

    // ─── NA-ive ─── (from https://github.com/pctrade/end4-pC/pull/81 by @na-ive)
    // JSON index from gh-pages, full files from main branch
    readonly property string naiveJsonUrl: "https://raw.githubusercontent.com/na-ive/wallpapers/gh-pages/wallpapers.json"
    readonly property string naivePagesBase: "https://raw.githubusercontent.com/na-ive/wallpapers/gh-pages/"
    readonly property string naiveFullBase: "https://raw.githubusercontent.com/na-ive/wallpapers/main/"

    // ─── Resolution ───
    readonly property var resolutionMap: ({
        "wallhaven": {
            "1080p": "1920x1080",
            "2K":    "2560x1440",
            "4K":    "3840x2160",
        },
        "unsplash": {
            "1080p": "&w=1920&h=1080&fit=crop",
            "2K":    "&w=2560&h=1440&fit=crop",
            "4K":    "&w=3840&h=2160&fit=crop",
        },
        "pexels": {
            "1080p": "&w=1920&h=1080&fit=crop",
            "2K":    "&w=2560&h=1440&fit=crop",
            "4K":    "&w=3840&h=2160&fit=crop",
        }
    })

    function fetch() {
        // A single Process backs every request, so a search issued mid-request
        // waits for that one to finish instead of being dropped.
        if (root.loading) {
            root._refetchQueued = true;
            return;
        }
        root._refetchQueued = false;
        root.page = 1;
        root.seed = "";
        root.appending = false;
        root.results = [];
        _doFetch();
    }

    function nextPage() {
        if (root.loading) return;
        if (root.provider !== "unsplash" && root.totalPages > 0 && root.page >= root.totalPages) return;  // NUEVO: no pedir de más
        root.appending = true;   
        root.page += 1;
        _doFetch();
    }

    function _doFetch() {
        root.loading = true;
        if (root.provider === "wallhaven") {
            _fetchWallhaven();
        } else if (root.provider === "unsplash") {
            _fetchUnsplash();
        } else if (root.provider === "pexels") {
            _fetchPexels();
        } else if (root.provider === "naive") {
            _fetchNaive();
        }
    }

    // Picking the active wallhaven color clears it, matching the naive color toggle behavior.
    function setWallhavenColor(hex) {
        root.wallhavenColors = (root.wallhavenColors === hex) ? "" : (hex || "");
        root.saveWallhavenConfig();
        if (root.provider === "wallhaven") root.fetch();
    }

    function _fetchWallhaven() {
        const res = root.resolutionMap["wallhaven"][root.resolution] ?? "1920x1080";
        const purity = root.wallhavenPurity === "000" ? "100" : root.wallhavenPurity;

        const params = [];
        if (root.query.length > 0) params.push("q=" + encodeURIComponent(root.query));
        params.push("categories=" + root.wallhavenCategories);
        params.push("purity=" + purity);
        params.push("sorting=" + root.wallhavenSorting);
        if (root.wallhavenSorting !== "random") params.push("order=" + root.wallhavenOrder);
        if (root.wallhavenSorting === "toplist") params.push("topRange=" + root.wallhavenTopRange);
        if (root.wallhavenSorting === "random" && root.seed.length > 0) params.push("seed=" + root.seed);
        params.push("atleast=" + res);
        if (root.wallhavenRatios.length > 0) params.push("ratios=" + root.wallhavenRatios);
        if (root.wallhavenColors.length > 0) params.push("colors=" + root.wallhavenColors);
        if (root.wallhavenApiKey.length > 0) params.push("apikey=" + root.wallhavenApiKey);
        params.push("page=" + root.page);

        const url = "https://wallhaven.cc/api/v1/search?" + params.join("&");
        console.log("[OnlineWallpapers] fetch:", url.replace(/apikey=[^&]+/, "apikey=***"));

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            root.loading = false;
            if (xhr.status === 200) {
                root._parseWallhaven(xhr.responseText);
            } else if (root._looksLikeHtml(xhr.responseText)) {
                root.fetchError(Translation.tr("Wallhaven is temporarily unavailable (server busy or blocked). Try again shortly, or add an API key in settings."));
            } else if (xhr.status === 429) {
                root.fetchError(Translation.tr("Wallhaven rate limit exceeded, wait a moment and retry."));
            } else if (xhr.status === 401) {
                root.fetchError(Translation.tr("Invalid Wallhaven API key."));
            } else {
                root.fetchError("Wallhaven API error: " + xhr.status);
            }
            if (root._refetchQueued) {
                root._refetchQueued = false;
                root.fetch();
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function _fetchUnsplash() {
        const orientation = "landscape";
        const count       = 24;
        const q           = root.query.length > 0 ? `&query=${encodeURIComponent(root.query)}` : `&query=${encodeURIComponent(root.category)}`;  
        const clientId    = root.unsplashClientId;

        const url = `https://api.unsplash.com/photos/random?orientation=${orientation}&count=${count}${q}&client_id=${clientId}`;

        fetchProc.provider = "unsplash";
        fetchProc.command = ["curl", "-s", url];
        fetchProc.running = true;
    }

    function _fetchPexels() {
        const q = root.query.length > 0 ? root.query : "wallpaper landscape";
        const url = `https://api.pexels.com/v1/search?query=${encodeURIComponent(q)}&per_page=24&page=${root.page}`;
        fetchProc.provider = "pexels";
        fetchProc.command  = ["curl", "-s", "-H", `Authorization: ${root.pexelsApiKey}`, url];
        fetchProc.running  = true;
    }

    // A challenge/error page (Cloudflare 503, 5xx, rate-limit) arrives as HTML, so
    // JSON.parse would throw a cryptic SyntaxError. Detect it and report plainly.
    function _looksLikeHtml(body) {
        // trimStart() is ES2019 and missing from Qt's QML engine
        return /^\s*</.test(body);
    }

    function _parseWallhaven(jsonStr) {
        if (root._looksLikeHtml(jsonStr)) {
            root.fetchError(Translation.tr("Wallhaven is temporarily unavailable (server busy or blocked). Try again shortly, or add an API key in settings."));
            return;
        }
        try {
            const data = JSON.parse(jsonStr);
            if (data.meta?.seed && root.seed.length === 0) {
                root.seed = data.meta.seed;
            }
            root.totalPages = data.meta?.last_page ?? 0
            const newItems = data.data.map(item => ({
                id:               item.id,
                thumb:            item.thumbs.large,
                full:             item.path,
                provider:         "wallhaven",
                title:            "",
                author:           "",
                authorUrl:        "",
                likes:            0,
                width:            item.dimension_x ?? 0,
                height:           item.dimension_y ?? 0,
                resolution:       item.resolution ?? "",
                downloadLocation: "",
            }));
            root.results = root.appending ? root.results.concat(newItems) : newItems;
            root.fetched();
        } catch (e) {
            root.fetchError("Wallhaven parse error: " + e);
        }
    }

    function _parseUnsplash(jsonStr) {
        try {
            const data = JSON.parse(jsonStr);
            const resSuffix = root.resolutionMap["unsplash"][root.resolution] ?? "&w=1920&h=1080&fit=crop";

            const newItems = data.map(item => ({
                id:               item.id,
                thumb:            item.urls.small,
                full: item.urls.raw + (root.resolution === "4K" ? "&w=3840&h=2160&fit=crop&fm=jpg&q=85"
                    : root.resolution === "2K" ? "&w=2560&h=1440&fit=crop&fm=jpg&q=85"
                    : "&w=1920&h=1080&fit=crop&fm=jpg&q=85"),
                provider:         "unsplash",
                title:            item.alt_description ?? item.description ?? "",
                author:           item.user?.name ?? "",
                authorUrl:        item.user?.links?.html ?? "",
                likes:            item.likes ?? 0,
                width:            item.width ?? 0,
                height:           item.height ?? 0,
                downloadLocation: item.links?.download_location ?? "",
            }));

            root.results = root.appending ? root.results.concat(newItems) : newItems;
            root.fetched();
        } catch (e) {
            root.fetchError("Unsplash parse error: " + e);
        }
    }

    function _parsePexels(jsonStr) {
        try {
            const data = JSON.parse(jsonStr);
            const resSuffix = root.resolutionMap["pexels"][root.resolution] ?? "&w=1920&h=1080&fit=crop";

            root.totalPages = Math.ceil((data.total_results ?? 0) / 24);
            const newItems = data.photos.map(item => ({
                id:               String(item.id),
                thumb:            item.src.large,
                full: root.resolution === "4K" ? item.src.original + "?auto=compress&cs=tinysrgb&w=3840&h=2160&fit=crop"
                    : root.resolution === "2K" ? item.src.original + "?auto=compress&cs=tinysrgb&w=2560&h=1440&fit=crop"
                    :                            item.src.original + "?auto=compress&cs=tinysrgb&w=1920&h=1080&fit=crop",
                provider:         "pexels",
                title:            item.alt ?? "",
                author:           item.photographer ?? "",
                authorUrl:        item.photographer_url ?? "",
                likes:            0,
                width:            item.width ?? 0,
                height:           item.height ?? 0,
                avgColor:         item.avg_color ?? "",
                downloadLocation: "",
            }));

            root.results = root.appending ? root.results.concat(newItems) : newItems;
            root.fetched();
        } catch (e) {
            root.fetchError("Pexels parse error: " + e);
        }
    }

    function _fetchNaive() {
        fetchProc.provider = "naive";
        fetchProc.command = ["curl", "-sL", root.naiveJsonUrl];
        fetchProc.running = true;
    }

    function _parseNaive(jsonStr) {
        try {
            const data = JSON.parse(jsonStr);
            if (!Array.isArray(data)) throw new Error("Unexpected wallpapers.json response");

            const q = root.query.trim().toLowerCase();
            const cg = root.colorGroup.trim().toLowerCase();
            const newItems = data
                .filter(item => item && item.filename)
                .filter(item => q.length === 0 || String(item.filename).toLowerCase().includes(q))
                .filter(item => cg.length === 0 || ((item.color_groups ?? []).map(g => String(g).toLowerCase()).includes(cg)))
                .map(item => {
                    const filename = String(item.filename);
                    const baseName = filename.replace(/\.[^.]+$/, "");
                    const dims = String(item.resolution ?? "").split("x");
                    const w = parseInt(dims[0], 10) || 0;
                    const h = parseInt(dims[1], 10) || 0;
                    return {
                        id:               baseName,
                        thumb:            root.naivePagesBase + String(item.thumbnail ?? item.preview ?? filename),
                        full:             root.naiveFullBase + encodeURIComponent(filename),
                        provider:         "naive",
                        title:            baseName.replace(/[-_]+/g, " ").replace(/\b\w/g, c => c.toUpperCase()),
                        author:           "",
                        authorUrl:        "",
                        likes:            0,
                        width:            w,
                        height:           h,
                        avgColor:         item.color ?? "",
                        colorGroups:      item.color_groups ?? [],
                        downloadLocation: "",
                    };
                });

            root.totalPages = 1;
            root.results = root.appending ? root.results.concat(newItems) : newItems;
            root.fetched();
        } catch (e) {
            root.fetchError("NA-ive parse error: " + e);
        }
    }

    // ─── Process ───
    Process {
        id: fetchProc
        property string provider: ""
        property string buffer:   ""

        onRunningChanged: {
            if (running) buffer = "";
        }

        stdout: SplitParser {
            onRead: data => {
                fetchProc.buffer += data;
            }
        }

        onExited: (exitCode) => {
            root.loading = false;
            if (exitCode !== 0) {
                root.fetchError("curl exited with code " + exitCode);
            } else if (fetchProc.provider === "wallhaven") {
                root._parseWallhaven(fetchProc.buffer);
            } else if (fetchProc.provider === "unsplash") {
                root._parseUnsplash(fetchProc.buffer);
            } else if (fetchProc.provider === "pexels") {
                root._parsePexels(fetchProc.buffer);
            } else if (fetchProc.provider === "naive") {
                root._parseNaive(fetchProc.buffer);
            }
            if (root._refetchQueued) {
                root._refetchQueued = false;
                root.fetch();
            }
        }
    }
}
