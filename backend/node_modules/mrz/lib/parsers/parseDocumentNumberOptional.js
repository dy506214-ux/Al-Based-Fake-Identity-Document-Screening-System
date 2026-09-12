import { parseText } from "./parseText.js";
export function parseDocumentNumberOptional(optional) {
    const value = parseText(optional, 0);
    return {
        value,
        start: 0,
        end: value.length,
    };
}
//# sourceMappingURL=parseDocumentNumberOptional.js.map