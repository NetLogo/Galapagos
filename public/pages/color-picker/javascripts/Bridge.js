(function () {
  document.addEventListener("DOMContentLoaded", () => {
    window.addEventListener("message", (event) => {
      if (event.data.type === "init-baby-monitor") {
        if (event.ports.length === 0) {
          console.error("No port provided for baby monitor communication.");
          return;
        }
        const port = event.ports[0];

        const parseColor = (str) => {
          if (str.startsWith("[") && str.endsWith("]")) {
            const parts = str.slice(1, -1).split(" ").map((s) => s.trim());
            const nums = parts.map((p) => parseFloat(p));
            if (nums.length === 4) {
              return { rgb: nums.slice(0, 3), alpha: nums[3] };
            } else if (nums.length === 3) {
              return { rgb: nums, alpha: 255 };
            } else if (nums.length === 1) {
              return { num: nums[0] };
            }
          } else if (!isNaN(parseFloat(str))) {
            return { num: parseFloat(str) };
          }
          return null;
        };

        window.nlBabyMonitor = {
          onPick: (str) => {
            port.postMessage({ type: "pick", color: str, ...parseColor(str) });
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

        if (event.data.initialColor) {
          const { typ, value } = event.data.initialColor;
          setValue(typ, value);
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
      }
    });
  });
})();
