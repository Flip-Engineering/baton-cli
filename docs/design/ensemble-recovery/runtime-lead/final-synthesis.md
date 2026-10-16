# runtime-lead FINAL SYNTHESIS — Ensemble runtime-integration (proposal-deliberation)

Assignment: baton-cli issue #1 heavy-orchestra audit, runtime-integration lane (Bend2
feasibility + Baton contracts). Status: COMPLETE. Independent rounds, reciprocal critiques,
and peer deliberation finished; both workers' completion requests confirmed pre-reboot
(message:runtime-lead:23d329f0f6af997acb6f0463fe4d1701 to bend-feasibility;
message:runtime-lead:985355bc426a85e73675c90d556c92d8 to baton-contracts; worker
acknowledgments receive:316/317 retained).

## 0. Publication verdict

Root published the reviewed proposal at baton-cli commit 32f5f9217c953ebb04c63dcb6d8bcb5b90a91436.
I diffed the published design-sketch.md (SHA256 b49ab64a5464ce8f042c2321968a4a40c854c87f5d1dd660a365863a1d51f57a)
against the last reviewed candidate (reconciled.89360bd04154): every delta is an integration of
this lane's critique residuals — control-laws.bend and turn.bend named in the adapter change set
with the launch dispatcher's Claude fall-through called out and a refuse-before-launch test
required; completion-request mechanism honestly scoped (current coordinator carries an authored
body; per-operation pending-state report is proposed); TCP EOF semantics (peer close = empty
string, None{} = timeout-only) added; knowledge pull-only consumption clarified; managed-query
admission store named as the reuse candidate for named cells/versions/leases; toolchain fork
recorded as qualification:false diagnostic evidence with release qualification at PR #772;
follow-ups filed as baton-cli issues #2 (native seat integration), #3 (uncertain tool-effect
recovery), #4 (admitted artifact execution). No substantive disagreement with the published text
remains from this lane. Issue #1 stays open; the lane's residual dissent is in §6.

## 1. Worker round lineage (preserved)

- bend-feasibility (omp, zai/glm-5.3-flash): independent round report:1db006672cb3467c582934e5385fe3fb
  (twelve probes, retained outputs/exit codes; one process loss to the operator reboot retained as
  unknown-after-keeper-loss; recovered under its existing identity); critique round
  report:79abfe24304be7f1cbe4d9a89965bf64. Deliverables: deliverables/bend-feasibility/
  (FINDINGS.md, review-corrections.md, probes/p01-p12, critique/).
- baton-contracts (muse): independent round report:7a439ac72754d35ef2ead4f37811509c; feasibility
  critique report:07310197502aa0c9c517cc89669ac4c2; candidate critique
  report:e55c26f6f8509ea94c2a148be1e5bc46. Deliverables: deliverables/baton-contracts/
  (report.md, evidence.md, critique/, reciprocal/, scratch DB copy).
- runtime-lead independent findings: knowledge-record:d0920646549e4500cda9ed2247c8d1b5,
  ff6528be175ad8a2bf0c2c3f6020c6e2, dcfb7c75ac5f67ffd4f18df072720e46,
  2a3e50b883e5d1f186eb3bd930925824, d46edc1d2683955235f7696b55da6982,
  64806ea0afbf22857d8ea75df2b85156, f36446ec9d38b7c83897e63f19e341d0. Deliverables:
  deliverables/runtime-lead/ (amendments-r1.md, amendments-r2.md, interim-report-1.txt, probes/).

## 2. Reconciled conclusions (multi-witness)

- CLOSED HARNESS SET is the milestone-0 precondition for any baton-cli seat. The
  `('codex','omp','muse','claude-code')` admission list spans at least 8 SQL sites
  (control.bend:125,177,198,281; delivery.bend:20; commands.bend:196,:301; instance.bend:58;
  stop.bend:58), law-pinned generated SQL (control-laws.bend), the direct-turn predicate
  (turn.bend:1519) and the launch dispatcher (turn.bend:1001-1008, Claude as fall-through
  default). recruit stores harness as free text, so a novel harness registers and fails late.
  Self-correction retained: my interim report undercounted (five sites) and mislabeled two files
  (agent-native.bend → control.bend); corrected in amendments-r2.md R2-2.
- PROGRAM LANE: out-of-process only (no evaluator, imports resolve at check time, one C file per
  program). Interpreter checks before running (the prior audit's "no type checking of the
  generated program" is wrong for the interpreter lane; corrected in the published text). A
  JS-hosted bun-child evaluator is a demonstrated primitive (P10) but a separate process with
  untested authority and result-codec.
- SELF-EXTENSION: three expressible paths (declarative tools as data; repository-act law-gated;
  dlopen C-ABI); no runtime module loading; authority enforced at the effect/OS boundary because
  Bend2 records are forgeable (Lease.Mk{999} reproduced by failure-evaluation probe2).
- COMMIT-AND-CITE (proposal §8): proposed orchestrator dependency (#778), absent at the pin.
  Refined: the context/ managed-query machinery (bound-admission, artifact-sha binding,
  Submission* types) is an existing seat-reachable content-identity substrate to extend; missing
  pieces are named cells, version semantics, cross-seat deref receipts, lease/fence.
- RELATION LINEAGE: replaceable on caller-supplied id (knowledge.bend:288,296; deterministic ids
  per agent-native.bend:212-215); publicly reproduced on the production binary (baton#785);
  findings refuse via finding-id-conflict. Protection remains proposed (identical retry
  idempotent; changed author/content refused).
- DURABILITY: effect family primitives demonstrated on the pinned Linux toolchain in both lanes
  (P03; exit-2 tail was the probe's own unlink-after-rename, not a durability failure). The seat
  hot path (O_APPEND + per-commit fsync, flock, crash window, torn-frame repair) is unproven and
  so labeled. U32 file offsets force segment rotation past 4 GiB (EOVERFLOW, effs/file_size.c).
- REJECTED (preserved objection): bend-feasibility C3 alleged knowledge search/traverse read
  nonexistent nodes/edges tables. Refuted at exact source: nodes/edges are WITH RECURSIVE CTEs
  over the knowledge table (knowledge.bend graph_ctes:188-189; search_sql:207-210;
  traverse_sql:225-229; graph_read:236-242); corroborated by root's public Main9 reproduction
  (baton#779 comment) and my own scratch-DB probe (knowledge search on the retained DB copy exits
  0 with valid structured output; deliverables/runtime-lead/probes/knowledge-search-scratch.*).
  Its F4 severity upgrade loses that basis; F4 stands at its original grading (medium: the
  reachable store is the SQLite authored-kind store, not the retired JS-line Cairn graph).

## 3. Decisions with costs and preconditions

A. Seat admission (decided): new harness/bend2-player.bend + gate-set extension + turn.bend
   prompt/frame/settlement handling + control-laws lockstep (~15 edit sites + one 76-432-line
   module). Precondition: the seat speaks the native attempt contract (sealed ATTEMPT/prompt.txt
   input custody, stream reading, exit status). REJECTED: riding omp identity — falsifies route
   identity/telemetry and activates ~20 omp-specific String.eq feature sites against a foreign
   event stream. Law-pinned SQL makes partial gate edits fail the check — a protective feature.
B. Program lane (decided): interpreter child per call; compile-once reuse after promotion.
   Single-run platform-named costs: trivial program on this Linux/EPYC runner — check 0.353-0.642s,
   emit 0.414-0.420s, link 0.733-0.855s, native run 0.032-0.062s, interpreted 0.409-0.544s
   (bend-feasibility p11; design-lead 0.33-0.39s; runtime-lead hello probes); prior audit's
   60-110ms is darwin/arm64. Full-coordinator anchor: 2101.119s emit, 142,651,376 KiB RSS with
   opt-in diagnostics (build-result.json). These are single-run measurements, not constants.
C. Child authority (OPEN, highest-priority unresolved): socket re-entry mediates SDK-expressed
   effects only; a same-UID child retains ambient OS authority. Any authority claim requires OS
   confinement (rootless namespaces+seccomp / sandbox-exec) plus SDK protocol tests (framing,
   terminator, encoding, authentication) plus bypass/impersonation probes. UNTESTED by any lane.
D. Artifact identity (OPEN): admitted-bytes-to-executed-bytes binding unresolved;
   digest-then-pathname-exec is racy; an fd to a mutable inode is insufficient without a
   demonstrated protection contract. Evidence to establish, not a security fact.

## 4. Discriminating experiments (observable outcomes)

1. Confined-child authority probe: direct write outside writable roots, direct spawn, direct
   network from inside a confined bend child; observable: exact OS errno per attempt.
2. Crash-window replay: kill between external effect and result commit; observable: recovery
   classifies unstarted/running/retained/unknown; no blind reissue.
3. T11/T12: unsupported-harness turn refuses with control.bend:286-287's full string and never
   falls through to a Claude launch; a partial gate edit fails the law check.
4. Append+fsync hot path under mid-append crash: last-complete-frame recovery and
   writer-position latch refusal.
5. Async vs blocking with batching separated (declared sweep or one-result-per-turn arm):
   per-operation commit latency, reorder events, steering latency, provider continuation form;
   right-censored outcomes flagged; smallest resolvable paired effect declared per suite.
6. Relation-conflict contract post-#785: identical retry idempotent; changed author/content
   refused; original row preserved.

## 5. Unresolved dissent (preserved)

- Sequencing: bend-feasibility ranks the confined-child authority probe before the §12
  measurement campaign; baton-contracts ranks the admission gate first. My disposition: the
  authority probe precedes any lane that spawns generated code; the admission gate precedes the
  seat milestone. The underlying disagreement is recorded, not resolved.
- D1: SQLite knowledge-store growth/retention unbounded; no retention statements in
  knowledge.bend. Open.
- D2 (strengthened): seat knowledge write path has no role gate; author is an unchecked string;
  discipline is the only current gate. Mechanism-vs-discipline open.
- Redteam hard caps (critique-redteam.md:60-64) and failure-evaluation Attack-3-A1 per-call
  deadline: contrary to the operator ruling (no duration/token/step budget admits, pauses, stops,
  truncates or gates unfinished work; silence never settles; lost needs lifecycle evidence);
  preserved as dissent, not adopted. dsh's elapsed-deadline design
  (deepseek-harness.md:106,114,116) is an observed external design with no necessity proof.
- D4 (JS-line countersign): moot — the JS line was retired from the repository at 2b8449af
  (2026-10-02); closed by evidence, not vote.

## 6. Evidence classification

- Source-derived at b1f006a6 (file:line retained): harness gates, message_route gating,
  idempotent admission, receipt semantics, branch inheritance (branching.bend:64-73), relation
  upsert, Chan.recv signature (base.bend:231, no timeout), law-gate drift (#782), context/
  substrate shape, seed generation/instruction (native-initial-input.bend:10,14,19-21).
- Executed: runtime-lead hello.bend probe set and knowledge-laws exit-1 check and scratch-DB
  search (deliverables/runtime-lead/probes/); bend-feasibility's twelve probes;
  failure-evaluation's probes; #785's production-binary reproduction.
- Paper-reported (not re-measured): NOOA, CLM, PASTE, TomasuLLM (2.1s speculative-compute proxy;
  measured chains commit ≤4 vs configured K=6), Speculative Actions, ALITA-G, monitor study,
  reliability study — the published design states each with its configuration limits.
- Proposals: commit-and-cite, grants, fifth-harness adapter, confinement boundary, artifact byte
  binding, relation protection.

## 7. Limits of this synthesis

I did not rerun bend-feasibility's durability/socket probes; I verified retained outputs, the
root probe-evidence review, and independently reproduced the toolchain surface and cost class.
The 18,157-line context/ subsystem received structural review only. No full coordinator build
was performed (forbidden). The JS line was assessed only as retired reference material
(reproducible at 1e050e42). The published design's own claims were diff-reviewed, not re-derived
line by line beyond the deltas listed in §0.
