import { Hexadecimal, HSB, HSBA, HSL, HSLA, NLNumber, NLWord, RGB, RGBA } from "../color/Representation.js";
import { DOMManager } from "./DOMManager.js";
export class ReadsReprFromInputs {
    constructor() { }
    read(dom, setRepr) {
        const dropdown = dom.findReprDropdown();
        const inputValues = dom.findInputValues();
        switch (dropdown.value) {
            case "nl-number": {
                const [colorNumber] = inputValues;
                setRepr(new NLNumber(parseFloat(colorNumber)));
                break;
            }
            case "nl-word": {
                const [colorWord] = inputValues;
                setRepr(NLWord.parse(colorWord));
                break;
            }
            case "hsb": {
                const [hue, saturation, brightness] = inputValues.map((v) => parseInt(v));
                setRepr(new HSB(hue, saturation, brightness));
                break;
            }
            case "hsba": {
                const [hue, saturation, brightness, alpha] = inputValues.map((v) => parseInt(v));
                setRepr(new HSBA(hue, saturation, brightness, alpha));
                break;
            }
            case "hsl": {
                const [hue, saturation, lightness] = inputValues.map((v) => parseInt(v));
                setRepr(new HSL(hue, saturation, lightness));
                break;
            }
            case "hsla": {
                const [hue, saturation, lightness, alpha] = inputValues.map((v) => parseInt(v));
                setRepr(new HSLA(hue, saturation, lightness, alpha));
                break;
            }
            case "rgb": {
                const [red, green, blue] = inputValues.map((v) => parseInt(v));
                setRepr(new RGB(red, green, blue));
                break;
            }
            case "rgba": {
                const [red, green, blue, alpha] = inputValues.map((v) => parseInt(v));
                setRepr(new RGBA(red, green, blue, alpha));
                break;
            }
            case "hex": {
                const [hex] = inputValues;
                setRepr(Hexadecimal.parse(hex));
                break;
            }
            default: {
                alert(`Invalid representation dropdown value: ${dropdown.value}`);
            }
        }
    }
}
//# sourceMappingURL=ReadsReprFromInputs.js.map