# Bend2 feasibility — independent findings (bend-feasibility)

Assignment: independent recheck of `feasibility-bend2.md` and every
Bend2-dependent claim of the proposal against (a) the actual pinned
toolchain at `postrelease-751-761-20261015-9/toolchain-home` and (b) the
canonical Baton source at `b1f006a6308bbb00e29a24322e4f7d5164774470`.
Method: source reading with file:line citations plus twelve smallest
experiments, all retained under `probes/` with sources, commands, outputs,
and actual exit codes (`probes/README.md` indexes them).

## 0. Verdict

The prior audit's four use-case verdicts **hold at the actual toolchain**
and are now verified on Linux rather than carried over from the Darwin
review: the seat binary and session-log codec are feasible (all needed
host primitives demonstrated through authored C effects: durability p03,
process supervision p05, AF_UNIX mediation p04, dlopen p08); the in-process
program lane and runtime Bend2-module loading remain impossible (no
evaluator to call, imports resolve at check time, one C file per program);
law-gated admission and declarative-tool dispatch are the expressible
self-extension paths (p09, p02). Two corrections to the prior audit's
figure-set, one new capability it under-claimed, and two new constraints
it did not know — all listed below. The root-prepared candidate review
(`review-ready/design-sketch.final-review.md`) is substantially correct on
the feasibility questions; I carry two evidence corrections (§5 checker
verdicts, §5 cost attribution), three additions (4 GiB Base file bound,
global constructor namespace, effect-author NUL contract), and one
superseded-evidence note (its probe-review packet is pre-continuation).

## 1. Toolchain identity (what "the pinned toolchain" actually is)

- `bin/bend` = sh wrapper over `bun 1.3.14 --smol bend2/main.ts`;
  `bend version` → `bend 2.0.25`. `fork-manifest.json` (schema
  `baton-bend-776-smol-diagnostics-v1`): `official_release_artifact: false`,
  `qualification: false` — the compiler running this orchestra is a local
  fork lineage (#741 memoization on comp.ts, #776 opt-in diagnostics), not
  a qualified release. Release qualification is #772's lane.
- Checker (`bend.ts` `93c2a43d…`), Base (`base.bend` `e5639663…`), and CLI
  (`main.ts` `92dcdb49…`) are byte-identical to upstream v2.0.25 release
  sources (`source/bend2/toolchain/bend-2.0.25-baton741/pins.json`). Only
  the C emitter (`comp.ts`) is patched (upstream `ad8b8213…` → `d600b125…`
  → `1956f2e2…`). Consequently the prior audit's *language-level*
  observations transfer; only its emitter-side cost figures needed local
  re-measurement (p11).
- The prior audit's guide hashes match exactly (`GUIDE.md` `9e464364…`,
  `EFFECTS.md` `4d7178c7…`) — the reviewed language documentation is
  unchanged.
- Checker delta vs the audit's `a4952426` vendored copy is 30 diff lines:
  a compile-template instantiation-depth guard (64 levels) plus a 32768
  cap on `~` argument growth. A hardening, not a semantic change. The
  termination checker's "a decreasing self-call" refusal still fires
  first for ordinary self-recursion (p12), and `@unsafe` still exempts.
- The CLI's daily version check performs a network GET unless
  `BEND_NO_TELEMETRY=1` (main.ts:129-162) — measurement hygiene for any
  benchmark lane.

Severity: informational, but any reproducibility contract must name
fork lineage + bun build, not "bend 2.0.25".

## 2. Confirmed by experiment (each with the smallest demonstrable case)

| Claim | Evidence |
| --- | --- |
| Base refuses durability/process/JSON/TLS/HTTP/regex names | p01 (`bend: Base has no File.sync` et al., exit 1) |
| Durability family via authored C effects works on Linux, both lanes | p03: write→fsync→rename→dirfsync→stat "size 9", file content `hello-log`, native and interpreted |
| Child supervision via the audit-era 222-line `process-spawn.c` (canonical commit `bdc234c3`) | p05: streamed `one`/`two`, `exit: exit 0`, stderr captured to file |
| AF_UNIX via authored C effect (Base TCP is `AF_INET` only, `effs/tcp_connect.c` `socket(AF_INET,…)`) | p04: `socket said PONG`, exit 0 |
| Completion-order join over `Chan(U32)`/`IO.fork`; no cancel/select/deadline primitive exists | p07 (join works both lanes); Base inventory p01 (no such names); base.bend:211-255 |
| Law-gated admission: open law in any import fails `--check-only`; `--checkup` checks imports singly | p09 ("Error: 1 TODO found."; `--- ./tool.bend ---` marker) |
| No ring axioms / no tactics: reflexivity fails arithmetic identity | p09 (`- expected : U32.add(U32.add(n, n), U32.add(n, n)) / - observed : U32.mul(n, 4)`) |
| Records forgeable: constructors export with the module | p09 forge (`forged capability released level 999`); corroborated by failure-evaluation's `Lease.Mk{999}` probe |
| Declarative dispatcher on a Data parameter subject is legal and callable repeatedly | p02 (`read: /tmp/x`, `bash: …`, `read: /tmp/y`) |
| `@unsafe` self-recursive state loop is the loop shape | p02 waitloop (3 ticks → done); coordinator's own `run_from` (receive.bend:808-816) uses the same closure-re-entry idiom |
| Runtime C-ABI extension via `dlopen` | p08 (`extension answered 42`) |
| HTTP/1.1 framing + incremental delivery over Base TCP | p06 (chunks arrive as sent, interleaved with server log; exit 0) |
| **JS-side in-process evaluation** (main.ts:1-10; GUIDE.md:378-382) — under-claimed by the prior audit | p10: bun + `--preload main.ts`; defs exported under `default`; `double(21) = 42`; constructors as `{"$":"Some","value":7}` |
| Shape rules, verbatim refusals | p02/p05/p06/p07: "a match heads a def body, not a term" (bend.ts:1855); "a match cannot scrutinize a local binder"; "consumed more than once"; mutual recursion refused ("a defined name: keep/drain/pump/step"); declare-before-use; nested matches in arms legal; `+h : T <- bind` legal in do blocks; `Chan(U32)` is a handle *law*, not a datatype |

## 3. New constraints the prior audit did not record

1. **Base file offsets/sizes are U32; files past 4 GiB fail EOVERFLOW**
   (`effs/file_size.c`: "a file past 4 GiB fails with EOVERFLOW";
   `base.bend:272` `File.read_at(file, offset: U32, max: U32)`). For an
   append-only session log that "never fires" compaction, this is the
   forcing constraint behind segment rotation: a single-file log is
   bounded at 4 GiB by the Base surface. Severity: medium, design-level
   (the candidate review's rotation mechanism absorbs it, but the bound
   should be named).
2. **Constructor names are one global namespace.** `type Step is Data:
   Done{}` collides with Base `Result.Done{}` ("duplicate declaration:
   Done", p02 first attempt). Extension admission that admits constructors
   (or generated programs) needs naming discipline; declarative tools as
   data avoid it. Severity: low-medium for self-extension.
3. **Effect-author ABI fact: `io_cstr`'s length excludes the NUL**
   (`comp.ts:5670-5686`: `buf[n] = 0; *len = n`), and `io_nul(s,n)` is
   `strlen(s) != n` (comp.ts:5692). Effects taking two strings must pack
   the separator themselves — my first rename/dlopen/socket C halves
   failed ENOENT exactly here (fixed; the buggy and fixed outputs are
   both retained in p03/p04/p08 histories). The candidate review's §2
   "pinned effect ABI" should cite this contract explicitly: it is the
   kind of thing every authored effect gets wrong once.
4. **EOF semantics of `TCP.poll`: peer close arrives as `Some{""}`
   (empty string), `None{}` is only the timeout** (p06, first run looped
   19M lines before truncation-with-provenance). A streaming shell or
   SSE reader must treat the empty read as close. Severity: medium for
   any long-lived reader; now demonstrated, not assumed.

## 4. Corrections to the prior feasibility audit

1. Its size reference is stale: "4,484 lines of .bend plus 714 of C" was
   the audit-era coordinator. At `b1f006a6` the coordinator is **43,412
   lines of .bend + 7,897 lines of C** (`src/host/process-spawn.c` alone
   is 5,192). Two readings: (a) the "few thousand lines" seat target
   stays plausible (the coordinator is a superset of seat scope); (b)
   the language demonstrably carries a 43k-line real application —
   which *strengthens* the feasibility verdict. Its emit-cost figure
   (3.0 s) is likewise superseded at scale: the recorded production
   build at this pin took **2101 s emit, 142,651,376 KiB max RSS**
   (`build-result.json`) — large-program emit cost is the real
   packaging constraint, and the #741 fork exists because of it.
2. Its probe-2/4/5/6/8/1 results all reproduce on Linux (p05/p06/p07/
   p08/p09/p03) — the audit's experimental core is sound, not merely
   plausible. Its "-isysroot" Darwin workaround has no Linux analogue
   needed (plain `clang-19 -O1 -pthread`).
3. Its "the in-process API is on the JavaScript side" observation is
   now a demonstrated primitive (p10), which the audit never ran. For
   the program lane this adds a third expressible posture: a bun child
   hosting generated Bend2 defs in-process via the plugin — still
   out-of-process relative to the seat, but with structured (non-text)
   call results. It does not change the verdict that the *seat* cannot
   evaluate generated Bend2 in-process.

## 5. Corrections to the root-prepared candidate review
(`review-ready/design-sketch.final-review.md`, root's candidate, not yet
applied anywhere)

1. **§5 "an interpreter invocation alone carries no checker verdict" —
   contradicted by observation.** `bend x.bend` checks before running
   (GUIDE.md:495 "check; run main"); every interpreted probe here
   refused on checker errors before any execution (p02 first attempts,
   p05/p06/p07 histories), and the reliance report ("N defs rely on
   unsafe or foreign code") prints on interpreted runs (p02/p03/p07).
   The bun-plugin path also checks (p10's first run surfaced the
   checker error through `load_js`). The candidate's own §13 is
   consistent with this; §5's sentence is the error. Suggested
   replacement: "the interpreter lane checks before running and prints
   an @unsafe/foreign reliance report; admission may additionally gate
   on `--check-only` of the program file."
2. **§5 cost attribution:** correct that the 60-110 ms figures are
   Darwin observations; this lane's Linux numbers are check-only
   353 ms / emit 420 ms / link 855 ms / native run 32 ms / interpreted
   409 ms for a trivial program (p11), consistent with the candidate's
   quoted 0.33-0.64 s observations. The candidate should also record
   the large-program anchor (2101 s / 142.7e6 KiB at 43k lines,
   `build-result.json`) next to the trivial-program numbers, because
   the proposal's compile-once promotion path scales with program size.
3. **§2 durability family:** the candidate frames the family as
   "proposed seat guarantees" with signatures unchecked. This lane has
   now executed the full family on the pinned Linux toolchain (p03):
   upgrade to "primitives demonstrated through one authored C half
   (probe p03); the seat's contract remains to be implemented".
4. **§6 extension paths:** add the two constraints from §3 above —
   constructor-namespace collisions (favors declarative-tools-as-data)
   and the executed-bytes/admitted-bytes binding now having a concrete
   failure mode to test (NUL-packing class bugs in effect halves).
5. **§4 observation:** the candidate's "tested Base `Chan.recv`
   signature has no timeout" is confirmed by inventory; this lane adds
   the demonstrated completion-order join (p07) and the TCP EOF-as-
   empty-read finding (p06) as the concrete behaviors a wake/event
   effect must reconcile.

## 6. Diagnostic limits preserved (reboot snapshot vs continuation)

Root's `probe-evidence-review.json` is accurate **for the packet it
reviewed** and its method note ("no probe or compiler was rerun locally")
is why several records are superseded, not wrong: P03's "exit 2" is the
probe's own final unlink-after-rename assertion, not a durability failure
(the family itself succeeded; both lanes); P06/P09/P10 now have captured
outputs reaching their intended assertions (P09's narrower constructor/
law proofs — TODO refusal, checkup markers, reflexivity mismatch — and
the forge case are all captured here, agreeing with failure-evaluation's
independent probes); P04/P11 are captured; P12's wrapper-status mismatch
is fixed (compiler exit captured separately: `bend_exit=0` under
`@unsafe`; the non-`@unsafe` refusal prints "a decreasing self-call").
The original truncated-artifact provenance for P06 is inside its
`output.txt`. Nothing from the original packet was deleted or rewritten.

## 7. Strongest case for the proposal (steelman, from this lane's evidence)

The language is hostile to incidental complexity in ways that serve a
harness: every effect is an explicit, checkable boundary; the loop shape
is forced into one inspectable state machine; admission can be gated by
machine-checked laws; and the entire coordinator — 43k lines of real
orchestration logic — is existence proof that a seat is buildable at a
fraction of that scope. Every hard primitive the design needs (durable
append, supervision, loopback mediation, C-ABI extension, completion
pools) has now been demonstrated end-to-end on the deployment platform
with a toolchain whose checker is byte-identical to upstream. The
proposal's Bend2-dependent claims, once corrected for the evaluator and
loader (out-of-process lane; declarative + law-gated extension), are all
reachable with authored C effects that total a few hundred lines.

## 8. Costs (this host)

Trivial program (p11): check 353 ms; emit C 420 ms; clang link 855 ms;
native run 32 ms; interpreted 409 ms; JS emit 429 ms. At coordinator
scale: emit 2101 s / max RSS 142,651,376 KiB (recorded production build).
Consequence: keep the seat's interpreted lane for one-shot programs,
compile promoted tools, and budget CI time for full-program emits.

## 9. Unresolved / open

- The v2.0.25 template instantiation-depth guard's triggering shape
  (p12: my `@unsafe` self-instantiation checks clean; the guard exists
  in the 30-line checker delta) — low priority, one open probe.
- No confined-child probe (same-UID ambient authority) was run here
  either; the candidate review's §5 statement stands, and its proposed
  direct-write/process/network tests are the right next experiments.
- dlopen probe demonstrates invocation only; authority confinement of
  native modules remains the candidate's §6 requirement, unexecuted.
