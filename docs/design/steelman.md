# Steelman: the strongest case for the baton-cli design sketch

Verdict: every major choice in the sketch is supported either by a measured result or by independent replication across at least three harnesses in the corpus, and the two choices that rest on neither — the async-first loop and citation hand-off — are declared bets with named falsification conditions (design-sketch.md §14). The design's weakest joint is evidentiary sequencing, not architecture: it builds the layers that depend on its bets before it measures the bets.

Load-bearing core: five elements — the turn-enclosed append-only session log, the two-plane projection economy, the async operation layer, the fork contract, and the commit-and-cite orchestrator plane. The promotion gate, the ensemble-consequence machinery, the grant-caveat apparatus, the TLA+ program, and the binary-size CI gates are deletable from the first milestone without loss.

## 1. The steelman, choice by choice

### 1.1 Keeping bulk out of the transcript is the best-measured result in the corpus

Claim: the design's context shape (§3) is the one mechanism the corpus backs with a controlled, same-model, same-agent number, plus two independent replications in kind.

- The measurement: NOOA reaches 82.2% on SWE-bench Verified at roughly 28 model calls and ~1.1M tokens per task, against Pi's 78.2% at 66 calls and 2.2M tokens, with OpenCode at 78.6% at a similar call count and ~1.3M (nooa.md §3.5). The stated mechanism is the design's two planes: tool outputs stay whole outside the transcript, and the transcript grows only by bounded previews, errors, and model-written text (nooa.md §3.5).
- Replication one: the long-horizon survey identifies "values or verbatim logs outside the context, with pointers back" as the load-bearing stage in every harness that has one (no-compaction-harnesses.md §9).
- Replication two: in twelve-hour containerized runs the context-managing methods keep improving across the full window while the append-only base harness stops improving inside the first two hours (context-language-models.md §5, EdgeBench-10 at a 128K budget).
- The sketch's specific form is the strongest version of that consensus: renderings sized by their format, typed truncation that is never silent (context-networking.md §3.2), spill to content-addressed files with preview plus path (fx.md §3), and serialization at exactly one durability boundary (nooa.md §3.4).
- The cache corollary holds the same way. A byte-stable static prefix plus an append-only event stream is what makes each turn reuse the previous prefix computation (nooa.md §3.5), and the sketch adds the one rule the corpus shows is required to keep it: the tool catalog is written once and masked at decode, because a definition change invalidates the prefix from that token onward (no-compaction-approaches.md §1; deepseek-harness.md §10).

### 1.2 Async is the one lever that acts on transcript growth and wall-clock at once

Claim: the design's §4 mechanism — async-first execution plus batched turn commits — attacks the multiplier the corpus actually measures, and the absence of a published A/B is an argument for the instrument the sketch ships, against the sketch's own declared bet.

- The multiplier is the call count. NOOA's advantage over Pi is primarily a call-count advantage, 28 versus 66 calls at matched quality (nooa.md §3.5), so any mechanism that absorbs several completions into one turn acts on the same axis.
- Unreal Agent supplies the concrete machinery the sketch adopts: the running-stub contract that lets a turn end while work runs (unreal-agent.md §5), grace windows that coalesce nearly simultaneous completions into one turn (§5), and idle-cap draining that commits arrived inputs and operations together (§3).
- The wall-clock side is supported by the benchmark record: Terminal-Bench tasks include kernel builds and server configuration where a blocking wait wastes wall time; Terminus's tmux design lets the agent run background jobs and extra shells; Anthropic's own tool guidance instructs backgrounding long-lived commands (benchmarks.md §Terminal-Bench, §Synthesis item 6).
- The honest boundary: no published controlled streaming-versus-blocking comparison exists (benchmarks.md §Explicit unknowns; synthesis.md §328-329). The sketch answers the gap by shipping the emulation switch (design-sketch.md §12) and declaring bet 1 with its falsification condition (§14).
- An unmeasured lever with an instrument attached is a better position than either a blocking loop with no lever or an async loop with no instrument. The corpus also records what the blocking posture costs: stateless per-action execution is incompatible with streaming tool execution and orchestrator-side live output (minimal-harness-survey.md §What does not transfer).

### 1.3 Turn enclosure is the commit point six operations share

Claim: three harnesses converged on the turn as the unit of consistency by different routes, and in baton-cli that joint carries six operations rather than three.

- DeepSeek's harness appends `turn/end` in a `finally` block that requires a reason on every exit path, heals failed steps in the log rather than in memory, and synthesizes crash-repair closers in the same shape as live ones (deepseek-harness.md §1.1).
- Pi makes one assistant response plus its complete tool-result batch the atom for persistence and compaction cut points, and fails every pending tool call when output truncates (pi.md §4).
- Unreal Agent persists tool-call status atomically with the operations it waits for, closing the translation-succeeded/dispatch-crashed window (unreal-agent.md §6).
- The synthesis records the convergence: turn boundaries are the only mutation points for fork, compaction, and delivery (synthesis.md §Cross-harness highlights).
- In baton-cli the joint carries more weight than in any single-harness design, because six operations resolve there: crash repair, fork cuts, compaction cuts, steering delivery, hand-off commits (§8 commits cells at turn boundaries), and extension registration (§6 registers at a turn boundary).
- One shared commit point with one validation discipline lets all six be correct for the price of one mechanism; per-operation commit points would multiply the crash windows the log invariants exist to close.

### 1.4 The minimal loop is what the benchmark record actually prices

Claim: the benchmark record rewards interface quality and penalizes tool proliferation, and the sketch takes exactly the priced additions.

- The loop is the primary instrument: mini-SWE-agent scores above 74% on SWE-bench Verified with a bash-only loop and lands within 3-8 points of the best scaffolds on the same frontier models (benchmarks.md §mini-SWE-agent, §Synthesis item 1).
- The same-model harness spreads of 8-20 points on Terminal-Bench 2.0 (benchmarks.md §Harness-vs-harness numbers) measure harness quality — reliability, edit discipline, context management. They are the argument for getting those properties right, and the ablations locate them: a dedicated edit operation is worth +7.7, linting guardrails +3.0, summarized search +6.0, while added narrow tools score below having none (iterative search −6.0; RAG 2.67% against 18.0% for the interface-centric design) (benchmarks.md §Published harness ablations).
- The sketch takes the priced additions and states the rule: the edit tool is the one tool with real internal machinery, outputs are bounded and summarized, and "nothing further is added until a measured gap argues for it" (design-sketch.md §5) — benchmarks.md's own design guidance (§Core architectural concepts 2 and 6).
- The survey adds the forward-looking reason: the orchestrator-inbox tool is the differentiator, and no surveyed harness treats the orchestrator as a tool surface — it is the closest thing to an open design slot (minimal-harness-survey.md §What transfers).
- Terminus's trace analysis supplies the failure model the minimal loop avoids: 77% of OpenCode's failed GPT-5.5 trials terminate within ten steps, against NOOA's validated termination contracts (nooa.md §5, Terminal-Bench row).

### 1.5 Commit-and-cite is the one unoccupied slot in the corpus's map

Claim: of everything in the sketch, commit-and-cite is the piece with zero competition in the corpus map and an existing substrate underneath it.

- The context-networking evaluation rules the weak reading of native context passing coherent — transfer with the transcript body left out of the envelope — and names its correction precisely: passing is by value at the commit point, by reference only in the address (context-networking.md §5.1).
- What the composition needs is a substrate, and the evaluation's finding is that the missing substrate is exactly what baton's REPL layer already provides: versioned content-addressed bindings, principal-pinned admission, a citation grammar, and settled-only resolution (context-networking.md §2.2, §5.1).
- The same report's gap list puts a baton-cli-shaped hole first: no surveyed harness emits its context state as orchestrator-admissible cells at turn boundaries — NOOA snapshots into its own storage, Prime into its own session directory, CLM into its own file (context-networking.md §2.3, item 1).
- The research program turns the gap into an experiment ladder with defined settling evidence, keyed to the filed substrate work (networked-context-program.md §The experimental ladder; baton#777), and the synthesis confirms no implementation measures any of the five primitives (synthesis.md §403-408).
- The consequence for the design: this is the highest expected value per unit of build in the sketch, and the only section whose differentiation does not depend on out-engineering a crowded field.

### 1.6 The fork contract is what an orchestrator needs from a seat

Claim: the orchestrator's requirements define the fork contract, the corpus supplies its mechanism, and the sketch's one addition is forced by its own feature set.

- The requirements are named in the corpus: re-rolls from a fixed initial state — pass^k — require replay from a turn boundary, "the same property the orchestrator needs to fork a seat at a turn boundary" (benchmarks.md §tau-bench implications); branch comparisons must not confound capability with strategy, which is why trajectories carry their capability set, in the spirit of CLM's harness fingerprint in usage records (context-language-models.md §3, cited in design-sketch.md §7); and a branch must not inherit poison.
- The poison case is recorded: Unreal Agent's live FIXME — forks leave inherited calls without results and retain pending-input accounting — and the sketch treats it as the invariant fork must hold (unreal-agent.md §12; design-sketch.md §2).
- The mechanism is supplied three times: fork is a pure function over the source log with deterministic synthetic closers that distinguish `interrupted` from `forked` wording (deepseek-harness.md §5.1); crash repair and fork are the same operation at different causes (deepseek-harness.md §1.1); and the ecosystem ships fork-at-turn-boundary as a product surface in goose, OpenCode, and Codex (minimal-harness-survey.md §What transfers).
- The sketch's addition beyond the corpus is the basis-digest triple — log prefix, harness-state version vector including admitted extensions, workspace checkpoint — with a typed mismatch verdict at load. That addition is forced: Prime's fork-by-prefix, the closest corpus mechanism, carries no extension state to compare (prime-agent.md §7), so no analyzed harness supplies the check, and fx's typed mismatch event is the model for it (fx.md §12).

### 1.7 Self-extension is context economy with a measured promotion gate

Claim: the sketch's compilation claim has a measured cousin, its safety side is the corpus's strongest mechanism rather than a new one, and its unmeasured part is handled by sequencing plus a gate.

- The claim (design-sketch.md §6): repeated composition is what should be compiled — a program written five times in a session becomes a tool, and every subsequent use costs fewer turns and less transcript.
- The measured cousin: CLM's skill evolution took a held-out task from 38.3 to 74.2 at lower compute, behind a Pareto gate with a frozen archive whose held-out split is touched once (context-language-models.md §5, §Skill evolution).
- The same artifact class exists in Prime: stored orchestration graphs — versioned, refinable state-machine programs executed over spawned children to quiescence (prime-agent.md §4).
- The economy link is the call-count multiplier again: any mechanism that compresses repeated multi-turn composition into one call acts on the axis where NOOA's 28-versus-66 advantage lives (nooa.md §3.5).
- The safety side: the model-readable description is generated from the same data the executor enforces, so description and behavior cannot drift (deepseek-harness.md §4); admission is a logged event carrying the module digest, the admitting principal, and the authorizing approval (deepseek-harness.md §2); extensions inherit the seat's authority and cannot widen it (fx.md §8).
- The promotion gate copies CLM's statistical protocol where a task suite exists and Prime's review gate where one does not (prime-agent.md §6) — the corpus's gate, restated. The unmeasured part — seat-authored tools compiling composition at runtime — is real; the sketch's answer is milestone sequencing plus the gate, which is the correct handling of a claim its own evidence does not yet carry.

### 1.8 The omissions are the negations of recorded costs

Each omission in design-sketch.md §11 maps to a documented cost elsewhere in the corpus:

- No plugin registry: dsh's distribution and composition machinery is where its size lives (deepseek-harness.md §8, "what fits poorly").
- No full-screen interface: the event log is the interface, and fx's scrollback and modal islands are the recorded human-viewer investment (fx.md §7).
- No harness-local memory service: the standing store is the orchestrator's knowledge layer, the position gptme's cross-harness store and baton's own graph take (minimal-harness-survey.md gptme section; no-compaction-approaches.md §7).
- No subagent spawning: a seat that needs help asks its conductor (prime-agent.md §11.2), and CLM found subagents add little on single-repository benchmarks (context-language-models.md §5, EdgeBench observation).
- No quotas, counters, or step caps: benchmark instruments cap steps because they are instruments; operational limits belong to individual tools (benchmarks.md §Concept 5).
- No stateless per-action execution: the async streaming contract requires a stateful, streamable shell (minimal-harness-survey.md §What does not transfer).

The omissions are not missing features; each one deletes a mechanism the corpus records as costly.

## 2. Load-bearing analysis

### 2.1 The irreducible core

Five elements carry the proposal. Each is stated with its collapse mode: what the remaining design becomes if the element is removed or changed.

1. **The turn-enclosed, append-only session log with call/result atomicity (§2).** Resume, fork, compaction, replay, instrumentation, and orchestrator receipts are all folds over this one artifact; dsh states the position as the log being the only truth (deepseek-harness.md §5). Remove it and fork loses its shared mechanism with crash repair, pass^k re-rolls become impossible, and the invariants — reason on every exit, result never separated from call, idempotent inputs persisted before processing — have no single place to live. This is the only element all the analyzed loop harnesses converged on independently (synthesis.md §Cross-harness highlights).
2. **The two-plane projection economy (§3).** The measured advantage (§1.1 above). Remove it and the transcript becomes the budget variable; compaction moves from "expected never to fire" to a load-bearing stage, which is precisely the posture the corpus documents as the field's default and its slow failure mode (no-compaction-harnesses.md §9, postponement mechanisms). Weaken truncation to silent and the failure becomes invisible — the Aider format-failure class, where parse failures suppress measured scores (benchmarks.md §Aider; design-sketch.md §12 logs parse-failure events for exactly this reason).
3. **The async operation layer (§4).** The lever on transcript-per-work and wall-clock, and the reason a seat can sleep, absorb completions in batches, and accept steering without queueing behind a tool call (unreal-agent.md §3, §5; design-sketch.md §4). Remove it and the seat blocks on every call; the orchestrator's steering property dies with it, milestone 2 disappears, and bet 1 becomes untestable because the switch it is settled by no longer exists. It is the one load-bearing element that is also a bet; its status is conditional on its own A/B.
4. **The fork contract with basis digests (§7).** The operation the orchestrator exists to perform (§1.6 above). Remove it and ensemble work — branches, comparison, promotion, adoption — has no substrate; forks either inherit in-flight calls without results or silently mismatch harness state, and the mismatch is the one failure that poisons a branch permanently rather than failing loudly (unreal-agent.md §12; fx.md §12).
5. **The commit-and-cite orchestrator plane (§8).** The project's reason to exist (§1.5 above). Remove it and baton-cli is a competent standalone harness in a crowded field; the differentiating half of the design disappears. It is also the only section whose substrate is external to the sketch — baton's REPL layer, baton#777 — so it cannot be re-derived from the corpus reports.

The tool-set policy of §5 sits at the boundary: its content is one priced addition (edit, +7.7) plus bounding, but its discipline — nothing added without a measured gap — is load-bearing as policy, because tool proliferation is the measured negative (benchmarks.md §Published harness ablations) and self-extension is the pressure that would otherwise erode the surface from inside.

### 2.2 Decorative in the first milestone

Five items are deletable from milestone 1 without loss, each because it depends on state that does not exist yet or instruments a concern the first milestone does not have:

1. **The promotion gate and shared-cell promotion (§6, §7).** Nothing is promotable before admitted extensions with evaluation records exist (milestone 3). Keep the gate's definition; delete it as a work item until an extension pays on a branch.
2. **The ensemble-consequence machinery (§7 tail).** Capability sets in trajectories and adoption-as-new-admission are consequences of the log and fork design, not mechanisms to build; the capability set already rides the trajectory items §12 requires.
3. **Macaroon caveats, subtree revocation, and three-key deref budgets (§8).** The research program itself orders these at E2/E3; E1 needs only an orchestrator-mediated, version-pinned read (networked-context-program.md §The experimental ladder).
4. **The TLA+ model-checking program (§13).** fx is the only analyzed harness doing it, and the corpus marks the minimum-viable-spec question as unexplored (synthesis.md §385-387). Milestone 1's durability claims are covered by codec fixtures and fuzz — unreal-agent's own engineering weight (unreal-agent.md §6). Specify the protocol state machine and property-test it; defer TLC until the protocol exists to model-check.
5. **Binary-size and startup-latency CI gates (§13).** fx's identity constraint as a user-facing binary (fx.md §1); a seat is spawned by an orchestrator and its startup cost is an operations concern, not a design invariant. A smoke assertion covers the real requirement.

The program lane (§5) is not decorative but is correctly sequenced: the milestones already place it at milestone 3, where its absence costs nothing, and the self-extension story's compilation verb — a program written five times becomes a tool — needs the lane's nesting and call-id correlation contract (deepseek-harness.md §4) to be more than a claim.

## 3. The strongest single argument against

The proposal's measured evidence and its novel mechanisms do not overlap. The one strong measured result behind the context economy — NOOA at 82.2% and ~1.1M tokens — is produced by in-process pass-by-reference, and the sketch forfeits that property at both boundaries where it would matter: tools and generated programs run under OS confinement, the exact condition NOOA's own limitation section names as trading reference semantics away (nooa.md §3.6), and every cross-seat transfer serializes at the commit point, by value, per the corpus's own verdict that "passed by reference" is true of the address and false of the bytes (context-networking.md §5.1). What the sketch actually implements inside the seat is fx-shaped — bounded renderings, spill handles, paging (fx.md §3) — plus within-turn program scope, while NOOA's cross-turn value residency, the half of its economy the sibling comparisons attribute to statefulness across turns (nooa.md §6), is reduced to the standing workset. The two things that are genuinely new — the async-first loop and commit-and-cite hand-off — are exactly the two mechanisms the corpus records as having no published controlled comparison (benchmarks.md §Explicit unknowns; networked-context-program.md §Open questions), and the sketch sequences all measurement after the architecture that depends on it: the campaign sits in milestone 4, behind the operation layer, the program lane, and self-extension. A design that cites a number earned by a mechanism it does not implement, and defers measurement of the mechanisms it does implement until after they are built, is asking to be trusted on its architecture alone — and its own falsification conditions say that trust is exactly what is not yet earned.

## 4. What must be demonstrated first, in order of evidentiary cost

Ordered cheapest-first; each item's cost is dominated by what must exist before it can run. The first three settle load-bearing properties with nothing beyond milestone 1; the last three settle the bets in ascending architectural dependency.

1. **Log durability under fault injection.** Fuzz and crash-sequence tests proving the six §2 invariants and that fork and crash repair are one operation at different causes. Needs no model calls; unreal-agent's fixture and fuzz suites are the template (unreal-agent.md §6). This is the substrate: if it fails, nothing above it is worth measuring.
2. **The provider contract for the async stub form, and cache stability of the prompt layout.** One seat, minutes of model time: does the target provider accept replacement or second-item results for the same call id — the mechanism the whole §4 primary path rests on, and the one the corpus records as provider-dependent, with the vendor reporting rejections on some non-OpenAI providers (unreal-agent.md §12)? In the same runs, measure prefix-cache hit rates across turns for the three-region prompt and the masked catalog.
3. **Projection bounding against transcript growth per task.** One seat, one fixed task set, same model, pinned harness version: transcript bytes and tokens per task with bounding on and off, spill-handle hit rates, and truncation events. A direct measurement of §3's claim with async out of the picture; the design's own instrumentation — per-deref receipts, separate provider-counted and estimated tokens, parse-failure events — already emits what this needs (design-sketch.md §12).
4. **Async versus blocking A/B — bet 1's settling experiment.** Requires milestone 2's operation layer. Same task set, same model, pinned version, both postures through the emulation switch; tokens, turns, wall-clock. The design's falsification condition is already stated (design-sketch.md §14); this experiment is what makes the operation layer's complexity earned rather than assumed.
5. **Program lane versus discrete calls — bet 2, plus the first compile-after-five test.** Requires milestone 3. Same task set with the lane on and off; then one extension promoted through the CLM-shaped gate — mean-reward delta against paired standard error, held-out touched once — to establish whether seat-authored tools pay as economy (context-language-models.md §5).
6. **Commit-and-cite E1 — bet 3.** Requires milestone 4 and the orchestrator substrate. The two-seat task with inline-transcript and re-derivation baselines; token cost, receiver cache behavior under commit cadence, replay-exactness across seat restarts (context-networking.md §5.1; networked-context-program.md §The experimental ladder, E1). This is the most expensive item and the only one whose evidence no prior system can supply, which is precisely why it must be run rather than cited — and why items 1-5 should not be allowed to consume the budget that funds it.

## Proposed amendments

Ranked; each is a concrete change to design-sketch.md.

1. **§3: declare the cross-turn residency scope honestly.** Add two sentences: what persists across turns is the standing workset and spill handles; within-turn bulk lives in program scope; NOOA's cross-turn in-process statefulness is out of scope because tools and programs run under confinement. Why: the sketch currently cites NOOA's measured number for an economy whose cross-turn half it does not implement (nooa.md §3.6, §6); §3 of this document is the attack that gap invites, and the fix costs two sentences.
2. **§15: pull the economy measurements forward.** Make the bounding A/B and the provider-contract checks (§4 items 2-3 of this document) exit criteria of milestones 1-2, and state that the milestone-4 campaign carries only the experiments that need the orchestrator. Why: the current plan measures every bet after the architecture that depends on it is built (design-sketch.md §14, §15); §3 here is exactly that sequencing stated as an attack, and the fix reorders evidence without changing any mechanism.
3. **§4/§15: add the provider-portability check to milestone 2.** Verify two-item/replacement result acceptance on the target providers before building the operation layer, citing unreal-agent.md §12. Why: it is the one external dependency of the §4 primary path, it is recorded as failing on some providers, and it costs minutes to test.
4. **§13: demote TLA+ to a post-milestone-2 item; keep codec fixtures and fuzz as the milestone-1 discipline.** Why: fx is the only corpus harness with TLC, the minimum-viable-spec question is open (synthesis.md §385-387), and the protocol state machine does not exist until milestone 2.
5. **§13: delete the binary-size and startup CI gates, or rescope them to an orchestrator-spawn smoke budget.** Why: fx's constraint as a user-facing binary has no seat-side corollary in the corpus.
6. **§15: mark the promotion gate and ensemble-consequence items as post-milestone-3 explicitly.** Why: §6 and §7 present them as design content; they are consequences and gates over state that does not exist until extensions are admitted, and the milestone list should say so.
7. **§9: make write-before-loss explicit for the workset.** The long-horizon survey records that no surveyed mechanism enforces the durable write happening before the loss event, and only Anthropic documents a prompt-level nudge (no-compaction-harnesses.md §9); state that the workset commits at the same turn boundary that any projection-bounding or compaction event consumes. Why: the design already has the boundary; one sentence turns an implicit ordering into an invariant.
8. **§2: cite pi.md §4 as the primary source for the truncated-output rule.** The rule is pi.md §4 item 3 (`failToolCallsFromTruncatedMessage`); §12 item 8 documents it as a corrections-register finding. Why: citation precision; the current §12 reference is defensible but secondary.
