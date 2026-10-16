# review-corrections.md — bend-feasibility dissent and corrections

Target documents (root-prepared candidates, recovery-20261016T1802Z):
`review-ready/probe-evidence-review.json`, `review-ready/review-notes.md`,
`review-ready/design-sketch.final-review.md`. Nothing in the recovery
packet was modified; these corrections are recorded here for the
Conductor's integration, with evidence paths.

## A. probe-evidence-review.json — records superseded by this continuation

The review's method line is "Read retained original outputs; no probe or
compiler was rerun locally." Its classifications were correct for the
reboot-time packet. This continued session re-ran every flagged probe
under the same pinned toolchain; the new captured outputs live in
`deliverables/bend-feasibility/probes/<name>/output.txt` (12/12 present).
Per-record status:

| Record | Root classification | Status after continuation |
| --- | --- | --- |
| p03 | "partial execution; final failure … Does not establish a successful end-to-end durability … contract" | Superseded: full sequence (write, fsync, rename, dir-fsync, stat "size 9", committed `hello-log`) captured on **both** native and interpreted lanes. The recorded exit 2 is the probe's own final `unlink` of the already-renamed temp path (the same deliberate artifact as the original audit's probe 1), not a durability failure. Root's limit stands only in the narrow sense that no crash/kill-recovery window was exercised. |
| p06 | "checker refusal … No executed HTTP/TCP success" | Superseded: HTTP/1.1 request, incremental chunk delivery (interleaved with server log), EOF close, exit 0 captured. Root's packet also missed the actual cause (the pre-continuation source mismatched `IO`/pure types at a `poll_ok(...)` call), not the Base TCP surface. New finding captured: peer close arrives as `Some{""}`; `None{}` is timeout-only. First-run blowup preserved with a truncation provenance note in the output. |
| p09 | "intended assertions not reached" | Superseded: all intended assertions captured — `--check-only` fails "Error: 1 TODO found." with an open law in an import; `--checkup` prints `--- ./tool.bend ---` then fails; reflexivity proof attempt prints `- expected : U32.add(U32.add(n, n), U32.add(n, n)) / - observed : U32.mul(n, 4)`; forge probe prints "forged capability released level 999", exit 0. These agree with failure-evaluation's independent probe2/probe4 and proposal-strongman's lawgate evidence; the earlier invalid attempt Root recorded was a source bug (`+n` binder), now fixed in the retained source. |
| p10 | "intended assertion not reached … Does not demonstrate a functioning dynamic loader" | Superseded: the loader demonstrably exports the module's non-IO defs under `default`; a JS host calls `double(21) = 42`, `greet`, and constructors cross as `{"$":"Some","value":7}` (p10/output.txt). |
| p12 | "diagnostic and wrapper-status mismatch" | Acknowledged and fixed: the runner now captures the compiler's own exit (`bend_exit=0` with `@unsafe`; refusal text "a decreasing self-call" without it). Root's instruction to record both outcomes separately is implemented. |
| p04, p11 | missing outputs | Captured this continuation (p04: `socket said PONG`, exit 0; p11: full cost table). |
| p01/p02/p05/p07/p08 | accurate | Confirmed unchanged; outputs re-verified present. |

Root's `sourceClaimPolicy` ("a run-script file alone does not establish
execution") is adopted here: every claim above points at a captured
`output.txt` with actual exit codes, and the two truncated/failed
attempts are preserved (p06 provenance note; the buggy pre-fix C halves
and their ENOENT outputs remain in git-less probe directories' histories
— where absent, the failure is documented in FINDINGS.md §3).

## B. design-sketch.final-review.md — evidence corrections

1. §5 (Tools and generated programs), sentence "Type checking is an
   explicit admission choice; an interpreter invocation alone carries no
   checker verdict." — **contradicted by observation.** `bend x.bend`
   checks before running (GUIDE.md:495 "check; run main"); every
   interpreted probe refused on checker errors before execution, and the
   reliance report ("N defs rely on unsafe or foreign code") prints on
   interpreted runs (p02/p03/p07/p10 outputs). The bun-plugin path checks
   too (p10's first run surfaced the checker error through
   `main.ts load_js`). Proposed replacement: "the interpreter lane checks
   before running and prints an @unsafe/foreign reliance report;
   `--check-only` remains the admission gate for programs the seat will
   build or admit." Severity: medium — as written it under-states what
   the platform guarantees and could justify skipping an admission gate
   that is in fact available for free.
2. §5 cost paragraph — add the large-program anchor beside the trivial
   numbers: recorded production emit at this pin is 2101 s / 142,651,376
   KiB max RSS for 43,412 lines of Bend2 + 7,897 lines of C
   (`build-result.json`). The compile-once promotion path scales with
   program size; the trivial-program constants alone understate it.
   This lane's Linux trivial constants: check 353 ms / emit 420 ms /
   link 855 ms / native run 32 ms / interpreted 409 ms (p11).
3. §2 durability family — upgrade "proposed seat guarantees … must be
   checked separately" to "primitives demonstrated through one authored
   C half on the pinned Linux toolchain (probe p03: fsync, dir-fsync,
   rename, unlink, stat-size, mkdir, both lanes); the seat's durability
   contract remains to be implemented." The 4 GiB U32 bound of Base file
   size/offsets (`effs/file_size.c` EOVERFLOW; `base.bend:272`) should
   be named as the forcing constraint for segment rotation.
4. §6 extension paths — add the constructor-namespace constraint
   (constructor names are global; `Done{}` collides with
   `Result.Done{}` — p02) as a stated reason the declarative path avoids
   admitting constructors, and note the effect-author NUL contract
   (`io_cstr` length excludes the terminator, comp.ts:5670-5686) as the
   concrete class of admitted-vs-executed bytes bugs to test at the
   execution boundary.
5. §4 — confirmed as written ("Base Chan.recv signature has no
   timeout…"); supporting demonstrations to cite: completion-order join
   (p07) and TCP EOF-as-empty-read (p06) as the behaviors a wake/event
   effect must reconcile.

## C. review-notes.md — status correction

"Research-critic and bend-feasibility final reports … remain original
assignments awaiting coordinator recovery" — the bend-feasibility final
report is now complete (this directory: `FINDINGS.md`,
`probes/README.md`, twelve captured probe outputs). The diagnostic-limits
section's five bullets are updated by §A above; the narrower
constructor/law proofs Root asked to keep separate are now additionally
carried by this lane's own P09 captures, which agree with
failure-evaluation's probes.

## D. Dissent preserved

None material on feasibility. One emphasis dissent: the candidate's
framing "No confined Bend2-child probe was executed in this review" is
true of every lane so far, and it is the single most load-bearing
unexecuted experiment for the §5/§6 authority story — same-UID ambient
authority is the default threat model for everything the seat spawns. I
rank it above any measurement-campaign work in §12 and ask the
Conductor to sequence it first among the runtime probes.
