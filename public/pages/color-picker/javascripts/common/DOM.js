import { unsafe } from "./Util.js";
const findElemByID = (doc) => (id) => {
    return unsafe(doc.getElementById(id));
};
const findElems = (container) => (selector) => {
    return Array.from(container.querySelectorAll(selector));
};
const findFirstElem = (container) => (selector) => {
    return findElems(container)(selector)[0];
};
const setInput = (elem) => (value) => {
    elem.value = value.toString();
};
const setInputByID = (doc) => (id, value) => {
    setInput(findElemByID(doc)(id))(value);
};
export { findElemByID, findElems, findFirstElem, setInput, setInputByID };
//# sourceMappingURL=DOM.js.map