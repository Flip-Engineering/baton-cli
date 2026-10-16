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
  Critic refinement (live records knowledge-record:6f98ed93 PASTE,
  knowledge-record:35d58d15 TomasuLLM; earlier cec0a6f6/80f4579e
  superseded): PASTE 43.5% is v2 AND v3 (v1 says 48.5%; pin the version
  when citing); v1 metric wording is tool-execution throughput, v2/v3 is
  observed tool latency (genuine instability addition); 1.8x tool-latency
  is relative cross-baseline aggregate (1.71x ORION, 1.83x SpecFaaS);
  testbed is trace-driven serving simulation with no token or success
  metric (outcome equivalence only), blank venue; TomasuLLM
  one-step-prefetch reimplementation reaches only 1.16x vs own 1.27x.
  TomasuLLM boundaries: cost ~2.1s speculative compute per wall-clock
  second removed; committed chains never exceed four with depth sweep
  saturating at K=4 (default config depth six — distinct quantities);
  Terminal-Bench figure fixed-seed; 7 of 18 SWE-Marathon sessions
  timeout-capped at 6.0h; baseline is authors own Serial Pi harness;
  samples small and author-drawn (4010 records, 95% upper bound 0.075%);
  GPU-dependent tasks excluded. Evaluation rule: report seeds and seed
  variance; fixed-seed speedups do not establish robustness.
  R13 corroboration: critic independently found the short instruction at
  b1f006a6 and the long vocabulary in live orchestra task text, supporting
  the deployed-release-retains-long-form note.
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
- LIN-03 (evidence-lead verified from primary issue, per
  proposal-root guidance 1c1ad87b): public coordinator reproduction EXISTS
  and is attributed — [baton#785](https://github.com/Flip-Engineering/baton/issues/785):
  production binary sha256 d91c9e40... at b1f006a6, UID 986/GID 978,
  throwaway DB; worker-authored probe-link overwritten by sibling via
  knowledge relate (exit 0, author becomes sibling) while finding-content
  change refuses with finding-id-conflict (exit 2); deterministic link IDs
  derivable from public record IDs (agent-native.bend:212-215). Local
  /tmp evidence path unreachable from this runner; issue body is the
  primary record. Exact candidate amendment: §8 "public coordinator
  reproduction remains future work" must be replaced with this attributed
  result; relation protection stays proposed. Cross-link #785 (and #782 law
  drift, #696/#770 uncertain-effect recovery); open no duplicates.
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

## Round-2 critique fold-in (auditor T1-T4 + critic findings; synthesis pending)

- Q-ASYNC-01 v2/v3 pin (auditor T1, knowledge-record:235aed77): 43.5% is
  v2 AND v3 (refutes "only in v2"); v1 says 48.5% with throughput framing.
  1.8x is cross-baseline aggregate (1.71x ORION, 1.83x SpecFaaS). Rule: pin
  the version; record 48.5-to-43.5 revision as instability datum.
- Q-ASYNC-01 chain ceiling (auditor T2, knowledge-record:6d1d8fd7):
  correct form is committed chains never exceed four with depth sweep
  saturating at K=4 (default config depth six), not "no chain beyond four".
  Cost detail: 1.6M drafter tokens + 1,480 drafter GPU-seconds (~0.9x a
  baseline session budget), sandbox CPU +56%, framed as single-session
  latency not throughput efficiency.
- Q-ASYNC-01 adverse prior (auditor T3, knowledge-record:f28db20a): token
  half upgrades to unmeasured-with-one-measured-adverse-prior (2.1:1
  speculative-compute ratio in harness-driven posture); narrowing stands
  because bet 1 falsification concerns turn structure, unmeasured in all
  three papers. Transfer of the prior to model-driven async stays open.
- SEED-RULE-01 (auditor T4, knowledge-record:83ac7546 + critic principle
  5aefbef4): per estimate record seed count, spread, aggregation rule;
  paired/unpaired declared per delta with matching variance; a delta whose
  seed-level OR paired-difference CI includes zero recorded as within noise,
  never direction (reverse-critique qualify: paired-difference CI operative);
  seed values
  verbatim; single-seed figures barred from headlines; task-sampling seeds
  recorded with draw rule and count. Per-arm comparisons additionally state
  trial count, session seed as provenance identity (not variance control),
  provider-counted tokens, paired-difference SE with declared MDE;
  environments need calibrated resource floors/ceilings, version
  discipline, and MDE-sized suites. Session seed is join identity, not a
  reproducibility instrument (critic a0500338; provider noise up to 6pts,
  skepticism below 3pt gaps).
- Q-REL-01 status: UNDER REVIEW, not revised. Critic 87343990 supports
  per-step compounding but refutes the exclusion of context shape (28/36
  cells fit; reliability 0.58 first-third to 0.44 last-third; 16-step cap
  is API-budget lower bound; compressed regime strips prior reasoning;
  LOCA-bench + 2606.29718 show independent context effects with 10.6-13.3
 pt recovery). Amendment-12 framing must weaken to both-axes-causal
  pending reverse critique and deliberation.
- MON-01 (critic 06245f64): amendment 13 must cite incremental monitoring
  of sub-transcripts as the tested mechanism behind bounded reads
  (effective), not assert untested bounded windows; reminders help obvious
  attacks only; fine-tuning did not generalize.
- AUTH-02 (critic bb018e8e): four properties as checklist with exactly one
  machine-checked invariant (fail-closed decision function); attenuation
  and operator-key trust base absent/assumed; sketch admission fails
  properties 1-2 as audited.
- LIN-02 (critic 37385d10): §8 lineage/revocation are seL4 derivation-tree
  primitives (Mint subset rights; revoke removes derived); macaroons give
  attenuation + deref-time caveats only, no lineage/tree, credentials not
  capabilities; classic revocation is caretaker pattern. Correct citations:
  seL4 manual 3.1/3.2, NDSS 2014 macaroons.
- HAND-01 (critic a3af80ed): three-part record rule is construction
  guidance (Prop 4.1 conditional), not theorem consequence; theory
  motivates and bounds via log-loss bit budget (Prop 3.6, regression
  models only; adaptive trajectories excluded).
- BET2-01 (critic dc02ea8f): bet 2 must state crossover conditions (model
  capability, chain length, fan-out, atomicity), not direction: CodeAct
  strong-model-conditional with JSON beating it on atomic calls; PTC below
  baseline 3/14 models (-19.7 to -26.9pts, backslash-n mode), +18.8pts at
  chain>=12, JSON collapses past fan-out ~70 while PTC holds at 100;
  Anthropic 98.7% is worked example, not benchmark; LOCA-bench Table 2
  first controlled scaffold-level PTC gain (38.7 to 49.3).
- HARBOR-01 (critic b996a49f, auditor-T4 primary-confirmed): 42-to-26%
  timeout result is 9-model suite not 8-model eval; WebGL 96.4/20.5 figures
  are Devin/Fable 5 (auditor verified at tbench.ai primary page), audit
  mis-attributes to Claude Code/Opus 4.8; Harbor-Index headlines are
  single-rollout per cell, no CIs, no rollout seeds anywhere.
- T4-CLOSE-01: auditor T4 grading PASS on all twelve critic targets with
  notes (constant-choice sensitivity; per-step drift and PwC/Table-II rows
  accepted on record citations without independent re-read, limits
  preserved); both Supersedes relations justified against arXiv evidence
  fields. No headline must fall. Evidence-lead first-hand T4 pass
  concurred. Subordinate critique work complete on both workers; both
  completions confirmed.
- T4-FLAGS-01 (auditor T4 close-out, evidence-lead ADOPTS as corrections):
  5aefbef4 mixes paired and unpaired arithmetic — the ~500-tasks-at-
  3-trials figure reproduces unpaired variance against the declared
  rho-0.5 pairing (consistent paired figure ~105); relabel or correct
  before any headline use. Round-D comparator 15/89 vs 17/89 best-config
  figure must be reconciled against Table II before either enters a
  headline. Headline-bar list (six): unpinned PASTE 43.5; no-chain-beyond-
  four as configured (K=6); Harbor-Index 28.0/82-task suite without the
  single-rollout power caveat (~14pp 1-trial MDE); the 500-tasks MDE
  figure; the unreconciled round-D comparator; WebGL-to-Claude-Code/Opus
  attribution. Auditor T3 narrowed-Q-ASYNC-01 position and candidate-
  gating dissent preserved as recorded alternatives.
- NOOA-02 (critic 16922d3b): benchmark-agent description has no summarizer
  component while competitors use transcript summarization (bounds the
  no-compaction reading); "harness fingerprint" appears nowhere in CLM
  paper text (code-level fact only); 128K summarization 47.8 > CLM 47.3,
  only CLM+subagents wins at 50.2.
- SPEC-01 (critic 7e494efb): Speculative Actions end-to-end (54.7%/19.5%)
  is chess-only (5 runs x 30 steps); theory 50% ceiling (Prop 1);
  losslessness design-argued except explicitly-lossy OS-tuning extension.
- COUNT-01 (critic 392be786): HARBOR zero-counters are integration failure
  in a production harness, not PASTE refutation; strongest field case for
  write+consumer counters with silent-flag auto-exclusion.
- SEED-01 (runtime-lead sourced, evidence-lead ADOPTS): the earlier
  interpretation-forbidding instruction is marked SUPERSEDED-BY-RULING (not
  resolved); seed + ideation behavior is operator-requested, mandatory, and
  SHIPPED at native-initial-input.bend:10,14,19-21. Ideation is authored
  context, never evidence; initialization seeding stays separate from
  evaluation randomization.
- CIT-03 (runtime-lead self-correction, evidence-lead NOTES): correct
  harness-gate location set is control.bend:125,177,198,281 +
  delivery.bend:20. H-ADM-01 verified the IN-list mechanism at the
  receiver/start/turn/delivery gates; :177 not independently re-read here.
- LAW-DRIFT-01 (runtime-lead f36446ec + root D1 qualification): law gate
  fails at pin (LAW-01 reproduced); repository-act extensions must pass the
  laws relevant to that extension and target interface; whole-repo
  laws-green stays a recorded alternative with sequencing cost, not adopted
  sequencing. Cross-link baton#782.
- REL-LINEAGE-01 (root D5 framing, evidence-lead ADOPTS): compare
  identical-content retry (may stay idempotent) versus changed
  author/content collision (refuse, preserving original rows); link public
  reproduction #785 separately from the isolated SQL probe. Relation
  protection remains proposed.
