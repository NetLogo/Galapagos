import { OutputType } from "./OutputType.js";
const clamp = (percentage) => Math.max(0, Math.min(100, percentage));
const optionValueToContainerID = { "nl-number": "netlogo-number-controls",
    "nl-word": "netlogo-word-controls",
    "hsb": "hsb-controls",
    "hsba": "hsba-controls",
    "hsl": "hsl-controls",
    "hsla": "hsla-controls",
    "rgb": "rgb-controls",
    "rgba": "rgba-controls",
    "hex": "hex-controls"
};
const outputTypeToHTMLValue = new Map([
    [OutputType.NLNumber, "nl-number"],
    [OutputType.NLWord, "nl-word"],
    [OutputType.RGB, "rgb"],
    [OutputType.RGBA, "rgba"],
    [OutputType.HSB, "hsb"],
    [OutputType.HSBA, "hsba"],
    [OutputType.HSL, "hsl"],
    [OutputType.HSLA, "hsla"]
]);
export { clamp, optionValueToContainerID, outputTypeToHTMLValue };
//# sourceMappingURL=Util.js.map