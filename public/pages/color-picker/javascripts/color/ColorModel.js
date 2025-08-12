import { Black, ColorLiteral, colorLiterals, Gray, White } from "./ColorLiteral.js";
import { unsafe } from "../common/Util.js";
const nlNumberToLiteral = (() => {
    const mappings = colorLiterals.flatMap((cl) => {
        const v = cl.value;
        if (![White, Black, Gray].includes(cl)) {
            return [[v - 5, Black], [v, cl], [v + 4.9, White]];
        }
        else {
            return [[v, cl]];
        }
    });
    return Object.fromEntries(mappings);
})();
const rgbToWordPair = (r, g, b) => {
    const colorNumber = nearestColorNumberOfRGB(r, g, b);
    if (nlNumberToLiteral.hasOwnProperty(colorNumber)) {
        const literal = unsafe(nlNumberToLiteral[colorNumber]);
        return [literal, 0];
    }
    else {
        const literals = colorLiterals.filter((x) => x !== Black && x !== White);
        const nearestLiteral = literals.reduce((acc, l) => Math.abs(colorNumber - l.value) < Math.abs(colorNumber - acc.value) ? l : acc, new ColorLiteral("nonsense", 1e9));
        const modifier = Math.round((colorNumber - nearestLiteral.value) * 10) / 10;
        return [nearestLiteral, modifier];
    }
};
const colorToRGB = (c) => window.NLColorModel.colorToRGB(c);
const nearestColorNumberOfRGB = (r, g, b) => window.NLColorModel.nearestColorNumberOfRGB(r, g, b);
export { ColorLiteral, colorToRGB, nearestColorNumberOfRGB, rgbToWordPair };
//# sourceMappingURL=ColorModel.js.map