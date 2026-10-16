# runtime-lead amendments R1 — operator corrections turned into exact proposal edits

Scope: edits to `deliverables/design-lead/revised-design-text.md` (proposed; root integrates).
Each amendment states the exact replacement text, the evidence, and the strongest case for the
original design that is preserved. No shared source was modified. Source references are at
canonical commit `b1f006a6308bbb00e29a24322e4f7d5164774470`.

## A. Quotas and deadlines (operator conflict, even task-scoped)

### A1. §11 quotas bullet — replace "enforced uniformly"

Current text (revised-design-text.md:163-165):

> No ambient step, token or time quota. Task-scoped step, token and time parameters arrive with
> tasking, are recorded in the log and enforced uniformly; per-call timeouts are properties of
> individual tools.

Replacement:

> No step, token or time quota — ambient or task-scoped — controls admission, continuation, or
> unfinished work. A task-scoped budget or timeout that does so is an explicit design conflict,
> not a recommendation. Budget parameters that arrive with tasking are recorded in the log and
> reported as ledger fact, never enforced as a gate. Provider quota failures are observed
> outcomes: retained in the log and reported to the Conductor, never answered by policy-driven
> parking. Per-call timeouts remain properties of individual tools, bounding a single effect,
> not a task.

Evidence: operator directive (proposal-root review, cf. evidence-lead claim-register-v0.md
I-QUOTA-03, ROOT-DIRECTED). Register state verified: I-QUOTA-02 is preserved as SUPERSEDED by
I-QUOTA-03 — no register change needed; the design text is what lags.

Strongest case for the original (preserved): uniform enforcement of recorded parameters gives
reproducible benchmark arms and protects runaway cost. That value survives as *measurement*:
recorded parameters with per-arm reporting give the same comparability without enforcement;
runaway-cost protection moves to the Conductor, which already owns stop authority
(`stop`/`force-stop` ship, `commands.bend:594-609`).

### A2. §4 pending-operation state machine — remove cap enforcement, recast deadlines

Current text (revised-design-text.md:69-73): "Each class of operation has a recorded deadline
and a heartbeat cadence … Caps are per class and are task-scoped parameters arriving with
tasking and recorded in the log, never ambient defaults."

Replacement:

> States: `pending, running, heartbeat_due, cancelled, lost, completed`. Each class of
> operation carries a heartbeat cadence and an age expectation recorded in the log; a heartbeat
> carries the actions the model may take — wait, cancel, collect partial output, or mark lost.
> Quiescence, not "turn ended", is the completion contract: the session is open while an
> operation is in flight and closes when nothing is. Child process groups are recorded and
> reaped. Cancellation authority rests with the model (for its own operations) and the
> Conductor (stop authority over the seat); the runtime itself never cancels, times out, or
> parks unfinished work. Per-call timeouts of individual tools are tool properties bounding a
> single effect, and are the only automatic termination.

Evidence: operator directive; I-QUOTA-03. `timed_out` removed as a runtime-enforced state
because an automatic deadline on an unfinished operation is exactly the conflicted mechanism;
`lost` remains as an *observed* state (a result that never arrives), which is a fact, not a
policy.

Strongest case for the original (preserved): the redteam P1 finding stands — one
never-settling operation must not hold the session open *invisibly*. The heartbeat cadence,
age expectation, and `lost` marking keep the failure observable and model-actionable; what is
removed is only the runtime's unilateral authority to end the work.

## B. §5 program lane — the child-authority claim overstates the mechanism

Current text (revised-design-text.md:88-91): "nested tool calls re-enter the seat over a
loopback socket so every effect passes the guarded pipeline and the child holds no authority
the seat did not grant."

Replacement:

> Generated Bend2 programs run out of process. The program and a byte-stable SDK module are
> written under the session directory; `bend <program> <args>` runs as a child through the
> process family with its stdout and stderr captured into the log; nested tool calls re-enter
> the seat over a loopback socket so every *SDK-expressed* effect passes the guarded pipeline.
> Socket re-entry is a routing convention, not an authority boundary: the child is an ordinary
> same-UID subprocess and retains full ambient OS authority (filesystem, process spawn, raw
> network) for anything it does outside the SDK. The actual boundary requires OS confinement —
> on this runner, rootless Linux namespaces plus seccomp (e.g. bubblewrap); on macOS,
> `sandbox-exec` — and that confinement is UNTESTED on the pinned toolchain: no probe has run a
> confined Bend2 child. Until it lands, the design must state plainly: the child inherits the
> seat's OS authority, and the only guaranteed mediation covers effects the SDK chooses to
> route.

Evidence: same-UID subprocess semantics are OS fact; Base ships no sandbox effect
(`toolchain-home/bend2/effs/` inventory verified at 2.0.25); no confinement probe exists in
the prior audit's ten probes or this round's. The feasibility audit's own wording ("Confinement
is the OS sandbox plus the absence of…") names OS confinement as a separate layer the sketch
never specifies.

Strongest case for the original (preserved): for well-formed SDK programs the guarded-pipeline
property is real — every effect the generated program *expresses through the SDK* re-enters the
seat, carries parent-child call-id correlation, and is logged. Base's missing `exec`/HTTP/TLS
also raises the effort of casual exfiltration. But that is effort, not a boundary, and the
design now says so.

## C. §2 stale source citation

Current text (revised-design-text.md:49): `SRC:bend2/src/host/session-lock.c`.

Replacement: `SRC:bend2/src/host/session-lock.bend` (the Bend half declaring
`SessionLock.try_acquire`/`wait_acquire`/`acquire_session`) with the C half at
`SRC:bend2/src/host/process-spawn.c` (`flock(LOCK_EX|LOCK_NB)` at :2438 and :5096). At
`b1f006a6` there is no `host/session-lock.c`; the lock effects merged into `process-spawn.c`
(now 5,192 lines). The prior audit's `session-lock.c:55` citation describes an older revision.

Companion correction, §7 (revised-design-text.md:119-125): `branching-model.bend:13` correctly
cites the *schema* (branch_rounds columns); the *behavioral* inheritance claim needs
`SRC:bend2/src/coordinator/branching.bend:64-73` (`input_snapshot`, `knowledge_snapshot`,
`round_task`) plus `docs/bend2/branching-ensembles.md` (research reference, Fork-and-Flush).
Cite both, labeled schema vs behavior.

## D. Claim-register note (evidence-lead)

I-QUOTA-02's SUPERSEDED marking and I-QUOTA-03's ROOT-DIRECTED text already implement the
operator's register ask: original preserved, correction recorded. Recommend one edit only:
annotate I-QUOTA-03 with the two design-text locations that lagged it (§4 caps, §11
"enforced uniformly") so the register points at where the correction lands. If any copy of the
register marks I-QUOTA-02 RESOLVED rather than SUPERSEDED, that marking is wrong: the position
was not resolved, it was overridden by an operator directive, and the register should keep the
distinction.
