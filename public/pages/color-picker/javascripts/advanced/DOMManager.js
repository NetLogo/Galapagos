import { findElemByID, findElems, findFirstElem, setInputByID } from "../common/DOM.js";
import { unsafe } from "../common/Util.js";
import { optionValueToContainerID } from "./Util.js";
export class DOMManager {
    constructor(doc) {
        Object.defineProperty(this, "findElemByID", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "findElems", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "findFirstElem", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "setInputByID", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        const pane = findElemByID(doc)("advanced-pane");
        this.findElemByID = findElemByID(doc);
        this.findElems = findElems(pane);
        this.findFirstElem = findFirstElem(pane);
        this.setInputByID = setInputByID(doc);
    }
    findActiveControls() {
        const controls = this.findElems(".repr-controls-container .repr-controls");
        const active = controls.find((c) => c.style.display === "flex");
        return unsafe(active);
    }
    findInputValues() {
        const dropdown = this.findReprDropdown();
        const targetElemID = unsafe(optionValueToContainerID[dropdown.value]);
        const container = this.findElemByID(targetElemID);
        return findElems(container)(".repr-input").map((i) => i.value);
    }
    findOutputDropdown() {
        return this.findElemByID("output-format-dropdown");
    }
    findReprDropdown() {
        return this.findElemByID("repr-dropdown");
    }
}
//# sourceMappingURL=DOMManager.js.map