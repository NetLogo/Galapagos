import { calcHueDegrees, GUI_HSLA } from "../color/Representation.js";
import { switchMap, unsafe } from "../common/Util.js";
import { DOMManager } from "./DOMManager.js";
import { DragManager } from "./DragManager.js";
import { OutputType } from "./OutputType.js";
import { ReadsReprFromInputs } from "./ReadsReprFromInputs.js";
import { WritesReprToInputs } from "./WritesReprToInputs.js";
import { clamp, optionValueToContainerID, outputTypeToHTMLValue } from "./Util.js";
const reprHasAlpha = (repr) => ["hsba", "hsla", "rgba", "hex"].includes(repr);
export class Picker {
    constructor(doc, outputTypes) {
        Object.defineProperty(this, "dom", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "repr", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "reprReader", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "reprWriter", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.dom = new DOMManager(doc);
        this.repr = new GUI_HSLA(0, 0, 0, 0);
        this.reprReader = new ReadsReprFromInputs();
        this.reprWriter = new WritesReprToInputs();
        const outputDropdown = this.dom.findOutputDropdown();
        outputDropdown.addEventListener("change", () => this.updateOutputControl());
        this.activateOutputs(outputTypes);
        const reprDropdown = this.dom.findReprDropdown();
        reprDropdown.addEventListener("change", () => this.updateReprControls());
        reprDropdown.value = "nl-number";
        this.updateReprControls();
        this.setHue(60);
        this.setSwatchCoords(75, 20);
        this.setAlpha(100);
        Array.from(this.dom.findElems(".repr-input")).forEach((input) => {
            input.addEventListener("change", () => this.reprReader.read(this.dom, (x) => this.setRepr(x)));
        });
        const dragMan = new DragManager();
        dragMan.setupDrag2D(this.dom.findElemByID("swatch-container"), doc, (x, y) => this.setSwatchCoords(x, y));
        dragMan.setupDrag1DY(this.dom.findElemByID("alpha-slider"), doc, (a) => this.setAlpha(a));
        dragMan.setupDrag1DY(this.dom.findElemByID("hue-slider"), doc, (h) => this.setHue(h));
    }
    setAlpha(alpha) {
        const clamped = clamp(alpha);
        this.repr = this.repr.withAlpha(clamped);
        this.dom.findElemByID("alpha-knob").style.bottom = `${clamped.toFixed(2)}%`;
        this.updateColor();
    }
    setHue(hueY) {
        const clamped = clamp(hueY);
        this.repr = this.repr.toGUI_HSLA().withHue(clamped);
        this.dom.findElemByID("hue-knob").style.bottom = `${clamped.toFixed(2)}%`;
        this.dom.findElemByID("swatch-gradient").style.background = `hsla(${calcHueDegrees(hueY)}deg, 100%, 50%, 100%)`;
        this.updateColor();
        this.updateAlphaGradient();
    }
    setSwatchCoords(x, y) {
        const clampedX = clamp(x);
        const clampedY = clamp(y);
        this.repr = this.repr.toGUI_HSLA().withSaturation(clampedX).withLightness(clampedY);
        const swatchPointer = this.dom.findElemByID("swatch-pointer");
        swatchPointer.style.left = `${clampedX.toFixed(2)}%`;
        swatchPointer.style.top = `${clampedY.toFixed(2)}%`;
        this.updateColor();
        this.updateAlphaGradient();
    }
    setRepr(repr) {
        this.repr = repr;
        const hsla = repr.toGUI_HSLA();
        this.setHue(hsla.hue);
        this.setSwatchCoords(hsla.saturation, hsla.lightness);
        this.setAlpha(hsla.alpha);
    }
    updateColor() {
        const hsla = this.repr.toHSLA();
        const hslStr = `${hsla.hue}deg, ${hsla.saturation}%, ${hsla.lightness}%`;
        this.dom.findElemByID("preview-color-opaque").style.background = `hsl(${hslStr})`;
        this.dom.findElemByID("preview-color-transparent").style.background = `hsla(${hslStr}, ${hsla.alpha}%)`;
        this.reprWriter.write(this.dom, this.repr);
        this.updateOutput();
    }
    updateOutputControl() {
        this.updateAlphaVis();
        this.updateOutput();
    }
    updateOutput() {
        this.dom.findFirstElem(".output-field").innerText = this.getOutputValue(false);
        this.validateControls();
    }
    validateControls() {
        const alpha = this.repr.toGUI_HSLA().alpha;
        const outie = this.dom.findOutputDropdown();
        const outputHasAlpha = reprHasAlpha(outie.value);
        if ((alpha === 100) || outputHasAlpha) {
            outie.classList.remove("alpha-warning");
            outie.title = "";
        }
        else {
            outie.classList.add("alpha-warning");
            outie.title = "You have chosen a color with alpha (transparency), but this output format does not support\
 transparency, so the output color will be entirely opaque.";
        }
    }
    getNLNumberValue() {
        return this.repr.toNLNumber().number;
    }
    getOutputValue(isCopy) {
        const value = unsafe(this.dom.findElemByID("output-format-dropdown").selectedOptions[0]).value;
        const pairs = Array.from(outputTypeToHTMLValue.entries());
        const reversedMap = new Map(pairs.map(([a, b]) => [b, a]));
        const scaleAlpha = (alpha) => Math.round(alpha / 100 * 255);
        switch (reversedMap.get(value)) {
            case OutputType.NLNumber:
                return this.repr.toNLNumber().number.toString();
            case OutputType.NLWord:
                const word = this.repr.toNLWord().toText();
                const isLiteral = !word.includes(" ");
                return (!isCopy || isLiteral) ? word : `(${word})`;
            case OutputType.RGB:
                const rgb = this.repr.toRGB();
                return `(rgb ${rgb.red} ${rgb.green} ${rgb.blue})`;
            case OutputType.RGBA:
                const rgba = this.repr.toRGBA();
                const alpha = scaleAlpha(rgba.alpha);
                const alphaSuffix = (alpha < 255) ? ` ${alpha}` : "";
                return `[${rgba.red} ${rgba.green} ${rgba.blue}${alphaSuffix}]`;
            case OutputType.HSB:
                const hsb = this.repr.toHSB();
                return `(hsb ${hsb.hue} ${hsb.saturation} ${hsb.brightness})`;
            case OutputType.HSBA:
                const hsba = this.repr.toHSBA();
                return `(lput ${scaleAlpha(hsba.alpha)} (hsb ${hsba.hue} ${hsba.saturation} ${hsba.brightness}))`;
            case OutputType.HSL:
                const hsl = this.repr.toHSL();
                return `[${hsl.hue} ${hsl.saturation} ${hsl.lightness}]`;
            case OutputType.HSLA:
                const hsla = this.repr.toHSLA();
                return `[${hsla.hue} ${hsla.saturation} ${hsla.lightness} ${scaleAlpha(hsla.alpha)}]`;
            default:
                throw new Error(`Unknown output value for output format: ${value}`);
        }
    }
    updateAlphaGradient() {
        const { hue, saturation, lightness } = this.repr.toHSL();
        const hslStr = `${hue}, ${saturation}%, ${lightness}%`;
        const elem = this.dom.findFirstElem(".slider-background.alpha");
        elem.style.background = `linear-gradient(to top, hsla(${hslStr}, 0) 0%, hsl(${hslStr}) 100%)`;
    }
    updateReprControls() {
        this.dom.findElems(".repr-controls-container .repr-controls").forEach((c) => { c.style.display = ""; });
        const dropdown = this.dom.findReprDropdown();
        const targetElemID = unsafe(optionValueToContainerID[dropdown.value]);
        this.dom.findElemByID(targetElemID).style.display = "flex";
        this.updateAlphaVis();
        this.updateColor();
    }
    updateAlphaVis() {
        const innie = this.dom.findReprDropdown();
        const outie = this.dom.findOutputDropdown();
        const inputHasAlpha = reprHasAlpha(innie.value);
        const outputHasAlpha = reprHasAlpha(outie.value);
        const alphaWrapper = this.dom.findElemByID("alpha-wrapper");
        if (inputHasAlpha || outputHasAlpha) {
            alphaWrapper.classList.remove("hidden");
        }
        else {
            alphaWrapper.classList.add("hidden");
            this.setAlpha(100);
        }
    }
    activateOutputs(outputTypes) {
        outputTypes.forEach((ot) => {
            const optionValue = switchMap(ot, outputTypeToHTMLValue, (target) => {
                throw new Error(`Impossible output type: ${JSON.stringify(target)}`);
            });
            const elem = this.dom.findFirstElem(`#output-format-dropdown > option[value=${optionValue}]`);
            elem.disabled = false;
            elem.selected = true;
        });
    }
}
//# sourceMappingURL=Picker.js.map