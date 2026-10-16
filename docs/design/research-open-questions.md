# External research on the sketch's unmeasured claims

Verdict: each of the sketch's three bets now has adjacent published evidence and none of it reverses a
bet; the strongest new challenge is to §6 self-extension, where a machine-checked authorization
formalism classes the sketch's model-callable admission path as a control inside the agent's own
address space, and to §3/§14, where a 2026 decay study reattributes long-horizon failure to per-step
reliability rather than context shape. Searched 2026-10-16; the corpus was assembled mid-October 2026,
so "new" means published since roughly 2026-10-10 plus items of any date the corpus missed.

Method: every claim was read from its named primary source during this session; numbers are quoted from
those sources. Aggregator sites (benchlm.ai, agent-harness.ai, benchgen.com, qaskills.sh) appeared in
searches, were unverified, and are excluded; vendor research is labeled and unverified items marked.

## 1. Async and streaming tool execution versus blocking

The corpus position survives in narrowed form: no published controlled comparison of the sketch's
specific choice — a transcript where the model ends its turn with work in flight versus a loop that
blocks on every call, same model, same tasks — was found. What now exists is a measured line of work on
overlapping tool execution with model generation; `docs/research/benchmarks.md` "Explicit unknowns"
records only Terminus's tmux design and Anthropic's background-command guidance as closest evidence.

- PASTE, "Parallelizing Tool Execution and LLM Generation for Low-Latency Agent Serving"
  ([arXiv:2603.18897](https://arxiv.org/abs/2603.18897), 2026-03-19; Microsoft lists it as "Act While
  Thinking"). Predicts concrete future tool invocations from recurring agent patterns and executes them
  speculatively while the LLM is still generating, isolating speculative results until the model
  confirms them. Reports 43.5% reduction in average task completion time and 1.8x lower observed tool
  latency across deep-research, coding, and scientific-agent workloads. Measures serving-layer latency,
  not transcript design, token cost, or success-rate effects.
- TomasuLLM, "Out-of-Order Speculative Execution for LLM Agents"
  ([arXiv:2609.38201](https://arxiv.org/abs/2609.38201), 2026-09-22). Drafts future actions, runs them
  in isolated copy-on-write sandboxes, and commits results in trajectory order only after validation.
  Reports 1.31x on 100 SWE-bench Verified tasks, 1.35x on 28 Terminal-Bench 2.0 tasks, 1.27x on 18
  SWE-Marathon sessions, zero false accepts across 4,010 audited records. Its motivation matches the
  sketch's premise: long tools dominate coding-agent latency while the agent idles.
- Speculative Actions, "A Lossless Framework for Faster Agentic Systems"
  ([arXiv:2510.04371](https://arxiv.org/abs/2510.04371), 2025-10-05). Faster models predict future
  actions that run in parallel and commit only when predictions match; up to 55% next-action
  prediction accuracy yields up to 20% latency reduction, with a cost-latency analysis.
- HARBOR, "Automated Harness Optimization" ([arXiv:2604.20938](https://arxiv.org/abs/2604.20938),
  2026-04-22) shipped a PASTE-derived flag in codex-py and it never fired: round D's post-mortem found
  the predictor's entry point was never wired into the runner, its counter identically zero, inside a
  configuration scoring 12/89 against 17/89 for the best configuration (§V).

Bearing on the sketch (design-sketch.md §4, §12, §14 bet 1): strengthens the wall-clock half of bet 1 —
three independent systems measure large latency gains from overlapping execution with generation.
Leaves the token-cost half unmeasured; none reports token or turn-structure effects. Adds a third
posture the sketch does not consider: harness-driven speculation with validated in-order commits,
adoptable as a speculative-prefetch flag. HARBOR's dead PASTE flag warns for §6: a capability that
contributed nothing because nothing counted its invocations.

## 2. Never-compacting operation at long horizons

The corpus's support is the CLM 12-hour result (append-only baseline stops improving inside the first
two hours while context-managing methods keep improving, `docs/research/context-language-models.md` §5)
and the Chroma context-rot report as background (`docs/research/deref-and-consistency.md` §1.2). Four
2026 papers sharpen or complicate this; none is in the corpus.

- "How Fast Do Agents Rot?" ([arXiv:2609.01660](https://arxiv.org/abs/2609.01660), 2026-08-31): nine
  models, four task families, five horizons, three context regimes, 10,664 analyzed trajectories. Task
  success follows a geometric law governed by a single per-step reliability parameter that saturates
  below 1; on the agentic loop every model fell from near-perfect to near zero within 16 steps.
  Degradation is driven by step count rather than context length: bounding the window steepened decay
  (logit slope −0.69 vs −0.44, p = 3e-6); projected reliability 0.42 at GAIA-length horizons, 0.24 at
  hundred-step horizons. Caveat: single author (physics.soc-ph); code and trajectories released.
- LOCA-bench ([arXiv:2602.07962](https://arxiv.org/abs/2602.07962), 2026-02-08; HKUST; open-source at
  [github.com/hkust-nlp/LOCA-bench](https://github.com/hkust-nlp/LOCA-bench)). Controls
  environment-state growth so context length scales while task semantics stay fixed, evaluating models
  and scaffolds including context-management strategies. Performance degrades as state grows; advanced
  context management substantially improves success rates — the first public platform for the A/B the
  sketch's instrumentation section plans.
- "Diagnosing and Mitigating Context Rot in Long-horizon Search"
  ([arXiv:2606.29718](https://arxiv.org/abs/2606.29718), 2026-06-29). Four flagship models, three
  benchmarks. Identifies premature termination — models give up or answer uncertainly long before
  exhausting the window — with a rate positively correlated with context length. Reanalyzes seven
  context-management methods as test-time-scaling strategies that reduce it to enable more exploration;
  behavior-aware parallel sampling adds 2.6-4.9%.
- "Classifier Context Rot: Monitor Performance Degrades with Context Length"
  ([arXiv:2605.12366](https://arxiv.org/abs/2605.12366), 2026-05-12; Martin and Roger). Opus 4.6,
  GPT 5.4, and Gemini 3.1 as safety monitors over coding-agent transcripts miss subtly dangerous
  actions 2x to 30x more often after 800K tokens of benign activity than in a short standalone
  transcript; periodic reminders partially mitigate.

Nothing found: no replication or rebuttal of the Chroma report's own experiments — secondary
discussion reiterates its conclusions, none reruns its battery. No controlled measurement of an
append-only agent beyond two hours; the closest evidence is Terminal-Bench Challenges' 12-hour runs
(§5.2), operational anecdotes rather than controlled comparisons.

Bearing on the sketch: strengthens the refusal to bound the window (§2/§3) — the one paper that
directly tests window bounding finds it worsens long-horizon decay, and the sketch's two-plane design
keeps the window append-only while values live outside it. Weakens the implicit §3 inference that
context management drives long-horizon reliability: the measured failure mode is per-step reliability,
and context management's benefit reframes as enabling more exploration (arXiv:2606.29718). Consequence:
gate completion on evidence — the verification recipe (§9) is the natural hook, currently a data field.
New obligation for §10 and §8: any check reading a long transcript degrades by up to 30x in miss rate,
so review must use bounded windows with provenance pointers or checkpoint digests.

## 3. Self-extending harnesses

The sketch's §6 admits four properties make self-extension "safe enough to leave available," and
`docs/research/synthesis.md` records that self-modification safety is unmeasured. Three published
treatments now exist; none is in the corpus.

- ALITA-G ([arXiv:2510.23601](https://arxiv.org/abs/2510.23601), 2025-10-27; follow-up to Alita
  [arXiv:2505.20286](https://arxiv.org/abs/2505.20286)). A generalist agent executes a curated
  target-domain suite, synthesizes candidate MCP tools from successful trajectories, abstracts them
  into parameterized primitives, deduplicates, and consolidates a curated tool box; at inference a
  retrieval-augmented selector admits only the tools a task needs. GAIA validation 83.03% pass@1 /
  89.09% pass@3 with ~15% fewer tokens per example.
- The Unfireable Safety Kernel ([arXiv:2606.26057](https://arxiv.org/abs/2606.26057), 2026-06-24).
  Formalizes four properties an authorization mechanism must satisfy for architectural control:
  process separation; pre-action enforcement on a structurally-only path; fail-closed at both request
  and system levels; externalized signed evidence verifiable outside the controlled system's trust
  boundary. Premise: any control inside the agent's own address space is reachable by inputs that
  influence the agent. A Rust implementation machine-checks the fail-closed invariant (Z3 SMT; Kani
  bounded model checking) and is evaluated against a self-modification seam: across 1,000
  self-modifications, all 704 attempts on the safety-critical core were refused with no escape.
- AgentTrust ([arXiv:2605.04785](https://arxiv.org/abs/2605.04785), 2026-05-06). Runtime interception
  of tool calls before execution (allow / warn / block / review verdicts, shell deobfuscation,
  multi-step risk-chain detection, MCP server interface); 95.0% verdict accuracy on a 300-scenario
  internal benchmark, 96.7% on 630 adversarial scenarios. Caveats: single-author preprint.

Bearing on the sketch (§6): strengthens the context-economy argument with published numbers — ALITA-G's
~15% token reduction from curated admission supports §6's claim, and its pipeline (harvest only from
end-to-end successful trajectories, parameterize, deduplicate, admit selectively) instantiates the
promotion gate where a task suite exists; its gate validates from successful trajectories, an
optimistic-bias risk the sketch's held-out-split gate (`docs/research/context-language-models.md` §4)
already avoids. It also challenges the admission path: fail-closed boundaries are present (via the dsh
lineage, §10) and evidence is logged but not signed nor verifiable outside the seat; the admission step
is model-callable inside the seat's own runtime, so it is neither process-separated nor on a
structurally-only path — the model that benefits from an admission can influence the inputs to the
check. The sketch's mitigations (attenuation-only authority, logged digest/principal/approval) are real
but are a different class of guarantee, and Prime's RCON incident (`docs/research/prime-agent.md`) is
the empirical instance. Nothing found: no production incident report involving runtime-admitted tools
beyond the Prime exploit; no benchmark prices refinement value against risk; no Bend2-specific analysis.

## 4. Cross-session context handoff between seats

The corpus covers Amp's operator-initiated handoff (`docs/research/no-compaction-harnesses.md` §5) and
states that no corpus system bounds a cross-session read and that episode-based handoffs are unmeasured
anywhere (`docs/research/arcee-nac.md` §8; `docs/research/deref-and-consistency.md` §5).

- "Handover of In-Context Learning State Across Session Boundaries"
  ([arXiv:2608.14528](https://arxiv.org/abs/2608.14528), 2026-08-14). Formalizes handover as transfer
  of a task-relative in-context-learning state, triggered by input limits, restarts, or delegation to
  another agent. Under an exogeneity condition, predictive equivalence characterizes the coarsest
  deterministic sufficient handover and yields a fixed-length bit requirement. Proposes a three-part
  record — store decisions and constraints exactly; use task-justified statistics for repeated
  evidence; retain original observations only when their effect is not preserved by those statistics —
  and quantifies the cost of writing the handover before the downstream query is known.
- Nothing found: no published measurement comparing citation hand-off against inline transfer (bet 3),
  no bounded cross-session read implementation, no shared-context-store evaluation with version
  pinning. The SAMEP protocol proposal ([arXiv:2507.10562](https://arxiv.org/abs/2507.10562)) is a
  located shape-only datapoint with self-reported unverified numbers (73% redundant-computation
  reduction, 89% context-relevance improvement). A vendor-blog cluster (mem0.ai, evermind.ai,
  heyclarity.dev) claims handoff degradation with no traceable methodology; excluded.

Bearing on the sketch: strengthens §8's core choice — hand-off artifacts, not the raw transcript —
with theory. The three-part record is a sharper content rule for plan/inventory/decision-record cells
than §8 gives, and it supplies the first formal answer to the sketch's commit-cadence open question
(§16): the cost of writing before the downstream query is known is now an analyzed quantity. Bet 3
remains unmeasured; the sketch's falsification design is the only plan on record to measure it.

## 5. Other findings the corpus lacks

### 5.1 Harbor Adapters and Harbor-Index

[arXiv:2609.04298](https://arxiv.org/abs/2609.04298) (2026-09-03; adapters and 0.3M trajectories
open-sourced). Eight models, each under two harnesses — cross-family Terminus-2 plus one native
harness (Codex, Claude Code, Gemini CLI) — across 54 benchmarks and 6,627 tasks, three trials each,
226B tokens, over $300K of compute.

- Model versus harness, model controlled: benchmark difficulty ICC 0.75; in a linear mixed model the
  model fixed-effect range (0.451) is 5.2x the harness range (0.087), with 6/8 model coefficients
  significant versus 2/4 harness coefficients (§3.2). Harness design matters but does not substitute
  for model capability.
- Native harnesses use fewer tool calls and output tokens than Terminus-2 and, matched task by task,
  cut the timeout rate from 42% to 26% (§4.3), partly because Terminus-2's bash-only action space
  lacks native image and web tools.
- Failure analysis over 6,028 trajectories (§3.4): wrong factual answers, algorithmic bugs, and
  hidden-test regressions dominate regardless of harness; Terminus-2's linear plan-execute-complete
  sequence lacks a verification-correction loop and is more vulnerable when iteration is required.
- Task quality: roughly one third of the hardest candidate tasks were rejected as broken rather than
  genuinely difficult; all four GAIA2 tasks reaching review had adapters that never fired the events
  the verifier waited on. Harbor-Index 1.0 is the audited residue: 82 tasks, 29 benchmarks, no
  configuration above 30% pass rate, strongest (GPT-5.5 with Codex) at 28.0%.

Bearing: this is the controlled harness-versus-model evidence the corpus's unknowns section says is
thin; it supports the sketch's reading that the loop is the primary instrument while cautioning that
harness deltas are secondary to model deltas. Harbor-Index is a ready-made affordable suite for the
sketch's promotion gate (§6) and measurement campaign (§12); the sketch assumes a suite must be built.

### 5.2 Terminal-Bench Challenges, 4.0, and continuous versioning

[Terminal-Bench Challenges](https://www.tbench.ai/news/terminal-bench-challenges) (2026-06-18):
long-horizon, token-intensive single tasks measured in days at $1k+ per task, 10k-500k LOC solutions,
no time or resource limits, multi-agent submissions welcomed. Initial 12-hour runs with Claude Code +
Opus 4.8 produced no significant improvement on a Rust compiler speedup task, logprob-chasing on an
inference-engine codegolf task, and 96.4% test coverage on a WebGL 1.0 renderer (20.5% on WebGL 2.0).
Two recorded failure modes: reluctance to delete large chunks and explore large solution-space
changes, and test-suite overuse — running full 20-minute-plus suites where targeted tests would do.

[Terminal-Bench 4.0](https://www.tbench.ai/news/terminal-bench-4-0) (2026-08-28): flat 8-hour agent
timeout on all tasks; resources calibrated by
[Anthropic's infrastructure-noise methodology](https://www.anthropic.com/engineering/infrastructure-noise);
8 tasks removed, 19 fixed; remaining errors mostly refusals and output-token-exceeded. Sonnet 5 used
21.6B tokens in its leaderboard run versus 6.5B for Opus 5. Terminal-Bench is now a continuous
benchmark with semantic versioning: major = re-run, minor = regrade, patch = reuse.

Bearing: the test-suite-overuse failure is an argument for the program lane (§5) the corpus does not
make — generated programs that select and run targeted tests are the direct countermeasure, documented
at 12-hour scale. The calibration methodology and version discipline belong in the measurement campaign
(§12, §13), and the Challenges format validates "no quotas, no step caps" (§11) as benchmark-viable.

### 5.3 HARBOR's instrumentation lessons

Beyond the case study (§1), HARBOR contributes mechanisms the sketch's §12 lacks: silent-flag
auto-exclusion (a detector prunes flags that demonstrably do nothing); requested-versus-realized flag
divergence as an observable invariant violation — the signature that caught two integration bugs whose
consumer counters were identically zero; and a cold-start correction for cross-session features. Its
B-versus-Oracle gap (17/89 best single configuration versus 81/89 for the union) shows feature
interactions dominate single-feature effects, an argument for the emulation-switch measurement plan.

### 5.4 Harness size datapoint: codex-py

HARBOR's test harness, codex-py, is a Python port of the OpenAI Codex CLI at roughly 52K lines
reaching parity on Terminal-Bench 2 with the roughly 649K-line Rust original (arXiv:2604.20938 §III).
The corpus size spectrum runs from mini-SWE-agent's ~100 lines to products in the hundreds of
thousands; 52K is the smallest documented production-parity port. The sketch's "few thousand lines,
readable in an evening" target (§1) sits between mini and codex-py; [INFERENCE] the target is
aggressive relative to the smallest documented parity-scale port.

### 5.5 METR Expenditure Horizon

METR introduced the expenditure horizon — capability as a function of resource input (tokens,
dollars, compute) rather than binary pass/fail at a time horizon
([metr.org](https://metr.org/blog/2026-07-21-expenditure-horizon/), 2026-07-21). The corpus covers
TH1.1 (`docs/research/benchmarks.md` §"METR" [20]) but not this metric. Bearing on §12: the sketch
already records token and cost per run; this framing is the publication-ready form of that data.

### 5.6 ACON and the posture map

ACON, "Optimizing Context Compression for Long-horizon LLM Agents"
([arXiv:2510.00615](https://arxiv.org/abs/2510.00615), Microsoft, ICML 2026) reduces peak token/memory
usage 26-54% and improves success rates over baseline compression, with up to 46% gains for smaller
models via a distilled compressor. The corpus's posture map
(`docs/research/no-compaction-approaches.md`) lacks this entry in the budget-the-history family.
HARBOR supplies its failure mode: ACON wired upstream of a tool-result cache stored the compressed
summary where later retrievals expected the raw output, and tasks needing line-level detail failed
(arXiv:2604.20938 §V). Bearing: validates the two-plane design (§3) — whole values live in the
process and spill files, so a compression gate cannot corrupt the durable record the way ACON
corrupted codex-py's cache; any future transform-on-commit path keeps this as the named anti-pattern.

## Summary of explicit gaps (nothing found)

1. No controlled A/B of model-driven async-first transcript design versus blocking execution;
   adjacent systems (PASTE, TomasuLLM, Speculative Actions) measure latency gains, none the
   transcript-cost axis.
2. No replication or rebuttal of the Chroma context-rot experiments.
3. No controlled measurement of an append-only agent beyond two hours; the 12-hour Terminal-Bench
   Challenges runs are operational anecdotes.
4. No production incident reports involving self-admitted tools beyond the corpus's Prime RCON
   exploit.
5. No measurement of citation hand-off versus inline transfer, and no bounded cross-session read
   implementation anywhere.

## Proposed amendments

Ranked by expected effect on the design if adopted.

1. **Restate §6's safety argument against the four authorization properties, and close what can be
   closed.** Where: design-sketch.md §6 bullet list. Add: the admission step must either run outside
   the seat's address space (orchestrator-side admission, which the grant plane already supports) or
   be declared a residual risk with mitigations named (attenuation-only authority, logged
   digest/principal/approval). Add signed admission evidence — digest, admitting principal, approval
   hash — verifiable outside the seat. Source: arXiv:2606.26057; corroborating incident: Prime RCON
   (`docs/research/prime-agent.md`). Reason: the current bullets answer "can the extension widen
   authority" but not "can the model steer its own admission"; a machine-checked formalism now names
   the difference.

2. **Gate completion on the verification recipe, not on transcript state.** Where: design-sketch.md
   §9 and §14. Make executing the workset's verification recipe a required step before a completion
   receipt may be emitted, with the recipe's execution recorded in the log. Sources:
   arXiv:2609.01660 (per-step reliability drives long-horizon collapse; context management does not
   fix it); arXiv:2609.04298 §3.4 (harnesses without a verification-correction loop fail on iterative
   tasks). Reason: the sketch's long-horizon posture rests on context economy; the measured failure
   mode is per-step reliability, which this gate addresses directly and cheaply.

3. **Bound every reviewer's read; never review the whole transcript.** Where: design-sketch.md §10
   and §11. Any safety review, approval decision, or orchestrator inspection operates over bounded
   windows with provenance pointers, or over checkpoint digests, never the full append-only log.
   Source: arXiv:2605.12366 (2x-30x miss-rate increase for monitors reading 800K-token transcripts).
   Reason: never-compacting makes transcripts grow, and the monitor-degradation result makes
   whole-transcript review a measurable liability.

4. **Adopt Harbor-Index as the external suite for the promotion gate and measurement campaign.**
   Where: design-sketch.md §6 (promotion gate), §12, §15 milestone 4. Where a task suite is needed
   and none is local, Harbor-Index 1.0 (82 audited tasks, 29 benchmarks, no configuration above 30%
   pass rate, one full run affordable) is the default external suite, citing its audit lineage (one
   third of candidates rejected as broken) over ad-hoc task sets. Source: arXiv:2609.04298 §4.
   Reason: the statistical gate requires a suite; one now exists, is cheap, and was audited for
   exactly the verifier defects that would confound promotion decisions.

5. **Rewrite bet 1's evidentiary status and add the speculative-prefetch flag.** Where:
   design-sketch.md §12 and §14. Bet 1's wall-clock half is no longer unsupported: cite PASTE (43.5%
   task-completion-time reduction), TomasuLLM (1.27-1.35x with validated in-order commits, zero false
   accepts over 4,010 records), and Speculative Actions (up to 20% latency reduction) as adjacent
   evidence, narrowing the bet's unsettled half to token cost and turn structure. Add a harness-side
   speculative-prefetch switch (predicted next tool call runs in a copy-on-write sandbox, commits in
   trajectory order after validation) beside the existing emulation switches so the model-driven and
   harness-driven postures can be A/B'd. Sources: arXiv:2603.18897, arXiv:2609.38201,
   arXiv:2510.04371.

6. **Add requested-versus-realized divergence counters and per-mechanism consumer counters to §12.**
   Where: design-sketch.md §12. Every switchable mechanism logs a write-side counter and a
   consumer-side counter; a write without a consumer is a reported invariant violation; silent
   (never-firing) mechanisms are auto-excluded from analysis. Source: arXiv:2604.20938 §V (two
   integration bugs invisible to a manual tuning loop were caught only by counter asymmetry). Reason:
   these are the two cheapest counters that separately caught real bugs in a comparable harness.

7. **Adopt the three-part record as the shape rule for hand-off artifacts.** Where: design-sketch.md
   §8. Decisions and constraints stored exactly; repeated evidence carried as task-justified
   statistics; raw observations retained only where their effect is not reconstructible from the
   statistics. The cost of writing before the downstream query is known is analyzed in
   [arXiv:2608.14528](https://arxiv.org/abs/2608.14528), which also formalizes the commit-cadence
   open question (§16). Reason: §8 names artifact types but not their content rule; the theory
   supplies one, and it agrees with the not-the-raw-transcript choice.

8. **Name the measurement environments: LOCA-bench for the context postures, Anthropic's
   infrastructure-noise calibration for the campaign, Terminal-Bench semantic versioning for harness
   versions.** Where: design-sketch.md §12 and §13. The three postures (append-only, projection-bounded,
   writable-mirror) can be measured on
   [LOCA-bench's controlled-growth platform](https://github.com/hkust-nlp/LOCA-bench); resource
   calibration follows [Anthropic's methodology](https://www.anthropic.com/engineering/infrastructure-noise);
   harness versions follow [the rerun/regrade/reuse discipline](https://www.tbench.ai/news/terminal-bench-4-0).
   Reason: the campaign's credibility depends on environment noise and version discipline; both now have
   published standards.

9. **Add targeted-test selection to the program lane's stated uses.** Where: design-sketch.md §5.
   Record the Terminal-Bench Challenges failure mode — agents run 20-minute full suites where
   targeted tests would do — and make selecting, generating, and running targeted test subsets a
   first-class program-lane use
   ([tbench.ai/news/terminal-bench-challenges](https://www.tbench.ai/news/terminal-bench-challenges)).
   Reason: the one documented 12-hour-scale operational failure the program lane directly addresses.

10. **Record the corpus's posture-map and benchmark-version updates.** Where: the parent's
    consolidation of `docs/research/` (not the sketch itself). Add ACON to the budget-the-history
    family with its cache-corruption failure mode; add the speculative-execution family (PASTE,
    Speculative Actions, TomasuLLM) as a new cross-cutting section; note that Terminal-Bench 3.0/4.0
    and Harbor-Index postdate the corpus's benchmark figures, so benchmarks.md's Terminal-Bench 2.0
    spread numbers no longer describe the current leaderboard.
