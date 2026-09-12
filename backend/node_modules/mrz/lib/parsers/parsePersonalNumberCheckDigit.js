import { check } from "./check.js";
import { cleanText } from "./cleanText.js";
export function parsePersonalNumberCheckDigit(checkDigit, personalNumber) {
    const cleanNumber = cleanText(personalNumber);
    if (cleanNumber === '') {
        if (checkDigit !== '<' && checkDigit !== '0') {
            return {
                value: checkDigit,
                valid: false,
                error: `invalid check digit ${checkDigit}: must be 0 or <`,
            };
        }
        else {
            return checkDigit;
        }
    }
    return {
        value: checkDigit,
        ...check(personalNumber, checkDigit),
    };
}
//# sourceMappingURL=parsePersonalNumberCheckDigit.js.map