const defaultTheme = { dialogBackground: "rgb(238, 238, 238)",
    dialogText: "black",
    tabBackground: "white",
    tabBackgroundHover: "#d3d3d3",
    tabBackgroundSelected: "rgb(6, 112, 237)",
    tabBorder: "rgb(175, 175, 175)",
    tabText: "black",
    tabTextSelected: "white",
    controlBackground: "white",
    controlBackgroundActive: "#0091ff",
    controlBackgroundHover: "#d3d3d3",
    controlBorder: "black",
    controlText: "black",
    dropdownArrow: "black",
    genericBorder: "#808080",
    outputBackground: "#7d7d7d",
    checkmarkColor: "#3eb84f",
    copyHover: "#c5c5c5",
    okButtonBackground: "rgb(6, 112, 237)",
    okButtonBackgroundHover: "rgb(0, 92, 217)",
    okButtonBorder: "rgb(6, 112, 237)",
    okButtonText: "white",
    okButtonActive: "rgb(0, 72, 197)",
    cancelButtonBackground: "white",
    cancelButtonBackgroundHover: "rgb(245, 245, 245)",
    cancelButtonBorder: "rgb(175, 175, 175)",
    cancelButtonText: "black",
    cancelButtonActive: "rgb(215, 215, 215)"
};
const applyTheme = (theme, element) => {
    const t = { ...defaultTheme, ...theme };
    const set = (k, v) => element.style.setProperty(k, v);
    set("--dialog-background", t.dialogBackground);
    set("--dialog-text", t.dialogText);
    set("--tab-background", t.tabBackground);
    set("--tab-background-hover", t.tabBackgroundHover);
    set("--tab-background-selected", t.tabBackgroundSelected);
    set("--tab-border", t.tabBorder);
    set("--tab-text", t.tabText);
    set("--tab-text-selected", t.tabTextSelected);
    set("--control-background", t.controlBackground);
    set("--control-background-active", t.controlBackgroundActive);
    set("--control-background-hover", t.controlBackgroundHover);
    set("--control-border", t.controlBorder);
    set("--control-text", t.controlText);
    set("--dropdown-arrow", t.dropdownArrow);
    set("--generic-border", t.genericBorder);
    set("--output-background", t.outputBackground);
    set("--checkmark-color", t.checkmarkColor);
    set("--copy-hover", t.copyHover);
    set("--ok-button-background", t.okButtonBackground);
    set("--ok-button-background-hover", t.okButtonBackgroundHover);
    set("--ok-button-border", t.okButtonBorder);
    set("--ok-button-text", t.okButtonText);
    set("--ok-button-active", t.okButtonActive);
    set("--cancel-button-background", t.cancelButtonBackground);
    set("--cancel-button-background-hover", t.cancelButtonBackgroundHover);
    set("--cancel-button-border", t.cancelButtonBorder);
    set("--cancel-button-text", t.cancelButtonText);
    set("--cancel-button-active", t.cancelButtonActive);
};
export { applyTheme };
//# sourceMappingURL=ColorTheme.js.map