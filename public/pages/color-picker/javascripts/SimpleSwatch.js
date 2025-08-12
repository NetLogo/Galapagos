import { colorToRGB } from "./color/ColorModel.js";
import { NLNumber } from "./color/Representation.js";
import { findElemByID, findElems, findFirstElem } from "./common/DOM.js";
import { unsafe } from "./common/Util.js";
export class SimpleSwatch {
    constructor(doc) {
        Object.defineProperty(this, "color", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "pane", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.color = new NLNumber(0);
        this.pane = findElemByID(doc)("simple-pane");
        const nums = [...Array(11 * 14).keys()].map((x) => {
            if (x <= 139) {
                return x;
            }
            else {
                const overflow = x - 140;
                return (overflow * 10) + 9.9;
            }
        }).sort((x, y) => x - y);
        nums.forEach((num) => {
            const [r, g, b] = (num % 10 === 0) ? [0, 0, 0] : (Math.floor(num) !== num) ? [255, 255, 255] : colorToRGB(num);
            const rgbCSS = `rgb(${r}, ${g}, ${b})`;
            const isDark = (num - Math.floor(num / 10) * 10) < 4;
            let div = doc.createElement("div");
            div.classList.add("swatch-color");
            div.classList.add(isDark ? "dark" : "light");
            if (rgbCSS === "rgb(255, 255, 255)") {
                div.classList.add("white");
            }
            div.style.cssText = `background-color: ${rgbCSS}; border-color: ${rgbCSS};`;
            div.onclick = () => {
                this.color = new NLNumber(num);
                findFirstElem(this.pane)(".output-field").value = this.color.toNLWord().toText();
                Array.from(this.pane.querySelectorAll(".swatch-color.selected")).forEach((sc) => sc.classList.remove("selected"));
                div.classList.add("selected");
            };
            div.dataset["color_num"] = (num * 10).toString();
            unsafe(this.pane.querySelector(".swatches")).append(div);
        });
        this.setColor(0);
    }
    getNLNumberValue() {
        return this.color.number;
    }
    getOutputValue(isCopy) {
        if (isCopy) {
            const word = findFirstElem(this.pane)(".output-field").value;
            const isLiteral = !word.includes(" ");
            return isLiteral ? word : `(${word})`;
        }
        else {
            return this.getNLNumberValue().toString();
        }
    }
    setColor(num) {
        const amped = Math.round(num * 10);
        const elems = findElems(this.pane)(".swatch-color");
        const closestDiv = elems.slice(1).reduce((best, elem) => {
            const bestDist = Math.abs(amped - parseInt(unsafe(best.dataset["color_num"])));
            const elemDist = Math.abs(amped - parseInt(unsafe(elem.dataset["color_num"])));
            const isBetter = elemDist < bestDist;
            return isBetter ? elem : best;
        }, unsafe(elems[0]));
        closestDiv.click();
    }
}
//# sourceMappingURL=SimpleSwatch.js.map