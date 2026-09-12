import { check } from "./check.js";
export default function parseCompositeCheckDigit(checkDigit, ...sources) {
    const source = sources.join('');
    const checkResult = check(source, checkDigit);
    return {
        value: checkDigit,
        ...checkResult,
    };
}
//# sourceMappingURL=parseCompositeCheckDigit.js.map