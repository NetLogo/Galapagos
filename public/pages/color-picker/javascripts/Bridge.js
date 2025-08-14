(function () {
  document.addEventListener("DOMContentLoaded", () => {
    window.addEventListener("message", (event) => {
      if (event.data.type === "init-baby-monitor") {
        if (event.ports.length === 0) {
          console.error("No port provided for baby monitor communication.");
          return;
        }
        const port = event.ports[0];

        window.nlBabyMonitor = {
          onPick: (str) => {
            port.postMessage({ type: "pick", color: str });
          },
          onCopy: (str) => {
            port.postMessage({ type: "copy", value: str });
            navigator.clipboard.writeText(str).catch((err) => {
              console.error("Failed to copy text: ", err);
            });
          },
          onCancel: () => {
            port.postMessage({ type: "cancel" });
          },
        };

        if (event.data.defaultPicker) {
          switch (event.data.defaultPicker) {
            case "simple":
              /* NOP */
              break;
            case "advanced":
              window.switchToAdvPicker();
              break;
            default:
              console.warn(`Unknown defaultPicker '${event.data.defaultPicker}', defaulting to 'simple'`);
          }
        }

        if (event.data.pickerType) {
          switch (event.data.pickerType) {
            case "num":
              window.useNumberOnlyPicker();
              break;
            case "numAndRGBA":
              window.useNumAndRGBAPicker();
              break;
            default:
              console.warn(`Unknown pickerType '${event.data.pickerType}', defaulting to 'num'`);
              window.useNumberOnlyPicker();
          }
        }

        if (event.data.initialColor) {
          const { typ, value } = event.data.initialColor;
          setValue(typ, value);
        }

      }
    });
  });
})();
