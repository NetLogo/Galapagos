import { findElemByID, findElems, findFirstElem } from "./common/DOM.js";
import { unsafe } from "./common/Util.js";
import { OutputType } from "./advanced/OutputType.js";
import { Picker } from "./advanced/Picker.js";
import * as Repr from "./color/Representation.js";
import { applyTheme } from "./ColorTheme.js";
import { SimpleSwatch } from "./SimpleSwatch.js";
const { NLNumber, NLWord, RGBA } = OutputType;
const SIMPLE_TAB_ID = "simple-tab";
const ADVANCED_TAB_ID = "advanced-tab";
var hasInitialized = false;
const setUpTabListener = (tabID, contentID) => {
    findElemByID(document)(tabID).addEventListener("click", (e) => {
        const prevID = findFirstElem(document)("#tab-strip .tab-button.selected").id;
        if (hasInitialized && tabID !== prevID) {
            switch (tabID) {
                case SIMPLE_TAB_ID: {
                    if (prevID === ADVANCED_TAB_ID) {
                        const value = window.advanced.getNLNumberValue();
                        window.simple.setColor(value);
                    }
                    else {
                        throw new Error(`But what non-simple tab is '${prevID}'?`);
                    }
                    break;
                }
                case ADVANCED_TAB_ID: {
                    if (prevID === SIMPLE_TAB_ID) {
                        const value = window.simple.getNLNumberValue();
                        const repr = new Repr.NLNumber(value);
                        window.advanced.setRepr(repr);
                    }
                    else {
                        throw new Error(`But what non-advanced tab is '${prevID}'?`);
                    }
                    break;
                }
                default: {
                    throw new Error(`Which tab is this?  ${tabID}`);
                }
            }
        }
        findElems(document)("#tab-strip .tab-button").forEach((tb) => tb.classList.remove("selected"));
        e.target.classList.add("selected");
        findElems(document)("#content-pane .pane").forEach((p) => p.classList.add("hidden"));
        findElemByID(document)(contentID).classList.remove("hidden");
    });
};
const instantiateTemplates = (doc) => {
    const outputsTemplate = (findElemByID(doc)("outputs-template")).content;
    Array.from(findElems(doc)(".outputs-placeholder")).forEach((placeholder) => {
        const outputs = outputsTemplate.cloneNode(true);
        unsafe(placeholder.parentNode).replaceChild(outputs, placeholder);
    });
};
window.addEventListener("load", () => {
    const platform = navigator.platform;
    if (platform === "MacIntel" || platform.startsWith("iPad") || platform.startsWith("iPhone")) {
        document.body.classList.add("apple2025");
    }
    window.nlBabyMonitor = {
        onPick: (_) => { return; },
        onCopy: (s) => { navigator.clipboard.writeText(s); },
        onCancel: () => { return; }
    };
    setUpTabListener(SIMPLE_TAB_ID, "simple-pane");
    setUpTabListener(ADVANCED_TAB_ID, "advanced-pane");
    instantiateTemplates(document);
    window.simple = new SimpleSwatch(document);
    window.advanced = new Picker(document, new Set([]));
    findElemByID(document)("pick-button").addEventListener("click", (_) => {
        window.nlBabyMonitor.onPick(getOutputValue(false));
    });
    findElemByID(document)("cancel-button").addEventListener("click", (_) => {
        window.nlBabyMonitor.onCancel();
    });
    Array.from(findElems(document)(".copy-button")).forEach((btn) => {
        var isChilling = false;
        btn.addEventListener("click", () => {
            if (!isChilling) {
                btn.classList.add("on-cooldown");
                isChilling = true;
                setTimeout(() => {
                    btn.classList.remove("on-cooldown");
                    isChilling = false;
                }, 1200);
                window.nlBabyMonitor.onCopy(getOutputValue(true));
            }
        });
    });
    window.syncTheme({});
    hasInitialized = true;
});
window.injectCSS = (css) => {
    const elem = document.createElement("style");
    elem.textContent = css;
    document.head.append(elem);
};
window.useNumberOnlyPicker = () => {
    window.advanced = new Picker(document, new Set([NLNumber]));
};
window.useNonPickPicker = () => {
    findElemByID(document)("pick-button").classList.add("hidden");
    window.advanced = new Picker(document, new Set([NLNumber, NLWord, RGBA]));
};
window.useNumAndRGBAPicker = () => {
    window.advanced = new Picker(document, new Set([NLNumber, RGBA]));
};
window.setValue = (typ, value) => {
    let repr = undefined;
    if (typ === "number") {
        repr = new Repr.NLNumber(value);
    }
    else if (typ === "rgb") {
        const { red, green, blue } = value;
        repr = new Repr.RGB(red, green, blue);
    }
    else if (typ === "rgba") {
        const { red, green, blue, alpha } = value;
        repr = new Repr.RGBA(red, green, blue, alpha);
    }
    else {
        throw new Error(`Unknown value type: ${value}`);
    }
    window.simple.setColor(repr.toNLNumber().number);
    window.advanced.setRepr(repr);
};
window.switchToAdvPicker = () => {
    unsafe(document.getElementById(ADVANCED_TAB_ID)).click();
};
window.syncTheme = (config) => {
    applyTheme(config, document.body);
};
const getOutputValue = (isClipboard) => {
    const selected = findFirstElem(document)("#tab-strip .tab-button.selected");
    switch (selected.id) {
        case SIMPLE_TAB_ID:
            return window.simple.getOutputValue(isClipboard);
        case ADVANCED_TAB_ID:
            return window.advanced.getOutputValue(isClipboard);
        default:
            throw new Error(`Unknown picker type tab ID: ${selected.id}`);
    }
};
//# sourceMappingURL=Main.js.map