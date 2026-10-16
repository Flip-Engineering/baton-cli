// A JS host calling Bend2 defs in process through the compiler's bun
// plugin (bend2/main.ts preloaded). The plugin exposes the module's defs
// under the namespace's `default` export (observed), not as named exports.
import * as Hello from "./hello.bend";

const defs = Hello.default;
console.log("default-export type:", typeof defs);
console.log("default-export keys:", Object.keys(defs).sort().join(", "));
console.log("double(21) =", defs.double(21));
console.log(defs.greet("bend"));
console.log("decide(7) =", JSON.stringify(defs.decide(7)));
console.log("decide(0) =", JSON.stringify(defs.decide(0)));
