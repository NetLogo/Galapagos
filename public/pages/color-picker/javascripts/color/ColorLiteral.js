class ColorLiteral {
    constructor(name, value) {
        Object.defineProperty(this, "name", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "value", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        this.name = name;
        this.value = value;
    }
}
const Black = new ColorLiteral("black", 0);
const White = new ColorLiteral("white", 9.9);
const Gray = new ColorLiteral("gray", 5);
const Red = new ColorLiteral("red", 15);
const Orange = new ColorLiteral("orange", 25);
const Brown = new ColorLiteral("brown", 35);
const Yellow = new ColorLiteral("yellow", 45);
const Green = new ColorLiteral("green", 55);
const Lime = new ColorLiteral("lime", 65);
const Turquoise = new ColorLiteral("turquoise", 75);
const Cyan = new ColorLiteral("cyan", 85);
const Sky = new ColorLiteral("sky", 95);
const Blue = new ColorLiteral("blue", 105);
const Violet = new ColorLiteral("violet", 115);
const Magenta = new ColorLiteral("magenta", 125);
const Pink = new ColorLiteral("pink", 135);
const colorLiterals = [Black, White, Gray, Red, Orange, Brown, Yellow, Green, Lime, Turquoise, Cyan, Sky, Blue, Violet, Magenta, Pink];
export { Black, Blue, Brown, ColorLiteral, colorLiterals, Cyan, Gray, Green, Lime, Magenta, Orange, Pink, Red, Sky, Turquoise, Violet, White, Yellow };
//# sourceMappingURL=ColorLiteral.js.map