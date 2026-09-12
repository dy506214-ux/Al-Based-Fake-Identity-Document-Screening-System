import { check } from "./check.js";
export default function parseCheckDigit(checkDigit, value) {
    return {
        value: checkDigit,
        ...check(value, checkDigit),
    };
}
//# sourceMappingURL=parseDateCheckDigit.js.map