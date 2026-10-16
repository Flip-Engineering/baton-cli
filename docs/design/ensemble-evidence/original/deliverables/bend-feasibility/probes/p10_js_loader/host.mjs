// A JS host calling Bend2 defs in process through the compiler's bun
// plugin (bend2/main.ts preloaded). This is the implemented in-process
// evaluation path on the JavaScript side.
import { double, greet, decide } from "./hello.bend";

console.log("double(21) =", double(21));
console.log(greet("bend"));
console.log("decide(7) =", JSON.stringify(decide(7)));
console.log("decide(0) =", JSON.stringify(decide(0)));
