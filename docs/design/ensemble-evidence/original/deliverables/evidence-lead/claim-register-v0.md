# Claim register v0 (evidence-lead independent draft; worker verification pending)

Corpus: baton-cli @ 5941316491eb01d8794abddc5dcf1798801c4aaf.
Canonical source: postrelease-751-761 source @ b1f006a6308bbb00e29a24322e4f7d5164774470,
toolchain at build-root/toolchain-home/bend2. Grades a/b/c/d per audit-evidence.md.
Status: CONFIRMED = independently spot-checked; SUPPORTED = prior audit verified,
recheck delegated; PENDING = awaiting citation-auditor/research-critic.

## Mechanical core (provisionally SUPPORTED, survives)

- C-LOG-01..11: session-log invariants (item vocabulary, atomic tool-call
  status, turn-close reasons, call/result atomicity, truncation rule,
  intent journal, writer latch, idempotent inputs, crash/fork identity,
  in-flight fork FIXME, compaction shape). Grade a. My check: citations
  precise except pi cut-point cite should be pi.md §7 not §4; arcee spill
  generalization overclaims (fx-only content-addressing). Status SUPPORTED.
- C-CTX-01: two-plane projection economy (renderings sized by format,
  spill with preview+path, one serialization boundary, typed truncation).
  Grade a (fx half) / c (generalized halves). Status SUPPORTED with
  spill-attribution correction owed.
- C-ASYNC-01: async operation layer machinery (durable op records,
  stub contract, batched drain, head-of-line cursor, join handle,
  writer fences). Grade a. "Replacement is primary path" is unmeasured
  (unreal-agent.md §13 open question). Status SUPPORTED minus that sentence.
- C-TOOL-01: tool contracts as data, edit-tool machinery, program-lane
  contract terms. Grade a. Status SUPPORTED.
- C-SAFE-01: safety vocabulary (closed outcome union, invocation-only
  approvals, content-backed undo, no-registry). Grade a/b. Status SUPPORTED.

## Quantitative justifications (CONTESTED, do not survive as stated)

- Q-NOOA-01: "NOOA 82.2% at ~28 calls/1.1M vs 66 calls/2.2M". Paper-reported,
  OpenCode row (78.6%, similar calls, ~1.3M) omitted. Correction: quote all
  three rows, label paper-reported, separate architecture claim from economics.
- Q-12H-01: twelve-hour improvement evidence belongs to writable-context and
  summarization postures, not projection-bounded append-only. Correction:
  claim only "some context management beats none at twelve hours".
- Q-EDIT-01: +7.7 edit ablation is 2024 GPT-4 Turbo on SWE-bench Lite; gap
  shrinks across generations (7.5 to 4.8). Correction: date and scope it.
- Q-CLM-01: skill evolution 38.3 to 74.2 is paper-only; gate mechanism is
  code-verified. Correction: lean on the gate, not the number.
- Q-ASYNC-01: wall-clock half of async bet now has adjacent support (PASTE
  43.5%, TomasuLLM 1.27-1.35x zero false accepts/4010, Speculative Actions
  ~20%); token half unmeasured. Correction: narrow bet 1, add
  speculative-prefetch third posture for A/B.
  Critic refinement (knowledge-record:cec0a6f6): PASTE 43.5% is v2 only
  (v1 says 48.5%; pin the version when citing); 1.8x tool-latency is
  relative to weaker-baseline SpecFaaS; testbed is trace-driven serving
  simulation with no token or success metric (outcome equivalence only),
  blank venue; TomasuLLM one-step-prefetch reimplementation reaches only
  1.16x vs own 1.27x.
  TomasuLLM boundaries (knowledge-record:80f4579e): cost ~2.1s speculative
  compute per wall-clock second removed; no chain commits beyond four
  actions; Terminal-Bench figure fixed-seed; 7 of 18 SWE-Marathon sessions
  timeout-capped at 6.0h; baseline is authors own Serial Pi harness;
  samples small and author-drawn (4010 records, 95% upper bound 0.075%);
  GPU-dependent tasks excluded. Evaluation rule: report seeds and seed
  variance; fixed-seed speedups do not establish robustness.
- Q-REL-01: per-step reliability drives long-horizon collapse, not context
  shape (arXiv:2609.01660; logit slope -0.69 bounded vs -0.44, p=3e-6,
  n=10,664). Consequence: gate completion on verification recipe; bound all
  reviewer reads (monitor miss-rate 2x-30x past 800K, arXiv:2605.12366).

## Platform expressibility (CONFIRMED against pinned toolchain)

- P-PROG-01: in-process Bend2 program lane not expressible (no evaluator,
  no runtime module loader; one C file per program). CONFIRMED via
  feasibility probes + my spot-checks (AF_INET-only TCP, no File.sync).
  Replacement: out-of-process lane (`bend <program>` child, socket
  re-entry, 60-110 ms/call, no run-time type check).
- P-EXT-01: runtime Bend2 module admission not expressible; capability
  records forgeable (LANG-F-28). CONFIRMED in principle; full recheck
  delegated. Replacement: declarative tools as data + repository-level
  Bend2 tools gated by `bend --check-only` + optional dlopen C modules;
  authority enforced at effect boundary. Model-callable admission fails
  two of four machine-checked authorization properties (arXiv:2606.26057);
  move admission outside seat address space or declare residual risk with
  signed admission evidence.
- P-SIZE-01 (auditor-restated, knowledge-record:4e21a4c8, S2): the cited
  4,484 lines Bend2 + 714 C describe the foreign KIT checkout, not the pin;
  at b1f006a6 the reference measures 25,258 .bend lines plus 8,059 lines
  authored C (process-spawn.c 5,192; adapters player-named 193 + 239 law
  lines; unmentioned context subsystem 47 .bend + 2 .c). Language-capability
  claims verify pin-exact so feasibility verdicts stand, but the size-floor
  argument (audit-findings amendment 6) must be restated against a named
  snapshot or a seat-scope subset — the grown reference is orchestrator
  scope, no longer a clean comparable. Companion attribution error:
  json/canonical.bend:11-18 states THREE checker shape rules, not five.
- G-RECHECK-01 (auditor-sourced, knowledge-record:a17360cb): grading table
  68/73 OK, 5 imprecise, 0 wrong; C1-C7 verbatim-confirmed. Imprecise-row
  corrections: row 18 ToolHistoryProjection refusal is dsh §5.1 not §10;
  row 31 fx ToolSpec lacks result-representation/timeout fields (those live
  on the §6 shell action schema); row 34 7.5-to-4.8 shrink pairs different
  scaffolds (4.8 is live-SWE-agent minus mini); row 66 benchmarks unknowns
  covers only async-vs-blocking, program-lane/citation unmeasured statuses
  live in context-networking/deref docs; row 72 7-fuzz count is unreal §2
  with golden fixtures §1, not §6 alone.
- R-RET-02 (auditor-completed re-resolution, knowledge-record:45ec0ab1):
  all 44 baton2-cited paths re-derived at b1f006a6 — 41 transfer exactly,
  3 with correction (architecture.md:234-241 is missing-conversation
  recovery, not resume-same-conversation; branching-ensembles.md:35-38
  ancestor chaining is schema-only, word absent from doc;
  branching-model.bend:13 omits trailing created column). Verdict-critical
  impl subset re-resolved at 1e050e42 transfers exactly (19 types :191, 14
  edges :193, four groundings :195; recallPreview zero callers;
  serveKnowledge defined-and-delegated with zero callers;
  knowledgeBriefingProvider null-default, no in-repo supplier;
  brief.knowledge rendered never set; MAX_REPL_BINDING_ITEMS=512; claimGrant
  board+boardRunId; repl.manifest/binding kernel-embedded, repl.cite
  ordinary-MCP; limits 8 items/2048 bytes). knowledge-laws.bend drift
  confirmed on all three counts. Residue: ~30 impl-internal line ranges
  scout-characterized, not individually re-read, no contradiction surfaced.

## Orchestrator plane (SUPPORTED by integration-baton/integration-knowledge)

- O-LINE-01: sketch names one "baton2 protocol" but describes JS-line
  objects; REPL layer absent on Bend2 line. Must choose one line (§1 split).
- O-COMMIT-01: no external seat can commit cells today (manifest/binding
  kernel/embedded; only repl.cite ordinary/MCP; run boundary unenforced
  on MCP tool). Commit-and-cite needs orchestrator-side worker-scoped
  admission; ship reachable half (cite, deref receipt, bounded render) first.
- O-FORK-01: three baton mechanisms called fork (provider-session fork,
  branch start, resume); no log-prefix copy anywhere; Fork-and-Flush
  inherits workspace+inputs+findings+config with no log prefix
  (CONFIRMED at branching-model.bend:13-17). Triple restated as proposal.
- O-KNOW-01: two stores (Cairn graph, seat SQLite); no completion gate
  either line; census knowledge.promoted x4, zero elevations/admits/reads;
  seat read path built, tested, called by nothing. Promotion is the
  orchestrator admit gate, not statistical/review gate; emission
  settlement-time and rare, never per-turn.

## Internal contradictions (SUPPORTED, corrections owed)

- I-COMP-01: "expected never to fire" vs dormant-with-trigger corpus
  (NOOA 75%, NAC 70%, Unreal per-model). Give compaction a trigger+policy.
- I-CAT-01: catalog "written once, masked at decode" vs runtime
  self-extension. Pick one mechanism with evidence class stated.
- I-QUOTA-01: "no quotas/counters/step caps" vs recorded-parameters
  corpus position. Fix to: no ambient caps; task-scoped budgets arrive
  with tasking, recorded, enforced uniformly. (Operator requirement
  preserved: no arbitrary ceilings invented by the seat.)
- I-STEER-01: steering cite belongs to unreal §3, arcee §2 is the
  counterexample. One-line fix.
- I-CITE-01: miscitations rows 4,14,23,26,39,61 per audit-evidence §C7.

## New rows from deliberation round 2 (evidence-lead verified first-hand)

- R-RET-01 (P1, CONFIRMED): the JS line was deliberately retired by
  2b8449af (2026-10-02, "Use the native coordinator source and contributor
  entry points"), fourteen days before the pin; HEAD has no `impl/`.
  Register rule: JS-line rows are labelled RETIRED (reproducible at
  1e050e42, evidence about a superseded system), never cited as current.
  Consequence: target-the-Bend2-line decision strengthened.
- H-ADM-01 (P1, CONFIRMED): native turns admitted only for
  {codex,omp,muse,claude-code} (control.bend receiver_admitted,
  start_admission, turn_admission_sql; delivery.bend native_receiver_sql);
  recruit.bend stores harness as free text, so refusal is late
  (turn_admitted dies on dispatch). The sketch's Bend2 seat cannot be
  driven today. Missing milestone-1 decision: match an existing adapter
  protocol vs add harness/bend2-player.bend plus admission-set and
  settlement changes (change set and cost owed to runtime-lead;
  corroborated by baton-contracts).
- I-QUOTA-02 (SUPERSEDED by I-QUOTA-03): earlier no-ambient-caps plus
  recorded-and-enforced task parameters position withdrawn.
- A-ALITA-01 (auditor-sourced, knowledge-record:1ba48071, MINOR):
  research-open-questions.md:105-106 invents an Alita-G deduplication
  stage (zero regex matches for dedup in arXiv:2510.23601; §3.3 preserves
  implementation diversity). Curated-consolidation and retrieval selection
  confirmed; review conclusion survives. Wording repair only.
- A-ACON-01 (auditor-sourced, knowledge-record:59d0ee1e, MINOR):
  arXiv:2510.00615 reports 26-54% peak token-usage reduction, not
  token-and-memory; the 45.6% EM figure is configuration-specific
  (Qwen3-14B with distilled compressor). Posture-map entry and
  cache-corruption failure mode unaffected. Precision repair only.
- R-RET-01 convergence: auditor finding 126be218705 independently
  reproduces the retired-not-stale ruling with transfer-or-break rule.
- I-QUOTA-03 (ROOT-DIRECTED, per proposal-root-review:cf9b744d): no
  runtime step/token/time quota or ceiling may control admission,
  continuation, or unfinished work — ambient or task-scoped; a
  task-scoped budget or timeout doing so is an explicit design conflict.
  Budget/quota state is recorded and reported ledger fact only, never an
  enforcement gate; provider quota failures are observed outcomes retained
  and reported to the Conductor; policy-driven parking is not accepted.
  Per-call tool timeouts retained as tool safety properties bounding
  single effects, not task caps. Consequence: audit amendment 19 and
  redteam P2 enforcement language are explicit design conflicts, not
  recommendations — recorded as live dissent against the prior audit
  until the proposal text is corrected.
- TIME-01 (ROOT-DIRECTED, per proposal-root-timeout-review:ad10e418,
  SUPERSEDES the per-call-timeout allowance inside I-QUOTA-03): Baton must
  not require a duration estimate nor enforce any duration/token/step
  budget to admit, pause, stop, truncate, or gate unfinished work; calling
  a limit a tool property does not remove the conflict. Compliant
  four-way distinction: (1) actual provider/OS rejection, disconnect,
  process exit, or externally enforced limit, retained with provenance and
  unfinished state; (2) explicit authorized cancellation (model for its own
  operations, Conductor stop authority over the seat); (3) an observation
  wait returning while the operation remains owned and running
  (prime-agent.md:45 collect pattern); (4) finite benchmark measurement
  conditions (research-open-questions.md:194-212). None establishes a
  required runtime cap: dsh elapsed-timer abort is observed external
  design without necessity proof (deepseek-harness.md:106,114,116);
  unreal-agent.md:46 keeps pending calls alive with informational
  heartbeat; critique-redteam.md:60-64 caps are conflicting policy, not a
  demonstrated prerequisite. Elapsed silence alone never establishes lost;
  retain unknown/pending unless concrete lifecycle evidence supports lost.
  Live consequences: amendments A1 per-call-timeout sentence and A2 "only
  automatic termination" clause need recast to observation-wait semantics;
  A2 already-correct removals (timed_out state, runtime cancel/park) stand;
  `lost` requires lifecycle evidence, not age.
  TIME-01 already carries the timeout half design-lead asks for (no required
  duration estimate; admit/pause/stop/truncate/gate; silence stays unknown;
  dsh:106,114,116 + unreal:46 + roq:194-212 + redteam:60-64 cites) — no
  register change needed on that ask. failure-evaluation S7.2/S7.5 and
  correction 5 (recorded deadlines auto-marking lost, head-of-line deadline)
  are CONTESTED under TIME-01, not adopted as settled.
- LAW-01 (P1, evidence-lead reproduced): knowledge-laws.bend --check-only
  exits 1 at b1f006a6 on law/module schema mismatch (probe retained at
  deliverables/evidence-lead/probes/law-gate/ with rc and revision). The
  seat knowledge store fails its own admission gate at the pin.
- WAIT-01 (P5, evidence-lead corroborated): Base has zero select/race/
  timeout/deadline vocabulary (grep count 0); only IO.sleep, IO.now, and
  blocking Chan.recv. Idle-cap/grace-window vocabulary presumes a wait
  mechanism the language lacks and must name it (observation wait per
  prime-agent.md:45 or external lifecycle signal).
- LIN-01 (S6, evidence-lead confirmed): knowledge_relations rows keyed by
  caller-supplied id overwrite author/source/relation/target on conflict
  (knowledge.bend:288), so relation lineage is rewritable by the recorder.
  (design-lead verification; agent-native.bend:215 caller-id vicinity.)
  Lagging design locations (per runtime-lead amendments-r1.md, CONFIRMED):
  revised-design-text.md §11 "enforced uniformly" (replacement: amendments
  A1) and §4 per-class caps/recorded deadlines (replacement: amendments
  A2). Register needs no further change; the design text does.
- AUTH-01 (design-lead/runtime-lead sourced, evidence-lead CONCURS):
  socket re-entry is routing, not confinement; "child holds no authority
  the seat did not grant" unsupported — same-UID child keeps ambient OS
  authority outside the SDK. Actual boundary (OS sandbox profile, loopback
  only, explicit writable roots, metadata read-only) marked UNTESTED;
  discriminating probe: direct write outside roots + direct spawn from
  inside the child, recording what the OS denies. Until it runs, no
  routing-bounds-all-effects implication. (amendments-r1.md B;
  design-lead knowledge-record:f1b5ab64.)
- CIT-02 (CONFIRMED first-hand): no bend2/src/host/session-lock.c at
  b1f006a6; SessionLock effect declared in session-lock.bend importing
  ./process-spawn.c, flock(LOCK_EX|LOCK_NB) at process-spawn.c:2438
  (also sqlite.c:881, text.c:86). Prior audit session-lock.c:55 is a
  revision-mismatch artifact. Replacement per amendments-r1.md C;
  §7 behavioral inheritance additionally needs branching.bend:64-73 plus
  branching-ensembles.md, cited schema-vs-behavior.
  (design-lead knowledge-record:ae1b94b0; runtime-lead C.)

## Strongest case for the proposal (preserved, not conceded)

Steelman §3 attack is load-bearing: measured evidence (NOOA number via
in-process pass-by-reference) and novel mechanisms (async-first loop,
commit-and-cite) do not overlap; confinement forfeits reference semantics
at both boundaries; measurement is sequenced last. Response is
resequencing (economy + provider-contract checks to milestones 1-2 exit
criteria), honest cross-turn residency scope (standing workset + spill
handles only), and the E1 experiment ladder — not dismissal. Dissent
preserved for deliberation with design-lead/runtime-lead.
