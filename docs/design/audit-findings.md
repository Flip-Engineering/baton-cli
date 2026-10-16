# Audit findings: the design proposal reviewed by seven independent agents

Status: consolidated result of an adversarial review round over
[design-sketch.md](design-sketch.md) and the research corpus in
[docs/research/](../research/). The seven source documents are
[audit-evidence.md](audit-evidence.md) (73 graded claims against the corpus),
[critique-redteam.md](critique-redteam.md) (severity-ranked attack),
[steelman.md](steelman.md) (strongest case, load-bearing analysis),
[feasibility-bend2.md](feasibility-bend2.md) (language capability, with probes),
[integration-baton.md](integration-baton.md) (orchestrator surface),
[integration-knowledge.md](integration-knowledge.md) (knowledge layer), and
[research-open-questions.md](research-open-questions.md) (external research). Each carries its own
citations; this document consolidates and ranks.

## Verdict

The proposal's mechanical core survives: the session-log invariants, the async operation layer, the
tool contracts, and the safety vocabulary are each code-verified in the corpus rather than asserted
([audit-evidence.md](audit-evidence.md) grading table). Three things do not survive: the program lane
and the self-extension loader are not expressible in Bend2 as written; the orchestrator plane
describes surfaces a seat cannot reach today; and the fork section contradicts what baton actually
calls fork. Two claims inside the sketch contradict the corpus, one comparison is cherry-picked, and
the load-bearing mechanism for long-horizon work is probably not the one the sketch names.

## What the review found

### The platform does not support two of the sketch's mechanisms

Bend2 at the pinned toolchain (2.0.25, `bendlang/bend@a4952426`) has no evaluator to call and no
runtime module loader; one C file per program with no separate compilation
([feasibility-bend2.md](feasibility-bend2.md) verdict, §"The pinned language"). Base ships no
process spawn, no fsync/rename/stat/mkdir, no TLS/HTTP/JSON/regex, and TCP is AF_INET only (:31).
The agent proved the gaps are closable through the documented C-effect contract — fsync plus
rename, an AF_UNIX round trip, an HTTP/1.1 client with incremental reads, a bounded completion pool,
`dlopen` of a runtime extension, and law-gated admission via `bend --check-only` failing an
importing program (:125) — but two consequences are structural:

- **The program lane must be out-of-process**: `bend <program>` as a child, nested tool calls
  re-entering the seat over a loopback socket, 60-110 ms per trivial call, and no type checking of
  the generated program (:212). The sketch's "executed natively in the same confinement, logging
  path, and operation layer" is not available.
- **Self-extension cannot add Bend2 code at runtime**: the tool set is a dispatcher `def` matched on
  a parameter, and "a table of tool closures cannot be invoked repeatedly" (:213). Expressible
  paths are declarative tools admitted as data, repository-level Bend2 tools gated by
  `bend --check-only`, and optional C-ABI modules via `dlopen`. Separately, a user-declared record
  is forgeable, so the checker cannot enforce capability authority (:31, :220) — authority must be
  enforced at the runtime boundary, and the sketch's "extensions inherit the seat's authority and
  cannot widen it" needs a mechanism, not a type.

The language also fixes the loop's shape: one self-recursive def carrying a state sum type, nested
matches on binders inside arms, `@unsafe` where an arm keeps waiting, no mutual recursion, no
`match` heading a `do` block (:214). Size is nearer the reference's 4,484 lines of Bend2 plus 714 of
C than "a few thousand lines, readable in an evening" (:221).

### The orchestrator plane describes surface that does not exist

The sketch names "the baton2 protocol" while describing the JavaScript line's objects
([integration-baton.md](integration-baton.md) §1): baton (Node, `impl/src`, REPL layer, MCP) and
baton2 (Bend2, no `impl/` tree) are different systems with different seats, tasking paths, and wake
paths. On the JS line, `repl.manifest` and `repl.binding` are kernel/embedded surfaces, so **no
external seat can commit cells today**; only `repl.cite` is ordinary/MCP, and the run boundary is
enforced on the brief path but not on the shipped MCP tool (:238-263, §5 item 1). The only grant is
`claimGrant {boardRunId, board}` — caveats, derivation lineage, subtree revocation, and
persistability are a proposal over a mechanism that does not exist (:322). Wakes are landed (the
brief wake block and `autoWake` are in code despite the doc saying otherwise), so the seat's
obligation is reading the wake block its brief carries plus an optional `swarm.watch` (:330).

### Fork has a different meaning than the sketch gives it

There are three mechanisms called fork: provider-session fork with a turn cursor, branch start with a
workspace snapshot and a fresh conversation, and resume of the same conversation
([integration-baton.md](integration-baton.md) §3). No operation copies a log prefix anywhere, and
`flush` in the baton code is stream flushing (`stream.omp.flush`, `_flushLedgerSync`); the
Fork-and-Flush method (arXiv:2610.07447) inherits workspace, complete task inputs, selected findings,
and native configuration with **no log prefix** (`bend2/src/coordinator/branching-model.bend:13`);
and the harness-state vector has no counterpart — what exists is a route version tuple carrying a
vendor CLI version (:317-321). The sketch's fork triple is therefore a *proposal to extend* baton's
branching record, not a description of it, and it should say so.

### Three internal contradictions

The evidence audit names them ([audit-evidence.md](audit-evidence.md) §"Internal consistency"):
compaction "expected never to fire" against the corpus's dormant-with-trigger position (NOOA installs
its summarizer by default at 75% of the window and keeps a reactive archive; NAC keeps a 70%
fallback) (:285); the catalog "written once and masked at decode" against runtime self-extension,
where masking is Manus's vendor-reported, provider-dependent claim while dsh's actual mechanism is a
catalog held identical with deltas admitted at turn boundaries (:292); and "no quotas, counters, or
step caps" inverting the corpus's recorded-parameters position (:305). Each has a stated
replacement.

### The evidence is weaker, and different, than the sketch implies

The NOOA comparison is quoted without the OpenCode row (78.6% at a similar call count and ~1.3M
tokens), which undercuts the cost inference, and all NOOA figures are paper-reported
([audit-evidence.md](audit-evidence.md) §"Vendor numbers"). The twelve-hour improvement evidence
belongs to writable-context and summarization postures, not the append-only projection posture the
sketch adopts ([context-language-models.md](../research/context-language-models.md) §5). The +7.7
edit ablation is 2024 GPT-4 Turbo on SWE-bench Lite, and the corpus records the gap shrinking across
model generations. Self-extension citations outrun their sources: dsh verifies that installing
requires authorization, not the digest-and-principal events the sketch describes, and
`harness.change` is an invented event name (:319).

The external research moved two things ([research-open-questions.md](research-open-questions.md)):
**bounding the context window steepened long-horizon decay** (logit slope -0.69 against -0.44,
p=3e-6, n=10,664), and the load-bearing driver of collapse is **per-step reliability**, not context
shape (arXiv:2609.01660) — which strengthens never-compacting while relocating the mechanism the
sketch credits. And the wall-clock half of the async bet is no longer unsupported: PASTE reports
43.5% task-completion-time reduction, TomasuLLM 1.27-1.35x with zero false accepts over 4,010 commit
validations, Speculative Actions up to 20% (:303). The token half remains unmeasured, as does
citation hand-off versus inline transfer.

### Two objections that stand on their own

The steelman's single strongest counter-argument ([steelman.md](steelman.md) §3): the proposal's
measured evidence and its novel mechanisms do not overlap. NOOA's number comes from in-process
pass-by-reference, which the sketch forfeits at both boundaries — tools run under OS confinement,
which NOOA's own limitations section names as trading reference semantics away, and every
cross-seat transfer serializes by value. What remains inside the seat is fx-shaped and commodity,
while the two genuinely novel mechanisms are the two the corpus records as unmeasured, and the plan
schedules their measurement last.

The safety formalist's objection ([research-open-questions.md](research-open-questions.md) §3,
arXiv:2606.26057): the four machine-checked authorization properties are process separation, a
structurally-only pre-action path, fail-closed at both levels, and externalized signed evidence. The
sketch's model-callable admission runs inside the seat's own address space and its evidence is
unsigned, so it fails the first two and leaves the model able to steer its own admission. The
mitigations available are orchestrator-side admission (which the grant plane could support),
attenuation-only authority, and signed admission evidence.

### The knowledge layer was mis-described, and its read path is dead code

Baton runs two knowledge stores, not one: the orchestrator's Cairn graph — 19 closed node types, 14
edge types, four groundings, repository-scoped over the append-only coordination ledger, records
minted by orchestrator derivation and admitted through one admit gate under a run lease — and the
Bend2 seat binaries' SQLite store with four scopes ([integration-knowledge.md](integration-knowledge.md)
§1-§2). Generation is orchestrator-derived or seat-authored under a prompt obligation; **no completion
gate exists on either line**, and the measured census shows `knowledge.promoted` four times, zero
elevations, zero admit-gate uses, and zero horizon reads (:§3). The seat's read path —
`recallPreview`, `serveKnowledge`, `knowledgeBriefingProvider`, `brief.knowledge` — is built, tested,
and called by nothing; today's seat reach is one bridge tool exposing `run.knowledge.seed` and
`evidence.search` (:§5). Two consequences for the sketch: promotion is the orchestrator's admit gate
rather than a statistical or review gate, and per-turn seat writes would multiply fence bumps and
collapse the candidate/admit separation, so emission must be settlement-time and rare.

## Amendment plan

Ranked by how much of the design changes if ignored. Items 1-2 are decisions only the operator can
make; the rest are edits.

1. **Choose one orchestrator line.** The sketch cannot address both. If the target is the JS line,
   §8 becomes a proposal for an orchestrator-side change (worker-scoped commit admission) plus the
   reachable half (cite, deref receipt, bounded render into the brief). If the target is Bend2/baton2,
   the REPL layer is absent and commit-and-cite has no substrate
   ([integration-baton.md](integration-baton.md) §1, §5).
2. **Decide whether commit-and-cite stays the differentiator.** With no seat-side commit lane today,
   the differentiating half of the design rests on an orchestrator change; the alternative is to
   ship the reachable half first and treat seat-side commits as a proposal with an owner.
3. **Replace the program lane specification** with the out-of-process lane: program and SDK written
   under the session directory, `bend <program>` as a child, stdout/stderr captured into the log,
   nested calls re-entering over a loopback socket so every effect passes the guarded pipeline, no
   authority held by the child ([feasibility-bend2.md](feasibility-bend2.md) §5 item 1).
4. **Replace the self-extension mechanism** with the two expressible paths: declarative tools as
   data (name, argument schema, argv template, permission target, writes declaration, digest) run by
   a compile-time-checked dispatcher, and repository-level Bend2 tools gated out of process by
   `bend --check-only`, with optional `dlopen` C-ABI modules. State that authority is enforced at the
   runtime boundary because Bend2 records are forgeable (§6 items 2-3).
5. **Add the durability effect family and the provider transport as named host layers.** Append with
   `O_APPEND` plus `fsync(file)`; directory fsync at creation, replacement, and rotation; temp-file
   plus `rename` for rotation only; a `flock` single-writer lock; `List<U32>` bytes for large frames;
   six named signatures for the C effect family; a TLS-linking C effect for the provider client as the
   only new third-party dependency (§2 item 4, item 5).
6. **State the loop-shape constraint in the design's own voice** — one self-recursive def with a
   state sum type per loop, nested matches inside arms, no mutual recursion, handles threaded through
   state (§4 item 3) — and revise the size target to the reference's measured floor (§1 item 10).
7. **Fix the fork section**: baton's three mechanisms, Fork-and-Flush's actual inheritance, the
   triple restated as a proposed extension, downgrade or delete "harness-state version vector", and
   refuse mismatches rather than running degraded ([integration-baton.md](integration-baton.md) §7
   items 3-4, 6; [critique-redteam.md](critique-redteam.md) §"What I would cut outright").
8. **Fix the orchestrator-plane claims**: REPL reachability, `repl.cite`'s real shape (one
   version-pinned read returning one binding row), grants as `claimGrant` plus a named orchestrator
   change, and the landed bounded alternative (a cited object rendered into the brief with untrusted
   framing) ([integration-baton.md](integration-baton.md) §8 items 7-8).
9. **Replace `harness.change` and the unimplemented digest/principal machinery** with the vocabulary
   that exists (request-header change reasons, `developer/message` deltas, route version tuple), and
   mark the extension-set and schema-hash components as design, not precedent
   ([audit-evidence.md](audit-evidence.md) §6 items 3, 8).
10. **Give compaction a trigger and a policy** instead of dormancy: proactive at 75% of the window,
    reactive on provider rejection, with pending-call carry-forward, the trigger stated as a
    boundary, and no-compaction demoted to a measurement arm
    ([audit-evidence.md](audit-evidence.md) §2 item 2; [critique-redteam.md](critique-redteam.md) §2
    item 1).
11. **Make the pending-operation state machine explicit**: states, caps, deadlines, heartbeat
    cadence, cancel semantics, lost-result semantics, process reaping, and a quiescence definition,
    because one never-settling operation otherwise holds the session open indefinitely
    ([critique-redteam.md](critique-redteam.md) §2 item 2; P1 finding).
12. **Gate completion on the workset's verification recipe**, recorded in the log before a
    completion receipt may be emitted. This is the cheapest response to the per-step-reliability
    finding ([research-open-questions.md](research-open-questions.md) §2; arXiv:2609.01660,
    arXiv:2609.04298 §3.4).
13. **Bound every reviewer's read**: no safety review, approval decision, or orchestrator inspection
    over a whole transcript; bounded windows with provenance pointers or checkpoint digests, given
    the 2x-30x monitor miss-rate increase past 800K tokens (§3; arXiv:2605.12366).
14. **Add divergence counters** — every switchable mechanism logs a write-side and a consumer-side
    counter, with a write lacking a consumer reported as an invariant violation, and silent
    mechanisms auto-excluded from analysis (§6; arXiv:2604.20938 §V).
15. **Add the speculative-prefetch switch** as a third async posture (predicted call runs in a
    copy-on-write sandbox and commits in trajectory order after validation) so the model-driven and
    harness-driven postures can be A/B'd, citing PASTE, TomasuLLM, and Speculative Actions, and note
    that Harbor's PASTE flag shipped without ever firing (§5).
16. **Name the measurement environments**: Harbor-Index for the promotion gate and campaign,
    LOCA-bench for the three context postures, Anthropic's infrastructure-noise calibration,
    Terminal-Bench's version discipline (§4, §8).
17. **Adopt the three-part record rule for hand-off artifacts**: decisions and constraints exact;
    repeated evidence as task-justified statistics; raw observations only where their effect is not
    reconstructible (§7; arXiv:2608.14528).
18. **Rewrite §11's knowledge bullet, add the knowledge read and emission rules, and state the
    pollution obligations** — orchestrator-derived Cairn as the standing store, a bounded
    provenance-framed read riding the dynamic tail rather than the catalog, settlement-time
    emission, and never per-turn writes ([integration-knowledge.md](integration-knowledge.md) §3-§7,
    items 1-7, 10).
19. **Fix the recorded-parameters bullet** (§11) to the corpus position — no ambient caps, with
    task-scoped step, token, and time parameters arriving with tasking, recorded, and enforced
    uniformly — and keep per-call timeouts as tool properties
    ([audit-evidence.md](audit-evidence.md) §5 item 5; [critique-redteam.md](critique-redteam.md) §9
    item 9).
20. **Apply the citation repairs** — pi §7 for the cut-point invariant, prime §9 for the
    orchestration graph, arcee's steering queue as the recorded counterexample rather than support,
    the spill mechanism attributed to fx with Unreal's capture files and arcee's `output_id` paging
    as variants, "replacement is the primary path" marked unmeasured, and fx §15 for the
    event-log-as-interface recommendation ([audit-evidence.md](audit-evidence.md) §9 item 9).
21. **Restate the safety argument against the four authorization properties**, moving admission
    outside the seat's address space where the grant plane allows it, declaring the residual risk
    where it does not, and signing admission evidence
    ([research-open-questions.md](research-open-questions.md) §1).
22. **Cut from milestone 1**: persistent self-extension, degraded-mode branch loading, the
    triple-basis fork, the emulation switches, grant derivation trees and caveats, the TLA+ gate,
    and the binary-size and startup CI gates; keep codec fixtures, fuzz, replay, crash injection,
    and permission-denial fixtures ([critique-redteam.md](critique-redteam.md) §"What I would cut
    outright"; [steelman.md](steelman.md) §2.2).
23. **Resequence so evidence precedes architecture**: pull the provider-contract check and the
    projection-bounding measurement into milestones 1-2 exit criteria; keep milestone 4 for the
    experiments that need the orchestrator ([steelman.md](steelman.md) §4 and item 2).

## Revised milestone ladder

1. Log, loop, four tools, headless seat completing a baton task; durability effect family; codec
   fixtures, fuzz, crash injection; provider-contract check (replacement versus second-item results
   on the target providers) and the projection-bounding measurement as exit criteria.
2. Async operation layer with the pending-operation state machine, quiescence, and loss handling;
   the async-versus-blocking A/B as its exit criterion.
3. Out-of-process program lane with targeted-test selection; the first compile-after-five promotion
   through the evaluation gate.
4. The orchestrator half, in the reachable order: cite and deref receipt with bounded render, then
   seat-side commit admission if the orchestrator change is taken; commit-and-cite E1, then the
   measurement campaign with the named environments.

Self-extension, branch capability promotion, and ensemble consequence machinery wait for evidence
from milestones 3 and 4.

## Open questions carried forward

The operator's two decisions (target orchestrator line; commit-and-cite as differentiator or
proposal). From the audits: whether admission runs orchestrator-side or in-seat; the growth boundary
for a permanently-append-only graph and for the seat's log; whether the knowledge read is evented or
served from cache; the commit cadence's interaction with receiver cache stability; the deref
representation bound for a first cross-seat read; whether a cross-scope dereference needs a defined
snapshot; and the Bend2 law-file drift recorded as unverified in the knowledge audit.