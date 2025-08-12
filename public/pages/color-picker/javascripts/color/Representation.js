import { colorToRGB, nearestColorNumberOfRGB, rgbToWordPair } from "./ColorModel.js";
import { colorLiterals } from "./ColorLiteral.js";
const round = (x) => Math.round(x * 10) / 10;
const calcHueDegrees = (hue) => round(360 * (hue / 100));
class NLNumber {
    constructor(num) {
        Object.defineProperty(this, "number", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "proxy", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.number = num;
        this.proxy = this.toRGBA();
    }
    equals(x) {
        if ((typeof x) === "object" && "toNLNumber" in x) {
            const other = x.toNLNumber();
            return this.number === other.number;
        }
        else {
            return false;
        }
    }
    toString() {
        return `NLNumber(${this.number})`;
    }
    toNLNumber() {
        return this;
    }
    toNLWord() {
        return this.proxy.toNLWord();
    }
    toRGB() {
        const [r, g, b] = colorToRGB(this.number);
        return new RGB(r, g, b);
    }
    toRGBA() {
        return this.toRGB().toRGBA();
    }
    toHSB() {
        return this.proxy.toHSB();
    }
    toHSBA() {
        return this.proxy.toHSBA();
    }
    toHSL() {
        return this.proxy.toHSL();
    }
    toHSLA() {
        return this.proxy.toHSLA();
    }
    toHexadecimal() {
        return this.proxy.toHexadecimal();
    }
    toGUI_HSLA() {
        return this.proxy.toGUI_HSLA();
    }
    withAlpha(alpha) {
        return this.proxy.withAlpha(alpha);
    }
}
class NLWord {
    constructor(literal, modifier = 0) {
        Object.defineProperty(this, "literal", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "modifier", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "proxy", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.literal = literal;
        this.modifier = modifier;
        this.proxy = this.toRGBA();
    }
    static parse(text) {
        const [word, operator, value] = text.split(" ");
        const matchingLiteral = colorLiterals.find((l) => l.name === word);
        if (matchingLiteral !== undefined) {
            const diff = ((operator !== "+" && operator !== "-") || isNaN(Number(value))) ? 0 :
                (operator === "+") ? Number(value) : -Number(value);
            return new NLWord(matchingLiteral, diff);
        }
        else {
            throw new Error(`Invalid NL color word: ${word}`);
        }
    }
    equals(x) {
        if ((typeof x) === "object" && "toNLWord" in x) {
            const other = x.toNLWord();
            return this.literal === other.literal && this.modifier === other.modifier;
        }
        else {
            return false;
        }
    }
    toString() {
        return `NLWord(${this.toText()})`;
    }
    toNLNumber() {
        return new NLNumber(this.literal.value + this.modifier);
    }
    toNLWord() {
        return this;
    }
    toRGB() {
        return this.proxy.toRGB();
    }
    toRGBA() {
        return this.toNLNumber().toRGBA();
    }
    toHSB() {
        return this.proxy.toHSB();
    }
    toHSBA() {
        return this.proxy.toHSBA();
    }
    toHSL() {
        return this.proxy.toHSL();
    }
    toHSLA() {
        return this.proxy.toHSLA();
    }
    toHexadecimal() {
        return this.proxy.toHexadecimal();
    }
    toGUI_HSLA() {
        return this.proxy.toGUI_HSLA();
    }
    toText() {
        const suffix = (this.modifier === 0) ? "" :
            (() => {
                const sign = (this.modifier > 0) ? "+" : "-";
                const magnitude = Math.abs(this.modifier);
                return ` ${sign} ${magnitude}`;
            })();
        return `${this.literal.name}${suffix}`;
    }
    withAlpha(alpha) {
        return this.proxy.withAlpha(alpha);
    }
}
class RGB {
    constructor(r, g, b) {
        Object.defineProperty(this, "red", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "green", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "blue", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "proxy", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.red = r;
        this.green = g;
        this.blue = b;
        this.proxy = this.toRGBA();
    }
    equals(x) {
        if ((typeof x) === "object" && "toRGB" in x) {
            const other = x.toRGB();
            return this.red === other.red && this.green === other.green && this.blue === other.blue;
        }
        else {
            return false;
        }
    }
    toString() {
        return `RGB(${this.red}, ${this.green}, ${this.blue})`;
    }
    toNLNumber() {
        return new NLNumber(nearestColorNumberOfRGB(this.red, this.green, this.blue));
    }
    toNLWord() {
        const [lit, mod] = rgbToWordPair(this.red, this.green, this.blue);
        return new NLWord(lit, mod);
    }
    toRGB() {
        return this;
    }
    toRGBA() {
        return new RGBA(this.red, this.green, this.blue, 100);
    }
    toHSB() {
        return this.proxy.toHSB();
    }
    toHSBA() {
        return this.proxy.toHSBA();
    }
    toHSL() {
        return this.proxy.toHSL();
    }
    toHSLA() {
        return this.proxy.toHSLA();
    }
    toHexadecimal() {
        return this.proxy.toHexadecimal();
    }
    toGUI_HSLA() {
        return this.proxy.toGUI_HSLA();
    }
    withAlpha(alpha) {
        return this.proxy.withAlpha(alpha);
    }
}
class RGBA {
    constructor(r, g, b, a) {
        Object.defineProperty(this, "red", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "green", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "blue", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "alpha", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.red = r;
        this.green = g;
        this.blue = b;
        this.alpha = a;
    }
    equals(x) {
        if ((typeof x) === "object" && "toRGBA" in x) {
            const other = x.toRGBA();
            return this.red === other.red && this.green === other.green && this.blue === other.blue && this.alpha === other.alpha;
        }
        else {
            return false;
        }
    }
    toString() {
        return `RGBA(${this.red}, ${this.green}, ${this.blue}, ${this.alpha})`;
    }
    toNLNumber() {
        return this.toRGB().toNLNumber();
    }
    toNLWord() {
        return this.toRGB().toNLWord();
    }
    toRGB() {
        return new RGB(this.red, this.green, this.blue);
    }
    toRGBA() {
        return this;
    }
    toHSB() {
        return this.toHSBA().toHSB();
    }
    toHSBA() {
        const rgbToHSB = (red, green, blue) => {
            const rx = red / 255;
            const gx = green / 255;
            const bx = blue / 255;
            const v = Math.max(rx, gx, bx);
            const n = v - Math.min(rx, gx, bx);
            let h = null;
            if (n === 0) {
                h = 0;
            }
            else if (n && v === rx) {
                h = (gx - bx) / n;
            }
            else if (v === gx) {
                h = 2 + (bx - rx) / n;
            }
            else {
                h = 4 + (rx - gx) / n;
            }
            const hue = 60 * ((h < 0) ? (h + 6) : h);
            const saturation = v && (n / v) * 100;
            const brightness = v * 100;
            return [hue, saturation, brightness].map(round);
        };
        const [h, s, b] = rgbToHSB(this.red, this.green, this.blue);
        return new HSBA(h, s, b, this.alpha);
    }
    toHSL() {
        return this.toHSLA().toHSL();
    }
    toHSLA() {
        const rgbToHSL = (red, green, blue) => {
            const rx = red / 255;
            const gx = green / 255;
            const bx = blue / 255;
            const v = Math.max(rx, gx, bx);
            const c = v - Math.min(rx, gx, bx);
            const f = 1 - Math.abs(v + v - c - 1);
            const subH = (c && ((v === rx) ? ((gx - bx) / c) :
                (v === gx) ? (2 + (bx - rx) / c) :
                    (4 + (rx - gx) / c)));
            const hue = 60 * (subH < 0 ? subH + 6 : subH);
            const subS = (f !== 0) ? (c / f) : 0;
            const sat = subS * 100;
            const subL = (v + v - c) / 2;
            const light = subL * 100;
            return [hue, sat, light].map(round);
        };
        const [h, s, l] = rgbToHSL(this.red, this.green, this.blue);
        return new HSLA(h, s, l, this.alpha);
    }
    toHexadecimal() {
        return new Hexadecimal(this.red, this.green, this.blue, this.alpha);
    }
    toGUI_HSLA() {
        return this.toHSLA().toGUI_HSLA();
    }
    withAlpha(alpha) {
        return new RGBA(this.red, this.green, this.blue, alpha);
    }
}
class HSB {
    constructor(h, s, b) {
        Object.defineProperty(this, "hue", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "saturation", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "brightness", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "proxy", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.hue = h;
        this.saturation = s;
        this.brightness = b;
        this.proxy = this.toHSBA();
    }
    equals(x) {
        if ((typeof x) === "object" && "toHSB" in x) {
            const other = x.toHSB();
            return this.hue === other.hue && this.saturation === other.saturation && this.brightness === other.brightness;
        }
        else {
            return false;
        }
    }
    toString() {
        return `HSB(${this.hue}, ${this.saturation}, ${this.brightness})`;
    }
    toNLNumber() {
        return this.proxy.toNLNumber();
    }
    toNLWord() {
        return this.proxy.toNLWord();
    }
    toRGB() {
        return this.proxy.toRGB();
    }
    toRGBA() {
        return this.proxy.toRGBA();
    }
    toHSB() {
        return this;
    }
    toHSBA() {
        return new HSBA(this.hue, this.saturation, this.brightness, 100);
    }
    toHSL() {
        return this.proxy.toHSL();
    }
    toHSLA() {
        return this.proxy.toHSLA();
    }
    toHexadecimal() {
        return this.proxy.toHexadecimal();
    }
    toGUI_HSLA() {
        return this.proxy.toGUI_HSLA();
    }
    withAlpha(alpha) {
        return this.proxy.withAlpha(alpha);
    }
}
class HSBA {
    constructor(h, s, b, a) {
        Object.defineProperty(this, "hue", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "saturation", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "brightness", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "alpha", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.hue = h;
        this.saturation = s;
        this.brightness = b;
        this.alpha = a;
    }
    equals(x) {
        if ((typeof x) === "object" && "toHSBA" in x) {
            const other = x.toHSBA();
            return this.hue === other.hue && this.saturation === other.saturation && this.brightness === other.brightness &&
                this.alpha === other.alpha;
        }
        else {
            return false;
        }
    }
    toString() {
        return `HSBA(${this.hue}, ${this.saturation}, ${this.brightness}, ${this.alpha})`;
    }
    toNLNumber() {
        return this.toRGBA().toNLNumber();
    }
    toNLWord() {
        return this.toRGBA().toNLWord();
    }
    toRGB() {
        return this.toRGBA().toRGB();
    }
    toRGBA() {
        const extract = (n) => {
            const g = (x) => (x + this.hue / 60) % 6;
            const comp = (this.brightness / 100) * (1 - (this.saturation / 100) * Math.max(0, Math.min(g(n), 4 - g(n), 1)));
            return Math.round(255 * comp);
        };
        const red = extract(5);
        const green = extract(3);
        const blue = extract(1);
        return new RGBA(red, green, blue, this.alpha);
    }
    toHSB() {
        return new HSB(this.hue, this.saturation, this.brightness);
    }
    toHSBA() {
        return this;
    }
    toHSL() {
        return this.toHSLA().toHSL();
    }
    toHSLA() {
        const getSLAsHSL = (s, b) => {
            const l = (2 - s / 100) * b / 2;
            const saturation = (l === 0) ? 0 : (s * b / ((l < 50) ? (l * 2) : (200 - (l * 2))));
            const lightness = l;
            return [saturation, lightness].map(round);
        };
        const [s, l] = getSLAsHSL(this.saturation, this.brightness);
        return new HSLA(this.hue, s, l, this.alpha);
    }
    toHexadecimal() {
        return this.toRGBA().toHexadecimal();
    }
    toGUI_HSLA() {
        return this.toHSLA().toGUI_HSLA();
    }
    withAlpha(alpha) {
        return new HSBA(this.hue, this.saturation, this.brightness, alpha);
    }
}
class HSL {
    constructor(h, s, l) {
        Object.defineProperty(this, "hue", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "saturation", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "lightness", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "proxy", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.hue = h;
        this.saturation = s;
        this.lightness = l;
        this.proxy = this.toHSLA();
    }
    equals(x) {
        if ((typeof x) === "object" && "toHSL" in x) {
            const other = x.toHSL();
            return this.hue === other.hue && this.saturation === other.saturation && this.lightness === other.lightness;
        }
        else {
            return false;
        }
    }
    toString() {
        return `HSL(${this.hue}, ${this.saturation}, ${this.lightness})`;
    }
    toNLNumber() {
        return this.proxy.toNLNumber();
    }
    toNLWord() {
        return this.proxy.toNLWord();
    }
    toRGB() {
        return this.proxy.toRGB();
    }
    toRGBA() {
        return this.proxy.toRGBA();
    }
    toHSB() {
        return this.proxy.toHSB();
    }
    toHSBA() {
        return this.proxy.toHSBA();
    }
    toHSL() {
        return this;
    }
    toHSLA() {
        return new HSLA(this.hue, this.saturation, this.lightness, 100);
    }
    toHexadecimal() {
        return this.proxy.toHexadecimal();
    }
    toGUI_HSLA() {
        return this.proxy.toGUI_HSLA();
    }
    withAlpha(alpha) {
        return this.proxy.withAlpha(alpha);
    }
}
class HSLA {
    constructor(h, s, l, a) {
        Object.defineProperty(this, "hue", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "saturation", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "lightness", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "alpha", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.hue = h;
        this.saturation = s;
        this.lightness = l;
        this.alpha = a;
    }
    equals(x) {
        if ((typeof x) === "object" && "toHSLA" in x) {
            const other = x.toHSLA();
            return this.hue === other.hue && this.saturation === other.saturation && this.lightness === other.lightness &&
                this.alpha === other.alpha;
        }
        else {
            return false;
        }
    }
    toString() {
        return `HSLA(${this.hue}, ${this.saturation}, ${this.lightness}, ${this.alpha})`;
    }
    toNLNumber() {
        return this.toRGBA().toNLNumber();
    }
    toNLWord() {
        return this.toRGBA().toNLWord();
    }
    toRGB() {
        return this.toRGBA().toRGB();
    }
    toRGBA() {
        const asRGB = (hue, saturation, lightness) => {
            const l = lightness / 100;
            const a = (saturation / 100) * Math.min(l, 1 - l);
            const morph = (n) => {
                const k = (n + hue / 30) % 12;
                const value = l - (a * Math.max(-1, Math.min(k - 3, 9 - k, 1)));
                return Math.round(value * 255);
            };
            return [morph(0), morph(8), morph(4)];
        };
        const [r, g, b] = asRGB(this.hue, this.saturation, this.lightness);
        return new RGBA(r, g, b, this.alpha);
    }
    toHSB() {
        const hsba = this.toHSBA();
        return new HSB(hsba.hue, hsba.saturation, hsba.brightness);
    }
    toHSBA() {
        const getSBAsHSB = (s, l) => {
            const temp = s * ((l < 50) ? l : (100 - l)) / 100;
            const semiB = l + temp;
            const hsbS = (semiB !== 0) ? round(200 * temp / semiB) : 0;
            const hsbB = round(semiB);
            return [hsbS, hsbB];
        };
        const [s, b] = getSBAsHSB(this.saturation, this.lightness);
        return new HSBA(this.hue, s, b, this.alpha);
    }
    toHSL() {
        return new HSL(this.hue, this.saturation, this.lightness);
    }
    toHSLA() {
        return this;
    }
    toHexadecimal() {
        return this.toRGBA().toHexadecimal();
    }
    toGUI_HSLA() {
        const scalingFactor = 1 + (this.saturation / 100);
        const y = 100 - Math.min(100, this.lightness * scalingFactor);
        const h = this.hue / 360 * 100;
        return new GUI_HSLA(h, this.saturation, y, this.alpha);
    }
    withAlpha(alpha) {
        return new HSLA(this.hue, this.saturation, this.lightness, alpha);
    }
}
class Hexadecimal {
    constructor(red, green, blue, alpha) {
        Object.defineProperty(this, "red", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "green", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "blue", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "alpha", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "proxy", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.red = red;
        this.green = green;
        this.blue = blue;
        this.alpha = alpha;
        this.proxy = new RGBA(red, green, blue, alpha);
    }
    static parse(hexStr) {
        const hex = hexStr.slice(1);
        if (hex.length === 6 || hex.length === 8) {
            const [red, green, blue, a] = [0, 2, 4, 6].map((n) => parseInt(hex.slice(n, n + 2), 16));
            const alpha = (!isNaN(a)) ? Math.round(a / 255 * 100) : 100;
            return new Hexadecimal(red, green, blue, alpha);
        }
        else {
            throw new Error(`Unparseable hexadecimal: ${hexStr}`);
        }
    }
    hex() {
        const hex = (x) => x.toString(16).padStart(2, "0");
        const rgba = this.toRGBA();
        const alpha = (rgba.alpha < 100) ? hex(Math.round(rgba.alpha / 100 * 255)) : "";
        return `#${hex(rgba.red)}${hex(rgba.green)}${hex(rgba.blue)}${alpha}`;
    }
    equals(x) {
        if ((typeof x) === "object" && "toHexadecimal" in x) {
            const other = x.toHexadecimal();
            return this.red === other.red && this.green === other.green && this.blue === other.blue && this.alpha === other.alpha;
        }
        else {
            return false;
        }
    }
    toString() {
        return `Hexadecimal(${this.hex()})`;
    }
    toNLNumber() {
        return this.proxy.toNLNumber();
    }
    toNLWord() {
        return this.proxy.toNLWord();
    }
    toRGB() {
        return this.proxy.toRGB();
    }
    toRGBA() {
        return this.proxy;
    }
    toHSB() {
        return this.proxy.toHSB();
    }
    toHSBA() {
        return this.proxy.toHSBA();
    }
    toHSL() {
        return this.proxy.toHSL();
    }
    toHSLA() {
        return this.proxy.toHSLA();
    }
    toHexadecimal() {
        return this;
    }
    toGUI_HSLA() {
        return this.proxy.toGUI_HSLA();
    }
    withAlpha(alpha) {
        return this.proxy.withAlpha(alpha);
    }
}
class GUI_HSLA {
    constructor(h, s, l, a) {
        Object.defineProperty(this, "hue", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "saturation", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "lightness", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "alpha", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "proxy", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.hue = h;
        this.saturation = s;
        this.lightness = l;
        this.alpha = a;
        this.proxy = this.toHSLA();
    }
    equals(x) {
        if ((typeof x) === "object" && "toGUI_HSLA" in x) {
            const other = x.toGUI_HSLA();
            return this.hue === other.hue && this.saturation === other.saturation && this.lightness === other.lightness &&
                this.alpha === other.alpha;
        }
        else {
            return false;
        }
    }
    toString() {
        return `GUI_HSLA(${this.hue}, ${this.saturation}, ${this.lightness}, ${this.alpha})`;
    }
    toNLNumber() {
        return this.proxy.toNLNumber();
    }
    toNLWord() {
        return this.proxy.toNLWord();
    }
    toRGB() {
        return this.proxy.toRGB();
    }
    toRGBA() {
        return this.proxy.toRGBA();
    }
    toHSB() {
        return this.proxy.toHSB();
    }
    toHSBA() {
        return this.proxy.toHSBA();
    }
    toHSL() {
        return this.proxy.toHSL();
    }
    toHSLA() {
        const hue = calcHueDegrees(this.hue);
        const saturation = this.saturation;
        const mult = 100 - this.lightness;
        const scalingFactor = 1 + (this.saturation / 100);
        const lightness = mult / scalingFactor;
        const alpha = this.alpha;
        return new HSLA(hue, saturation, lightness, alpha);
    }
    toHexadecimal() {
        return this.proxy.toHexadecimal();
    }
    toGUI_HSLA() {
        return this;
    }
    withHue(hue) {
        return new GUI_HSLA(hue, this.saturation, this.lightness, this.alpha);
    }
    withSaturation(saturation) {
        return new GUI_HSLA(this.hue, saturation, this.lightness, this.alpha);
    }
    withLightness(lightness) {
        return new GUI_HSLA(this.hue, this.saturation, lightness, this.alpha);
    }
    withAlpha(alpha) {
        return new GUI_HSLA(this.hue, this.saturation, this.lightness, alpha);
    }
}
export { calcHueDegrees, GUI_HSLA, NLNumber, NLWord, RGB, RGBA, HSB, HSBA, HSL, HSLA, Hexadecimal };
//# sourceMappingURL=Representation.js.map