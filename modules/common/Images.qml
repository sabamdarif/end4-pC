pragma Singleton

import Quickshell

Singleton {
    // Formats
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg"]
    readonly property list<string> validVideoExtensions: ["mp4", "webm", "mkv", "avi", "mov"]

    function isValidImageByName(name: string): bool {
        if (!name) return false;
        const lower = name.toLowerCase();
        return validImageExtensions.some(t => lower.endsWith(`.${t}`));
    }

    function isVideoByName(name: string): bool {
        if (!name) return false;
        const lower = name.toLowerCase();
        return validVideoExtensions.some(t => lower.endsWith(`.${t}`));
    }

    function isValidMediaByName(name: string): bool {
        return isValidImageByName(name) || isVideoByName(name);
    }

    // Thumbnails
    // https://specifications.freedesktop.org/thumbnail-spec/latest/directory.html
    readonly property var thumbnailSizes: ({
        "normal": 128,
        "large": 256,
        "x-large": 512,
        "xx-large": 1024
    })
    function thumbnailSizeNameForDimensions(width: int, height: int): string {
        const sizeNames = Object.keys(thumbnailSizes);
        for(let i = 0; i < sizeNames.length; i++) {
            const sizeName = sizeNames[i];
            const maxSize = thumbnailSizes[sizeName];
            if (width <= maxSize && height <= maxSize) return sizeName;
        }
        return "xx-large";
    }
}
