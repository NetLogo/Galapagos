const switchMap = (target, map, orElse) => {
    return map.has(target) ? unsafe(map.get(target)) : orElse(target);
};
const unsafe = (x) => x;
export { switchMap, unsafe };
//# sourceMappingURL=Util.js.map