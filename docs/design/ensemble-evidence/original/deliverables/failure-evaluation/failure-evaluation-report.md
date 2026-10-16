# Failure evaluation: baton-cli design sketch and the prior review — independent adversarial pass

Session: failure-evaluation (ensemble design-evaluation). Authored 2026-10-16.
Pinned corpus: baton-cli @ 5941316491eb01d8794abddc5dcf1798801c4aaf (read-only).
Canonical source: baton2 postrelease tree @ b1f006a6308bbb00e29a24322e4f7d5164774470 (read-only).
Toolchain: bend 2.0.25, linux-x64, at
`/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend`.

Seed-note (as instructed): the assignment seed is a 512-bit hex string with no visible structure —
uniform entropy, no pattern to trust, every bit equally likely. Used as an interpretive stance:
assume adversarial inputs, distrust the first plausible reading, and sample the tails of the
failure distribution (rare interactions, not the median path). The scenarios below are chosen on
that stance.

## 0. Lanes

All claims below are tagged:
- **[shipped]** — behavior of the installed baton 2.0.0 coordinator or the canonical source at b1f006a6.
- **[source]** — source-only facts at the pinned commits (baton-cli corpus, canonical tree, toolchain base.bend).
- **[proposed]** — sketch text or amendment-plan text (design, not built).
- **[paper]** — numbers reported by external papers/blogs, not local measurements.

Lane rules honored: no shared checkouts edited, no full coordinator build, no process signaling, no
live knowledge mutation, no branches. All experiments live under `probes/` with sources, exact
commands, raw output and exit codes. The prior review (audit-findings.md + seven reviews) was read
after my source work began and is treated as evidence to check, not verdicts to copy; §6 states
where I disagree with it.

## 1. Probes (smallest experiments; raw output in probes/*/run.txt)

| # | Claim probed | Method | Result |
|---|---|---|---|
| P1 | Law-gate integrity of the pinned production tree | `bend bend2/src/coordinator/knowledge-laws.bend --check-only` at b1f006a6 | **FAILS**, exit 1: `m1_the_knowledge_schema_retains_findings_and_promotions` expected/observed mismatch (law string lacks `kind`, `source_kind`, `destination_kind`, `knowledge_relations`). The law also calls 2-arg `promotion_admitted` (module defines 3-arg, knowledge.bend:306) and references nonexistent `evidence_ok` (knowledge-laws.bend:67). |
| P2 | Bend2 authority records are forgeable | two-file probe: module exports `type Lease is Data: Mk{cap: U32}` + intended `mint`; importer constructs `L.Mk{999}` directly | `--check-only` exit 0 ("All terms check."), run prints `999`, exit 0. No unforgeable value exists at the type level. |
| P3 | Affine reuse refusal (no tool-closure table) | `def apply2(f: U32 -> U32, x: U32) -> U32: U32.add(f(x), f(x))` | refused: `x (consumed more than once)`. |
| P4 | `match` cannot head a do block | match inside `do IO<Unit>` | refused: "a match heads a def body, not a term". |
| P5 | Deadline-bounded waiting at Base | fork sending after 60 s; `Chan.recv`; run under `timeout 3` | blocked past deadline, exit 124. `Chan.recv(chan) -> IO(Maybe<&1,A>)` (base.bend, no timeout param); no select/race/try-recv in Base; only `IO.sleep`/`IO.now` exist as time primitives. |
| P6 | Knowledge relation rows are last-writer-wins by caller-supplied id | shipped SQL transcribed from knowledge.bend:271-289 + agent-native.bend:215, replayed on a scratch SQLite DB | overwrite accepted: author flips `worker-a`→`peer-b`, target becomes `http://attacker.example/poison`, the edge **disappears from the original author's scoped read**; no refusal, no notice. Statement-level reproduction; binary-level run is the discriminating experiment (needs two registered scratch sessions). |

Source anchors for P6 (read, not inferred): `knowledge.bend:288`
(`ON CONFLICT(id) DO UPDATE SET author=excluded.author,...`), `agent-native.bend:215`
(caller `$.id` preserved verbatim when present), `knowledge.bend:66` and `:202-210` (relation ids,
including `r.id`, returned in every scoped read and in `knowledge search` output).

## 2. Named failure / attack scenarios

Format: trigger → mechanism → observable symptom → discriminating experiment → preventing
invariant. Status labels: **witness** (proven by probe/source at the pin) or **hypothesis**
(state-machine scenario on [proposed] design; no implementation exists to run).

### S1 — Torn-tail lockout (crash/restart) — hypothesis, mechanism grounded
- Trigger: process death mid-append; final JSONL line partially written.
- Mechanism: sketch §2 validates "contiguous sequence numbers … on append and load" and adopts
  fx's writer latch ("a writer that finds the log no longer ends where it last committed latches a
  failure state"). The sketch names **no load-time repair**. fx's shipped answer is separate and
  unstated in the sketch: "A torn tail on open truncates to the last complete frame"
  (fx.md:141). Conflating foreign-writer latch with own-crash torn tail turns a recoverable crash
  into a permanent refusal.
- Symptom: seat refuses to start after an ordinary crash; operator intervention (unlogged manual
  truncation) becomes the recovery path.
- Discriminating experiment: crash-injection fuzz that kills the writer at every byte offset of an
  append, then loads; negative witness = any load that does not self-repair to the last complete
  frame with a typed `log.repaired` event.
- Preventing invariant: load-time torn-tail repair (truncate to last complete frame, emit
  `log.repaired`) distinct from the foreign-writer latch (`SessionWriterChanged`).

### S2 — Replayed non-idempotent tool after crash (duplicate effect) — hypothesis, mechanism grounded
- Trigger: crash between intent journal and result commit for a non-idempotent bash call.
- Mechanism: sketch §2 journals intent before running (fx §4) and gives **operation records**
  at-most-once semantics (unreal §4), but says nothing about effects that may already have run.
  fx's shipped trio is: "only a stored intent reruns a call under the same id"; idempotent-non-writing
  tools run ahead; on resume ambiguous calls are "rerun under a stable execution id or answered as
  possibly-run" (fx.md:56, 232). Without that trio, resume either reruns a completed `git push` /
  `rm` / POST (duplicate effect) or refuses the whole session.
- Symptom: doubled side effects; transcript shows one call, the world saw two.
- Discriminating experiment: crash-timing matrix (before intent / after intent before effect /
  after effect before commit) × declared idempotency class; negative witness = any re-execution of
  a completed effect, or any *silent* possibly-run answer.
- Preventing invariant: intent barrier + possibly-run typed answers + idempotency declaration
  driving replay, stated in sketch §2 (currently absent).

### S3 — Head-of-line commit stall (race / lost result) — hypothesis
- Trigger: op1 never settles; op2 completes quickly.
- Mechanism: sketch §4: "commits stay model-ordered through a head-of-line cursor while completion
  order varies" (dsh §1.1). A strict cursor gives op2's arrived result no commit path until op1
  resolves; with the pending set non-empty the seat never reaches "ending a turn with nothing
  running ends the session".
- Symptom: a completed result invisible to the model; growing running stubs; session wedged.
- Discriminating experiment: two-operation model fixture, op1 cancelled at a deadline; negative
  witness = op2 still uncommitted after op1 is terminal.
- Preventing invariant: the cursor carries a deadline and a typed reorder path (`results.reordered`
  event) or commits op2 as a second item; the sketch specifies neither.

### S4 — Admission-time authority vs execution-time mutability (stale authority / TOCTOU) — design gap, attack witness-adjacent
- Trigger: seat admits a declarative tool (amendment-plan item 4: name, schema, argv template,
  permission target, digest) whose argv names an artifact under the session directory; the seat
  later edits that artifact with its own `edit`/`bash`.
- Mechanism: the digest pins the **declaration**, not the executed bytes; the executed artifact
  lives in the seat-writable workspace; admission happens at a turn boundary, execution later.
  Bend2 cannot close this in-process: P2 proves there is no unforgeable value, so "extensions
  inherit the seat's authority and cannot widen it" (sketch §6) is not enforceable as a type; and
  P1 shows even the proposed `--check-only` gate is red in the production tree today.
- Symptom: an admitted low-permission tool executes changed behavior; the admission log describes
  a different program than the one that runs.
- Discriminating experiment: admit → mutate → invoke with an exec/open audit hook; negative
  witness = executed-bytes digest ≠ admitted digest without a typed mismatch refusal (fx's
  `checkpoint.mismatch` is the model, fx.md §12).
- Preventing invariant: execute by content address (copy admitted bytes to a CAS path, exec that),
  or re-digest at spawn with refusal-on-change, recorded in the log.

### S5 — Poisoned standing state / spill bait (poisoned context) — hypothesis, corpus analogs
- Trigger: instruction-shaped text arrives via peer content or tool output; the model transcribes
  it into the workset (sketch §9 standing state) or it lands as a spill preview.
- Mechanism: the workset is rendered into the dynamic tail **every turn** — a persistent,
  high-attention injection channel that survives precisely because nothing is ever compacted away.
  The sketch's sanitization duty (§8) applies to peer messages as untrusted input, not to what the
  model itself writes into standing state; spill previews are attacker-controlled text delivered
  with a path whose follow-up read re-ingests unbounded bytes (no read bound is named for the
  seat's own read tool).
- Symptom: a durable instruction at the highest-salience prompt location, re-rendered every turn.
- Discriminating experiment: injection canary red-team suite (plant via peer message / tool
  output), measure (i) workset arrival rate, (ii) re-render persistence, (iii) downstream effect;
  whole-transcript review is a poor detector here (monitor miss rates rise 2x-30x past 800K
  tokens [paper, arXiv:2605.12366]), so the experiment must diff workset state, not read transcripts.
- Preventing invariant: workset mutations pass a schema valve carrying provenance; spill-handle
  reads are byte-capped with a receipt.

### S6 — Relation hijack / lineage rewrite in the shipped knowledge store (cross-scope disclosure) — **witness** (P6 + source)
- Trigger: any registered session learns a relation id (returned in every scoped read and search)
  and re-records it inside its own `knowledge record --links '[{"id":"<victim id>",…}]'`.
- Mechanism: `knowledge.bend:288` rewrites the row (`ON CONFLICT(id) DO UPDATE SET
  author=excluded.author,…`); `agent-native.bend:215` preserves caller-supplied ids; the scope
  filter keys on authorship, so the edge migrates visibility to the attacker and vanishes from the
  victim's scope. Findings are protected (content-guarded conflict refusal, knowledge.bend:260-274);
  relations are not; no notice is emitted.
- Symptom: silently rewritten lineage; cross-scope movement of a claim's evidence edges; the
  original author loses the edge from its own view.
- Discriminating experiment (binary-level, for the root lane): two registered scratch sessions;
  session B re-records session A's relation id; diff A's `knowledge search` before/after. Negative
  witness = the rewrite is accepted and A's view changes. Statement-level reproduction already
  fails-safe: P6.
- Preventing invariant: relation ids immutable, or author-namespaced on ingest
  (`author || ':' || caller-id` at agent-native.bend:215), or conflict-guarded like findings with a
  notice. This is a one-line-class fix in shipped code, and operator requirement 6 (preserve
  authority, lineage) is violated until it lands.

### S7 — The never-settling operation holds the session open (completion / quiescence) — witness at shipped level, hypothesis for the seat
- Trigger: a live streaming shell (per-call timeouts are tool properties; "no ambient quotas" §11)
  whose child blocks forever; or S3's stall.
- Mechanism, shipped: the coordinator holds one attempt per session under a physical lock
  (`session-lock.bend`: `try_acquire`/`wait_acquire` — "A serve task waits for the current session
  owner to release its physical lock"); the owner loop polls with `poll(…, -1)` (infinite,
  process-spawn.c:2359-2362) with no watchdog; the escape hatches are operator verbs
  (`force-stop`, `recover-observer`) — they exist because the case is real.
- Mechanism, proposed seat: sketch §4 ends the session only when nothing runs; sketch §4's
  "idle cap with a short grace window" presumes a timer-select that **Base cannot express** (P5:
  no deadline on `Chan.recv`, no select; only `IO.sleep`/`IO.now`). A natural implementation
  either blocks forever or burns turns polling.
- Symptom: session never completes; queued deliveries block on the lock; the parent sees silence,
  not failure.
- Discriminating experiment: milestone-1 seat against a `sleep infinity` tool with no per-call
  timeout; negative witness = no terminal state, no coordinator-visible deadline event.
- Preventing invariant (the design must state all five):
  1. quiescence as the completion contract — no in-flight entry and no unevaluated settle
     (prime-agent.md:51, 92);
  2. per-operation-class deadlines persisted **before** the wait, with terminal states
     `timed_out`/`lost`/`cancelled`;
  3. heartbeats that carry the model's actionable choice: wait / cancel / collect partial / mark
     lost;
  4. the wait mechanism named: sleep-poll over the durable pending table (`IO.sleep` +
     re-read) or a new C effect family (poll-timeout / WNOHANG reaper) — P5 rules out channel select;
  5. coordinator-side default: a completion request is refused while pending operations exist, and
     a recorded deadline auto-marks lost and closes the attempt — degradation to a visible failure,
     never silence.

### S8 — Evidence-chain opacity in the review itself (silent read paths / simulated evidence, meta) — witness
- Trigger: trusting "code-verified" labels in the prior review without locality.
- Mechanism: (i) the JS-line citations (`impl/src/…` at 1e050e42, `/Users/wahargis/...` paths) are
  **not checkable from the pinned corpus** — no `impl/` tree exists at b1f006a6 and the paths are
  macOS-local on this Linux host; within this ensemble they are source-plausible, not
  code-verified. (ii) The research corpus is LLM-authored reports (docs/research/README.md:4-5);
  "code-verified in a harness" means *reported* line numbers, and no clone is retained in the
  pinned tree — a plausible-but-fabricated citation chain would survive the whole pipeline.
  (iii) The feasibility probes ran on darwin/arm64 with a self-declared host toolchain defect;
  mine (P2-P5) reproduce the load-bearing language claims on linux/x64 with the pinned toolchain —
  they held, which upgrades those specific claims to locally re-verified.
- Symptom: verdicts inherit the reliability of the corpus instead of the code.
- Discriminating experiment: re-clone at the recorded HEADs and diff the cited line numbers
  (spot-check: the nine corpus files' key lines I verified all held — nooa.md:69,77;
  unreal-agent.md:46,131; fx.md:56,141,232; deepseek-harness.md:98,141,187;
  context-language-models.md:91-92,129; benchmarks.md:145,153,177; arcee-nac.md:76-79,123,283;
  prime-agent.md:51,92,94).
- Preventing invariant: lane-(a) claims cite evidence retained under a deliverables tree (clones or
  recorded output), not reviewer memory; "seven independent agents" sharing one corpus are
  independent verdicts, not independent evidence.

## 3. Grading the sketch's log/loop/async invariants

Grades: **code-verified*** = verified in their home harness per corpus line citations I re-checked
and, where language-level, re-verified locally (P2-P5); **source-plausible** = consistent with
source/corpus but not re-verified here; **idle** = as stated in the sketch, unsupported or
contradicted.

| Sketch invariant (§) | Grade | Note |
|---|---|---|
| Turn closes with a reason on every exit path (§2) | code-verified* | dsh `agent.ts:298-391` (corpus-reported); home-harness, not yet baton-cli |
| Tool result never separates from call (§2) | code-verified* | pi `compaction.ts:351`, `orderToolResults` (corpus-reported; audit-evidence's §7-not-§4 correction is right) |
| Truncated output fails pending calls with re-issue (§2) | code-verified* | pi §4/§12 |
| Effectful calls journal intent before running (§2) | code-verified* | fx.md:56, 232 (I verified the lines; fx also carries the possibly-run answers the sketch omits — S2) |
| Writer latches on foreign tail (§2) | code-verified* | fx.md:141 — but fx's separate torn-tail **repair** is missing from the sketch (S1) |
| Inputs idempotent by caller id, persisted before processing (§2) | code-verified* | unreal `inbox.go`, `loop.go:440` |
| Status persisted atomically with awaited ops (§2) | code-verified* | unreal `itemRecord.Operations` |
| Fork must not inherit in-flight calls (§2) | code-verified* | unreal FIXME `loop.go:593-596` (corpus-reported) |
| Compaction "expected never to fire" (§2) | **idle** | contradicted by corpus (NOOA 75% default-installed summarizer, nooa.md:77; NAC 70% fallback, arcee-nac.md:123,283); audit C1 is right |
| Catalog "written once and masked at decode" (§3) vs §6 registration | **idle** as written | internally contradictory; dsh's real mechanism is `ToolHistoryProjection` refusing redefinition (deepseek-harness.md:141) — cite that, drop Manus masking |
| Three-region prompt; provider parts re-attached on match (§3) | source-plausible | NOOA/dsh layout; vendor for masking half |
| Pending ops durable, at-most-once (§4) | code-verified* (for op records) | unreal §4; effects are not covered (S2) |
| Stub replacement vs second item (§4) | source-plausible | provider-dependent, vendor-reported; "primary path" unmeasured (unreal §13) |
| Batched drain, idle cap + grace window (§4) | code-verified* as mechanism (unreal `slurpMaxItems=100`, 1 ms) — **but the timer-select it presumes is not expressible at Base** (P5): the wait mechanism must be specified (S7.4) |
| Model-ordered head-of-line cursor (§4) | code-verified* (dsh §1.1) — sketch omits its deadline/reorder path (S3) |
| Steering never queues behind a tool call (§4) | code-verified* | unreal §3; the arcee citation is a recorded counterexample (audit C6 right) |
| Writer fences: first writer runs alone (§4) | code-verified* | fx `SessionWriterChanged` + flock (`session-lock.bend` shipped analog) |
| Join = handle; sleep until something lands (§4) | code-verified* (prime `BashHandle`) — with P5 caveat: no deadline-bounded variant exists at Base |
| "Executed natively in the same confinement" program lane (§5) | **idle** | no evaluator; out-of-process is the only lane (feasibility verdict stands; P1 additionally shows the proposed law gate is red at the pin) |
| "Extensions inherit authority, cannot widen" (§6) | **idle as a type claim** | P2: no unforgeable value; must be an effect/OS-boundary mechanism (S4) |
| Promotion gate (§6) | code-verified* (CLM `evolve.py`) | outcome numbers paper-reported [paper] |
| Hand-off cells / version-pinned deref (§8) | source-plausible | substrate exists on JS line only per prior review (not checkable here); Bend2 line has none |
| Grants: caveats/lineage/revocation (§8) | **idle** | only `claimGrant {boardRunId, board}` exists (prior review; unverifiable here) |
| Workset shape / verification recipe (§9) | code-verified* (NAC) | currently a data field; completion gate proposed, not built |
| Sandbox fail-closed union, approvals invocation-only (§10) | code-verified* | dsh §6, arcee §7 |

Net: the **log** invariants are the best-grounded part of the sketch; the **async** section is
mechanism-grounded but ships two unstated dependencies (timer wait, cursor deadline) and the
completion contract; the **self-extension/orchestrator** sections are idle-to-proposed at the pin.

## 4. Completion / quiescence (explicit treatment)

The question: a never-settling operation holds a session open. Answer in three layers:

1. **Shipped today [shipped]**: the failure mode is real and pre-existing. One attempt per session
   under a physical lock; `wait_acquire` blocks queued deliveries; the owner loop polls with an
   infinite timeout; no watchdog; recovery is operator (`force-stop`, `recover-observer`). Any
   harness that inherits this coordinator inherits the same exposure.
2. **Proposed seat [proposed]**: sketch §4's completion rule ("ending a turn with nothing running
   ends the session") plus §11's no-quotas stance make the wedge the default under one hung child.
   The critique's P1 (pending-op state machine) is necessary but not sufficient: P5 proves the
   language cannot express deadline-bounded channel waits, so the design must name the wait
   mechanism (sleep-poll over the durable pending table, or a new C effect family) or the state
   machine stays a diagram.
3. **Required contract** (all five points of S7, plus): the completion-request path refuses while
   pending operations exist; the coordinator auto-marks lost at a recorded deadline and closes the
   attempt with a visible event; fork settles or cancels pending work before copy (unreal FIXME is
   the recorded poison case).

## 5. Benchmark validity — discriminating evaluation plans

- **Async-vs-blocking A/B (bet 1).** Confounds to control: (1) idle-cap batching changes
  model-visible result grouping → token deltas not caused by async; add a fixed one-result-per-turn
  replay arm; (2) grace window is a knob, not a constant — sweep {0, 1 ms, 50 ms} to separate
  overlap from batching; (3) pair by task seed and report per-task paired deltas, not means only;
  (4) PASTE/TomasuLLM-class speculation is a different mechanism (harness-driven) — do not cite its
  wall-clock wins as evidence for the sketch's model-driven async (lane (d) vs (c)); (5) the
  token-cost half has no published measurement — pre-register the minimal detectable effect.
- **Divergence counters for every switch** (HARBOR's lesson): write-side vs consumer-side counters;
  a write without a consumer is an invariant violation; never-firing switches auto-exclude from
  analysis. Local precedents that this is needed: the JS-line knowledge read path built and called
  by nothing (prior review, unverifiable here), and P1 — a law file nothing compiles, red in
  production while the build is green.
- **Negative-witness registry**: per invariant, the runtime trace that would falsify it
  (orphan `tool_result` seq gap; completion while pending non-empty; executed digest ≠ admitted
  digest without a typed refusal; edge row whose author differs from its creator's session). Run
  these as executable fixtures over the protocol state machine (sketch §13), not as a TLA+ gate
  first.
- **Promotion gate validity**: the gate mechanism is code-verified but its outcome numbers are
  [paper]; local promotion claims must pair the gate with a held-out split touched once and
  per-task paired diffs; an external suite (Harbor-Index is the current audited candidate [paper])
  with its own broken-task audit.
- **Parse-failure visibility** (Aider class): keep sketch §12's default logging; add the silent-
  switch exclusion above.

## 6. Relation to the prior review

Checked and held (independently re-verified here): the platform infeasibility verdicts (no
evaluator, no runtime loader, affine reuse refusal, match-in-do, forgeable records — P2-P4), the
three internal contradictions (C1/C2/C5), the NOOA/CLM/+7.7 evidence regradings, the fork-mismatch
finding, the citation repairs I spot-checked.

Extended beyond it:
- **Closed its open question** (integration-knowledge uncertainty: "whether the entry compile still
  checks these statements was not verified") — P1: it does not; the law gate is red at the pin, and
  nothing in the build compiles laws, which is why the drift shipped silently. Any amendment
  resting on `--check-only` gates (amendment 4, feasibility probe 8) needs "gate green at the pin"
  as a prerequisite.
- **New shipped-behavior finding**: S6 relation hijack (knowledge.bend:288 + agent-native.bend:215)
  — the knowledge layer the sketch §11 designates as the standing store rewrites lineage on
  caller-supplied ids today.
- **New design gap**: S4 admission-vs-execution digest gap in amendment 4's declarative-tools path.
- **New language constraint for the async layer**: P5 (no deadline-bounded wait at Base) — the
  sketch's batching/waiting vocabulary needs a named wait mechanism.
- **New meta-finding**: S8 — "code-verified" in the review chain means corpus-reported; JS-line
  claims are not checkable from the pinned corpus; feasibility probes were darwin-only until now.

## 7. Strongest case for the proposal (independent steel)

The mechanical core is right and is the part I could re-verify: every log invariant the sketch
adopts exists in a shipping harness with named code, the turn boundary as the single commit point
for six operations is the highest-leverage decision in the document, the two-plane economy has the
strongest measured support once the OpenCode row is quoted honestly, and the omissions map to
documented costs. The 23-item amendment plan is broadly correct; with my additions (gate-green
prerequisite, content-addressed execution, relation-row hardening, named wait mechanism,
quiescence default) the plan is buildable at the pinned toolchain.

## 8. Concrete corrections (beyond the prior amendment plan)

1. Milestone-1 exit criterion: every `*-laws.bend` in the tree compiles (`--check-only`) in CI;
   fix the three knowledge-law drifts first (P1).
2. Amendment 4 amended: admitted artifacts execute by content address; spawn-time re-digest with
   typed refusal-on-change (S4).
3. §4 gains a named wait mechanism: sleep-poll over the durable pending table or a new C
   timer/wait family; no channel-select exists at Base (P5).
4. Pending-op machine gains its coordinator half: completion refused while pending; recorded
   deadlines auto-mark lost and close (S7).
5. Head-of-line cursor gains a deadline and a typed reorder event (S3).
6. §2 gains fx's two missing pieces: torn-tail repair on load (`log.repaired`), possibly-run
   answers + idempotency classes for resumed effects (S1, S2).
7. §9 workset mutations gain a provenance-carrying schema valve; spill-handle reads get a named
   byte cap with receipt (S5).
8. Shipped store hardening (root lane, one-line class): author-namespaced or immutable relation
   ids at agent-native.bend:215 (S6).
9. Review-chain hygiene: JS-line claims in audit documents marked not-checkable-from-this-corpus;
   retain clones or recorded outputs for lane-(a) claims (S8).

## 9. Unresolved dissent

- I weight the quiescence gap higher than the critique's P1 wording suggests: the shipped
  coordinator's own lock/wait/force-stop design is evidence the wedge is a live operational case,
  so the deadline path belongs in milestone 2's exit criteria, not in a definition.
- I do not accept "digest of the declaration" as a safety property for admitted tools (S4); the
  prior amendment plan does.
- The "code-verified" grade is weaker than its label (S8); my re-verification of language claims
  (P2-P5) and corpus lines held, which is why the verdict survives, but the grade should be read as
  "corpus-reported, spot-checked".

## Deliverables

- `probes/probe1-lawgate-drift/` — command + output (the drift), REVISION.txt.
- `probes/probe2-forge/` — lease.bend, main.bend, run.txt (checks + 999).
- `probes/probe3-affine/` — main.bend, run.txt (consumed-more-than-once).
- `probes/probe4-match-do/` — main.bend, run.txt (checker wording).
- `probes/probe5-deadwait/` — main.bend, run.txt (exit 124; base.bend signatures cited).
- `probes/probe6-relation-hijack/` — run.py (statement transcriptions with source anchors), run.txt.
