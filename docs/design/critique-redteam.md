Verdict: The sketch is not ready as a first milestone plan.
Highest-risk issue: it promotes unmeasured context, extension, and orchestration mechanisms into the core seat path.
Recommended change: ship a smaller crash-safe seat, then add each disputed mechanism behind a measurement gate.

# Red-team critique of `design-sketch.md`

This critique assumes the target is a minimal Bend2 seat for the baton orchestrator. The design has
sound pieces: an append-only event log, turn boundaries, typed tool contracts, and bounded tool
outputs are all supported by the corpus. The breakage is in the scope and in the missing failure
contracts around long sessions, async work, self-extension, branch state, and cross-seat context.

Severity labels use P1 for a release-blocking design risk, P2 for a high integration risk, and P3
for scope that should be delayed until measured evidence exists.

## Findings ranked by severity

### P1 — The no-compaction bet fails on the corpus evidence

Failure scenario: A seat runs for 100+ turns or several hours. The event stream grows, tool stubs
and old observations stay visible, and the model either loses attention to relevant facts or hits a
provider limit. The sketch says compaction exists but is expected never to fire. That is a bet on
append-only visible history, not a mechanism.

Evidence: `context-language-models.md §5` reports that on twelve-hour EdgeBench runs the three
context-managing methods kept improving while the base append-only harness stopped improving inside
the first two hours. `no-compaction-approaches.md §6` reports Chroma context-rot results where task
performance degrades as input length grows even when the window is large. `no-compaction-approaches.md
§2` reports Anthropic's conclusion that compaction alone was insufficient across many windows and
needed structured notes, an initializer artifact, progress files, and shell setup. `nooa.md §3`
records that NOOA still ships an opt-in summarizer, reactive overflow archive, and model-callable
collapse API; its no-compaction claim is about triggering, not absence.

Severity: P1. A seat intended for multi-hour Baton work will fail before the orchestrator layer gets
to prove anything if context management is a dormant emergency path.

Counter-proposal: Replace "compaction is expected never to fire" with a required context policy:
projection budgets for every tool result, explicit overflow handles, a live token/headroom estimate,
and a mandatory reclaim path that preserves user intent, final answers, pending calls, and cited
artifacts. Make no-compaction a measurement arm, not the default invariant.

### P1 — Async stubs can wedge the seat and bloat the transcript

Failure scenario: The model starts several long-running operations, then ends its turn. One result
never arrives, a shell child loses its parent, or a network operation goes idle. The transcript keeps
fixed running stubs forever. A `StopWhenIdle` style completion never fires because the pending set is
non-empty, while the model receives only periodic reminders. If many operations are pending, every
turn repeats a growing pending surface.

Evidence: `unreal-agent.md §5` shows the running-placeholder contract plus a heartbeat after ten
minutes; that heartbeat is a backstop, not a completion policy. The same report says Unreal has no
concurrency classification and runs any number of tool calls concurrently by default (`unreal-agent.md
§9`). DeepSeek bounds programmatic-tool pending calls, frames, output bytes, and deadlines
(`deepseek-harness.md §4`). Prime records orphan process groups so the host can reap them after a
kernel crash (`prime-agent.md §9`). Prime also defines completion as quiescence: no in-flight entry
and no unevaluated settle (`prime-agent.md §11.1`).

Severity: P1. A single never-settling operation can hold the session open and keep stale prompt
state alive indefinitely.

Counter-proposal: Define the pending-operation state machine before async-first is admitted: pending,
running, heartbeat_due, timed_out, cancelled, lost, completed. Put hard caps on pending operation
count, pending bytes, and wall time per class. Persist child process ownership and reap rules. Make
quiescence, not "turn ended", the completion contract. Heartbeats must carry the action the model can
take: wait, cancel, collect partial output, or mark lost.

### P1 — Self-extension is a model-controlled executor without a real gate

Failure scenario: The model writes a Bend2 module whose description looks safe and whose contract
validates, but its implementation composes host effects in an unexpected way. A peer branch or
orchestrator artifact supplies a module with prompt-injection text in the source, schema
description, examples, or saved evaluation record. The seat admits it because the module has a digest
and an approval event. After admission, the tool becomes part of the model-facing catalog and can be
called repeatedly with the seat's authority.

Evidence: `context-language-models.md §7` names editable context as a persistence channel for prompt
injection, including self-generated instructions that survive compaction summaries. `prime-agent.md
§11.2` says full self-improvement surfaces are heavy and trust-demanding, and that Prime's code has
guards because the model can write harmful refinements. DeepSeek avoids in-process program execution
for PTC: programs run in a fresh Node process under the same sandbox as Bash, with timeouts, memory
limits, bounded protocol traffic, and typed failure outcomes (`deepseek-harness.md §4`). The current
Bend2 architecture record says C supplies host primitives while Bend2 owns command meaning and
coordination decisions (`.scratch/session-takeover-20261006/orchestra-resume-20261007/current-source-ac55/docs/bend2/target-architecture.md §Implementation boundary`). That is not a sandbox boundary for adopted code.

Severity: P1. Admission records and digests prove identity, not safety. A persistent new executor
inside the harness is a privilege surface.

Counter-proposal: Cut persistent self-extension from the first implementation. Keep only ephemeral
program execution with the same sandbox, operation caps, approval path, and logging as the shipped
executor. Promotion requires an external review or statistical evaluation record owned by the
orchestrator. The model may propose a module; it may not install one into the durable catalog during
ordinary work.

### P1 — Permission enforcement is specified as policy, not implementation

Failure scenario: A generated program or extension performs nested calls. One nested call writes the
workspace, another reads outside the allowed scope, and a third starts a long process. The sketch says
tools carry permission targets and effects keep writer fences, but it does not state where the OS
sandbox, approval arbiter, authority snapshot, and execution identity are enforced.

Evidence: `fx.md §4` derives concurrency from declared tool safety and writes a `tool_intent` before
effects run. `fx.md §5` uses prepare-authorize-apply with captured preimages for file mutation.
`arcee-nac.md §7` says permission enforcement is an eleven-file subsystem with shell parsing, hard
policy, resource binding, approval modes, and invocation-only terminal input. `deepseek-harness.md
§6` records fail-closed approvals and honest sandbox reporting with full/partial enforcement states.
Baton's own earlier design notes warn that the OS sandbox is the authorization boundary and a policy
engine can only tighten and log (`docs/05-telemetry-steering.md §4`).

Severity: P1. A model-controlled executor plus underspecified permission enforcement creates an
unbounded effect surface.

Counter-proposal: Add one enforcement section with the executable boundary: process sandbox profile,
network default, writable roots, repository metadata handling, approval vocabulary, request IDs,
single-consumer answers, timeout behavior, authority snapshots, and effect-intent journaling. Tool
metadata should feed this path; it should not be the path.

### P2 — The orchestrator plane assumes citation behavior the model may not perform

Failure scenario: Seat A writes useful state into files, its local log, or a worktree. Seat B gets a
brief that mentions the state but does not receive a dereferenceable citation or a bounded projection.
B either ignores the hidden state, re-derives it, or quotes stale prose. The design then measures
"citation hand-off" while the actual behavior is inline summary plus manual retrieval.

Evidence: `context-language-models.md §3` states that ContextBench does not credit answers held only
in files; the answer must be in the agent context. `context-networking.md §2.3` says baton lacks the
seat-side context commit path, context-snapshot content convention, and receiver-side projection.
`context-networking.md §4.3` says every rebind bumps the scope fence and invalidates fence-keyed
projection caches, so commit cadence is part of the cost. `addressing-and-authority.md §1.3` says
orchestrator-minted grants move durable state and bookkeeping cost to the minting side.

Severity: P2. Commit-and-cite can be coherent and still fail in practice because the seat never emits
or dereferences the right object at the right time.

Counter-proposal: Make citation an automatic harness action for named hand-off artifacts, not a
model etiquette rule. A report should include machine-checked citations for artifacts the seat
claims, and the receiver should get a rendered projection plus a receipt. Add an inline fallback arm
for the first experiment so the system can detect when citation loses to re-derivation.

### P2 — The fork triple is too large and still underspecified

Failure scenario: A branch is forked after a model admitted one extension, started async work, and
changed several files. The child branch carries a log-prefix digest, a harness-state vector, and a
workspace checkpoint. On load, the core version or extension set differs. The sketch says refuse or
run degraded, but it does not define which tools disappear, how old tool calls are rendered, whether
pending operations are cancelled, or whether dirty workspace state can be reconstructed exactly.

Evidence: `minimal-harness-survey.md §Gemini CLI` records Gemini's shadow-git checkpoint before any
file-mutating tool call, together with conversation history and pending tool call. That is a concrete
rollback mechanism, not only a digest. `fx.md §10` uses append fences, manifests, recovery
checkpoints, and explicit stale states. `deepseek-harness.md §5` stores session header metadata so a
resume restores the same toolset and prompt composition. `unreal-agent.md §6` warns by example that a
fork must not inherit in-flight calls without results, because that poisons a branch.

Severity: P2. The triple protects identity, but the loading semantics are the part that determines
whether the branch is usable.

Counter-proposal: For the first milestone, fork only at completed turn boundaries, cancel or settle
all pending operations before fork, and refuse any harness-state mismatch. Degraded load should be
removed until there is a real compatibility table. Workspace checkpointing should be a separate
mechanism with a bounded store, not a field in the fork record.

### P2 — Token and budget accounting conflicts with the "no quotas" omission

Failure scenario: A task runs without a step cap, token budget, pending-operation budget, or provider
quota policy. A long session burns the operator's provider window, then parks or fails without a
ledger fact the orchestrator can use for scheduling. Evaluation results cannot be compared because
one run had unlimited turns and another hit a provider limit.

Evidence: `benchmarks.md §Synthesis` says limits must be first-class recorded parameters; tau-bench
scores moved when the action cap changed from 30 to 100, and Terminal-Bench treats timeout changes as
an integrity issue. `fx.md §9` records provider capabilities and self-correcting token estimates from
provider counts. `prime-agent.md §9` parks sessions durably on provider quota and resumes on a
configured retry policy. `fx.md §14` budgets skill catalogs and MCP schemas against context windows.

Severity: P2. Budget accounting is not optional in a seat controlled by an orchestrator.

Counter-proposal: Replace "no quotas, counters, or step caps" with a recorded task budget envelope:
provider token counts, estimated counts, cache-read/write tokens where available, wall-clock, tool
count, pending-operation count, output bytes, and provider quota state. The orchestrator may set the
budget; the seat must enforce and report it.

### P3 — The first milestone includes mechanisms that obscure the core proof

Failure scenario: The team builds protocol specs, emulation switches, branch digests,
self-extension, grants, and citation receipts before proving that one Bend2 seat can run a baton task
safely, settle async work, and recover after a crash. The harness becomes a research platform before
it becomes a reliable seat.

Evidence: `benchmarks.md §Synthesis` says the useful minimal target is a small versioned loop, one
interactive execution surface plus one edit surface, an append-only event session, explicit limits,
and no further scaffolding until measured gaps justify it. `minimal-harness-survey.md §What transfers
to Bend2` says deterministic tool-output bounding and validated edit tools are the cheap context
layers. `deepseek-harness.md §11` explicitly says the Cordis microkernel and plugin distribution
surface do not fit a minimal Baton seat.

Severity: P3. This does not make the design impossible, but it makes the first milestone harder to
review and easier to mis-measure.

Counter-proposal: Gate milestone 1 on four observable facts only: durable log replay, one sandboxed
execution surface, one safe edit path, and Baton task/report round trip. Add async in milestone 2
after the crash and permission model are fixed.

## What I would cut outright

- Cut persistent self-extension from milestones 1 through 3. Keep ephemeral generated programs only.
  Evidence: DeepSeek's PTC is a fresh sandboxed process with tight bounds (`deepseek-harness.md §4`),
  while Prime's self-refinement surface needs review gates because model-written refinements are risky
  (`prime-agent.md §11.2`).
- Cut degraded-mode branch loading. A mismatched extension set or tool schema should refuse. Evidence:
  DeepSeek stores header metadata to restore the same toolset and refuses changed retained tool
  definitions for cache and correctness (`deepseek-harness.md §5`).
- Cut the triple-basis fork from milestone 1. A completed-turn log fork plus clean workspace base is
  enough to prove orchestration. Evidence: `benchmarks.md §Synthesis` asks for a replayable session
  from a fixed state before advanced branching.
- Cut harness emulation switches from the build plan. They are useful for experiments, not for the
  first reliable seat. Evidence: `benchmarks.md §Synthesis` says add scaffolding only after a
  measured gap.
- Cut grant derivation trees and macaroon-style caveats from the first cross-seat experiment. Start
  with one orchestrator-minted read grant scoped to one citation and one reader. Evidence:
  `addressing-and-authority.md §1.3` names grant bookkeeping as durable orchestrator state with cost.
- Cut the formal model-checking requirement as a milestone-1 blocker. Keep executable state-machine
  fixtures and crash tests first. Evidence: `fx.md §11` shows formal specs can be valuable, but the
  same report also shows the runtime already has concrete append fences, recovery checkpoints, and
  logs that can be tested directly.

## Proposed amendments

1. **Section 2, "The session log": replace the dormant compaction claim.** State that context
   management is required from day one: bounded projections, spill handles, token/headroom tracking,
   and a reclaim operation with pending-call carry-forward. Why: CLM long-horizon results and Chroma
   context rot directly contradict an append-only visible transcript for multi-hour work
   (`context-language-models.md §5`; `no-compaction-approaches.md §6`).

2. **Section 4, "The loop is async-first": add a pending-operation state machine.** Specify states,
   caps, deadlines, heartbeat cadence, cancel semantics, lost-result semantics, process reaping, and
   quiescence. Why: Unreal's placeholder contract needs heartbeat and recovery machinery, while Prime
   and DeepSeek show the needed completion and bound vocabulary (`unreal-agent.md §5`; `prime-agent.md
   §11.1`; `deepseek-harness.md §4`).

3. **Section 5, "Tools and the program lane": make permission enforcement executable.** Add the OS
   sandbox profile, approval arbiter, authority snapshot, effect-intent journal, write fences, and
   nested-call handling. Why: tool metadata does not enforce anything by itself (`fx.md §4`; `fx.md
   §5`; `arcee-nac.md §7`).

4. **Section 6, "Self-extension": demote to a later experiment.** Change persistent self-extension
   into orchestrator-reviewed module proposals. Permit only ephemeral generated programs in the seat.
   Why: model-written durable executors are a security boundary, and the cited CLM/Prime evidence
   requires evaluation or review gates (`context-language-models.md §7`; `prime-agent.md §11.2`).

5. **Section 7, "Fork, branch, and ensemble": remove degraded-mode loading.** First versions should
   fork only completed turns and refuse harness-state mismatches. Workspace checkpoints should be
   designed separately with bounded storage and restore tests. Why: the proposal defines basis
   identity but not load behavior (`minimal-harness-survey.md §Gemini CLI`; `fx.md §10`).

6. **Section 8, "The orchestrator plane": add mandatory citation production and deref projection.**
   Reports should include machine-checked citations for claimed hand-off artifacts, and receivers
   should get a bounded rendered projection plus a deref receipt. Why: ContextBench does not credit
   answers stored only in files, and baton lacks the seat-side commit convention and receiver
   projection (`context-language-models.md §3`; `context-networking.md §2.3`).

7. **Section 8, "The orchestrator plane": specify commit cadence before grants.** Define when a seat
   commits context cells, what each commit contains, and how receiver caches are invalidated. Why:
   every rebind bumps the scope fence and invalidates fence-keyed caches (`context-networking.md
   §4.3`; `impl/src/coordination-ledger.mjs:3173-3185`).

8. **Section 10, "Safety and reversibility": add crash windows.** Name the durable barrier before
   each effect, the recovery answer for possibly-run effects, torn-tail handling, and child-process
   cleanup. Why: fx, DeepSeek, and Unreal all spend design on these exact windows (`fx.md §10`;
   `deepseek-harness.md §5`; `unreal-agent.md §6`).

9. **Section 11, "Deliberate omissions": remove the no-budget omission.** State that user-visible
   quotas may live in the orchestrator, but the seat records and enforces task budgets and provider
   quota outcomes. Why: benchmark scores and operational behavior depend on step, time, and token
   budgets (`benchmarks.md §Synthesis`; `prime-agent.md §9`).

10. **Section 12, "Instrumentation": narrow the switches.** Keep the citation-vs-inline experiment
    and async-vs-blocking experiment as logged measurements, but do not implement full harness
    emulation before the base seat works. Why: first proof should measure the Baton seat, not a matrix
    of unshipped modes (`benchmarks.md §Synthesis`).

11. **Section 13, "Engineering discipline": stage formal methods after executable recovery tests.**
    Keep codec fixtures, log replay, crash injection, and permission-denial fixtures in the first
    milestone; add model checking after the state machine stabilizes. Why: formal specs are useful
    only when they track the mechanism being shipped (`fx.md §11`).

12. **Section 15, "Milestones": rewrite the sequence.** Milestone 1 should be log, replay, sandboxed
    execution, edit, Baton task/report round trip, crash recovery, and budgets. Milestone 2 should be
    async with quiescence and loss handling. Milestone 3 should be program lane. Milestone 4 should be
    commit-and-cite. Self-extension and branch capability promotion should wait for evidence.
