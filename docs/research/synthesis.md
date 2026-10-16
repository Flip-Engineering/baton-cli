# Harness engineering approaches: evaluation of the research reports

The aim of the research was to understand conceptual approaches to harness engineering and the
architectures that achieve them. Each single-harness report is a code-level study of one
approach; this document evaluates the approaches and contrasts them on the engineering problems
every harness must solve. It draws no design prescriptions: design is a later phase, and these
reports plus this comparison are the input to it.

Method: the single-harness reports analyze shallow clones at recorded HEAD commits (Pi
`b06c1f2c`, DeepSeek Harness `5719020`, fx `6afa7c33`, Prime Agent `3e141d10`, NOOA
`3187c6df`, Meta CLM `48319822`, Unreal Agent `a5f3fd13`, Arcee NAC `e02ab928`); the survey
covers fifteen further harnesses from primary sources; benchmark figures come from primary
sources. Reports: [pi.md](pi.md), [deepseek-harness.md](deepseek-harness.md), [fx.md](fx.md),
[prime-agent.md](prime-agent.md), [nooa.md](nooa.md),
[context-language-models.md](context-language-models.md), [unreal-agent.md](unreal-agent.md),
[arcee-nac.md](arcee-nac.md), [minimal-harness-survey.md](minimal-harness-survey.md),
[benchmarks.md](benchmarks.md), [no-compaction-approaches.md](no-compaction-approaches.md),
[no-compaction-harnesses.md](no-compaction-harnesses.md),
[context-networking.md](context-networking.md).

## The six approaches

### Pi — policy at hooks, capability in the surface

Concept: the agent loop is a thin envelope; capability lives in the prompt and the tool
surface; every policy decision is expressed at a hook seam. The kernel ships tools without
approval logic, a loop without step limits, and a session without privacy rules; plan mode and
subagents are absent from the core and re-expressible as hooks or tools
(`packages/agent/src/agent-loop.ts`, `packages/agent/src/agent.ts`).

Architecture that achieves it:

- Layered packages, each knowing only the layer below: `pi-ai` normalizes four wire APIs into
  one closed stream-event union across ~30 endpoint adapters; `pi-agent` runs the event-sourced
  loop; `pi-coding-agent` owns files, sessions, and screens.
- The event-tree session: append-only JSONL entries with `id`/`parentId` and a leaf pointer
  (`session-manager.ts`). Resume is re-walking; fork is appending a child of an earlier node;
  nothing is deleted; files materialize lazily.
- Transcript-owned prompt and tool state: named prompt sections and `toolsAdded`/`toolsRemoved`
  entries are replayed from the transcript, so unchanged state is never re-sent and provider
  caches stay warm; an idle-time cache warmer replays the request at a one-token output cap.
- Strict turn discipline: one assistant response plus its complete tool-result batch is the
  atom for persistence and compaction cut points; a tool result never separates from its call;
  truncated responses fail pending tool calls rather than executing incomplete arguments.
- pi-durable, the second Pi architecture: a committed task graph over the same transcript — a
  single serialized mutation line, durable tool tasks committing intent plus a replay
  declaration before execution, head-marker context selection, ownership-indexed subagent
  conversations with bottom-up abort cascades, and busy-conversation submission queues.

Costs and limits: batch-scoped `Promise.all` concurrency with source-order persistence;
single-process JSONL persistence in the coding agent; awaited-listener settlement couples run
liveness to consumer speed (pi-durable's "only committed state is observable" is the fix);
per-conversation, single-model compaction; in-process TypeScript extensions carry the shared
process's security posture.

### DeepSeek Harness — seams everywhere, the log as the program

Concept: every subsystem is swappable at a named seam; product behavior is data (presets
compose plugins, patches replace configs by id); and one append-only, turn-enclosed event log
is the program whose folds produce all state — model history, pending input, tool
declarations, approval policy, and turn boundaries are projections
(`packages/core/agent-loop/src/agent.ts`, `packages/core/session/src/tool-history.ts`). Resume,
fork, search, and UI replay share one implementation because the log is the only truth.

Architecture that achieves it:

- The Cordis microkernel with three-role capability seams: `ctx.llm`, `ctx.sandbox`,
  `ctx.ptcRuntime`, subagent providers, session persistence providers — each a swap point with
  shipped default providers (bundled Node/TS PTC, bwrap/Landlock/Seatbelt/ACL sandboxes, JSONL
  session log).
- Turn enclosure as atomicity: every exit path closes the turn with a reason in a `finally`;
  crash repair synthesizes closers in the same shape as live repair; fork is the same mechanism
  with a different cause. Crash recovery and fork are one operation.
- Bounded concurrency as a portable contract: one per-tool classification
  (`isConcurrencySafe` → execution mode) drives three schedulers (native rolling pool, PTC
  sub-dispatch lane with `maxParallelSubCalls = 10`, tool-binding parallelism), with ordered
  commits through a head-of-line cursor so the log stays model-ordered.
- PTC: the model writes TypeScript against a generated byte-stable SDK; each program runs in a
  fresh Node process confined by the same sandbox as bash (worker-threads confinement was
  abandoned — workers cannot apply OS file policy to direct `node:fs` imports); bindings cross a
  dedicated untrusted control channel; nested calls re-enter the full guarded pipeline;
  failures resolve as typed result fields and failed programs never replay. The prompt's PTC
  presentation renders from the same predicate the executor denies by, so prompt and
  enforcement cannot drift.
- Fail closed, report honestly: approval normalizes rogue answerers to `unavailable` with the
  never-gate inside the approval service before the fallback waterfall; sandbox enforcement is
  reported as `full`/`partial` with named per-backend reasons; torn session tails are
  truncate-and-rewrite with recorded markers.

Costs and limits: the microkernel and patch-composition machinery is itself a large system;
per-call fresh-process PTC is expensive; every assembly listener owns the integrity of
rewritten protocol sections; much behavior hides behind seams — the report found shipped
controls (PTC `timeoutMs`, per-program sandbox escalation) absent from the docs.

### fx — budgeted native binary, formally specified durability

Concept: smallness and speed are enforced as CI contracts; one agent core serves many hosts
through injected effects; durability and concurrency correctness are first-class properties,
formally specified where they are hardest; the terminal is a plain Unix stream; context is a
budgeted variable.

Architecture that achieves it:

- Budgeted binaries: 6.74 MiB arm64 release binary (measured; vendor-reported 6.39 MiB at
  launch), byte-delta annotations over a 52,429-byte threshold per pull request, and 2 ms
  wall-clock budgets on trivial commands, measured with hyperfine
  (`.github/workflows/binary-size.yml`, `benchmarks/check_budgets.py`).
- The dependency-injection seam: the 12,655-line turn engine calls only `AgentRuntimeDeps`
  function pointers (`src/core/agent/runtime/deps.zig`); the ACP server is shared verbatim by
  CLI, Node addon, and WebAssembly; embedded hosts get typed capabilities that are
  default-deny.
- The fenced session log: `events.jsonl` with a state-machine validator (out-of-order seqs,
  duplicate tool-call ids, results answering nothing are rejected), offset-confirmed fsynced
  appends, writers that latch a failure state on any offset mismatch, a byte-exact manifest,
  and a disposable binary replay cache bound by watermark and CRC while the log stays the
  authority (`src/core/session/session_log.zig`).
- Intent-before-effect journaling: a `tool_intent` event with a barrier precedes
  effect-bearing batches; idempotent-non-writing tools run ahead; ambiguous calls on resume
  rerun under a stable execution id or are answered to the model as possibly-run.
- Safety-class concurrency: a leading prefix of each batch runs concurrently (read-only /
  subagent / host-concurrent, capped at 16), the first writer runs alone, and permission review
  is identical per call whether concurrent or not.
- Formal verification with runtime replay: TLA+ modules (`DurableSession.tla`,
  `DurableSteer.tla`, `AgentRouting.tla`) model-check writer fencing, lease takeover, cutoff
  continuation, and named-agent routing, with witness configs that must violate each named
  invariant; TLC-generated state graphs are then walked against the real runtime.
- Budgeted context: tool results cap at 64 KiB for the model and spill to content-addressed
  handles searchable after resume; skill catalogs and MCP schemas spend against declared byte
  budgets; token estimates self-calibrate against provider counts; compaction is
  lossy-verbatim reclamation — user intent and final answers survive word for word, the rest is
  displaced into searchable records, and model-written glue is linted against saved evidence.

Costs and limits: no cross-process wake model — durable queueing, lease takeover, and
named-agent routing exist at the libfx SDK layer and stop there; subagent children are first
class sessions but deliberately invisible to listing and external resume; the scrollback
interface and three modal islands are human-viewer investment; the `auto` mode's LLM permission
reviewer adds a model call and nondeterminism at action time; two referenced spec files are
absent from the public clone.

### Prime Agent — context as a queryable variable

Concept: information management belongs in a persistent kernel, not in prompts; the model's
effective context is what it can retrieve programmatically; the harness optimizes for
long-horizon autonomy with auditable self-modification.

Architecture that achieves it:

- One kernel tool, everything programmatic: the model-facing surface is a single
  `python_repl` tool plus programmatic tools (PTC); loops, batched subagent calls, and
  background handles compose in one cell (`crates/pa-core/src/prompts/layers/core.md`). Context
  reads are capped at 64 KiB host-side and 1 MiB kernel-side; the blog's answer-variable
  protocol and 8,192-char cap belong to the verifiers training scaffold, not the product.
- Spawning as admission, results as durable messages: children pass a depth gate (default 2),
  a model allowlist, and name uniqueness; results arrive through persisted `agent_message`
  entries and typed collect snapshots; a daemon-owned append-only spawn ledger preserves family
  topology across passivation and restart; state-machine factories run stored orchestration
  graphs over spawned children to quiescence.
- Append-only ledgers per concern: sessions, semantic edges, spawn topology, and refinement
  history are separate JSONL ledgers; fork-by-prefix makes restart a replay
  (`crates/pa-core/src/session_store.rs`).
- Refinement as reviewed, versioned commits: durable harness state (memories, skills, prompts,
  subagent specs) changes only at turn boundaries through gated plans recording trigger,
  evidence, and outcome, with versioned rollback; review-gated auto-refine re-arms after every
  compaction.
- Process-per-session supervision: one worker per active session with backoff restarts,
  passivation, and descriptor-based adoption; subtree accounting attributes usage down the
  spawn tree; harness state reaches the model as a `[harness-digest]` user message at cold
  boundaries.

Costs and limits: a full Python runtime per session; product/training-scaffold divergence
carries parity code and a stale AGENTS.md contract; self-modification has a documented exploit
(the RCON incident in its refinement history); performance claims are tied to RL-trained
models.

### NVIDIA NOOA — budget the projection, not the value

Concept: where the host language already has the right abstraction, use it. An agent is a
Python class — methods are capabilities, fields are state, docstrings are prompts, type
annotations are runtime-enforced contracts — and the model acts by writing Python against that
same object, so developer and model share one vocabulary. Its distinctive engineering
position: tool results are values passed by reference, and the harness budgets only the
projections the model sees.

Architecture that achieves it:

- The class as framework surface: `AgentMeta` wraps ellipsis-bodied methods for LLM
  completion; `@strategy` selects execution per method (CodeAct default, single-shot
  Predict, and others); return annotations are enforced through a generated Pydantic wrapper
  whose failures feed back into the loop (`src/nooa/metaclass.py`,
  `src/nooa/strategies/codeact.py`).
- Two data planes. The transcript carries three regions — a byte-stable static prefix, an
  append-only typed event log with stable string tags, and a dynamic tail re-evaluated each
  turn — so live-state updates never invalidate the cached prefix. The execution plane is a
  `CodeActSession` whose `session_locals` persist across cells of a method call; a
  multi-million-row table lives whole in the process while the transcript carries one bounded
  preview (`prefill_format`: 25 items, 2,000 characters, depth 4).
- Serialization at exactly one boundary: durability. `AgentSnapshot` v2 records typed fields
  through a type allowlist and `PersistentVars` refuses live objects; events persist only
  through the optional SQLite backend. Live by reference within the session; by value at the
  session boundary; never serialized through the model context unless the author places a
  value there.
- Compaction exists in triplicate and is dormant by headroom: an opt-in summarizer triggers
  at 75% of the window (installed by default in the benchmark agent; never triggered at
  reported token peaks), a reactive archive fires only when the provider rejects a request as
  too large, and `events.collapse()` lets the model compact its own history with originals
  addressable by tag. "No compaction" is a statement about triggering, not capability.

Costs and limits: the design depends on in-process execution — the opt-in sandbox backend
trades reference semantics away at the boundary (the paper states this limitation); events are
never individually budget-evicted (`max_event_tokens` and `min_preserved_events` are shipped
no-ops pending a refactor), so long-session growth rests on the overflow archive; captured
stdout past 50,000 characters is unrecoverably elided unless the file-backed option streams it
to disk; REPL locals die with the method by design.

### Meta Context Language Models — the context as a read-write file

Concept: make the accumulated context itself the editable artifact. The history transition
becomes `c_{t+1} = f^CLM(c_t)` — one function the model applies to its own context, subsuming
threshold compaction, fragments, and schedules as special cases (paper §1-§2). The harness is
a protocol: the context renders to a mirrored file with typed turn headers, the model edits it
with ordinary bash (`sed`, `python`, `cat`), and a round-trip parser re-pins the protected
prefix and recovers turns from surviving headers — with the disclosed loss that tool-call
structure never survives an edit.

Architecture that achieves it:

- A byte-exact round trip: `/tmp/.live_ctx/LIVE_CTX_MAIN.txt` with `[[CTX_TURN i role=...]]`
  headers; `parse_back` validates and rebuilds; edits are free-form and priced.
- The honesty device: prefix-reuse FLOPs. Mid-context edits invalidate KV prefix caching, so
  the paper prices the freedom — a head edit costs 7.7× an append-only turn on its
  Qwen3.6-27B setup — teaches the cost in the system prompt, and buys most of it back with
  Suffix Cache Reuse: a serving-layer implementation (~1,935-line SGLang monkeypatch with a
  21.97 GiB side KV buffer, plus a vLLM KV connector) recovering 65.0-65.5% of standard FLOPs
  at matched accuracy.
- Position in the context-as-variable line (paper Appendix A): RLMs externalize the input and
  keep live context read-only; CLMs make the live accumulated context read-write. Against
  NOOA it is the architectural opposite: NOOA pays zero re-prefill by keeping the transcript
  append-only and state in values; CLM pays re-prefill and mitigates it at the serving layer —
  mirror-image cache arguments.
- Release posture: harness, ICL loop, FLOPs accounting, and both SCR implementations are
  released and testable (the shipped unit tests pass); the subagent/swarm runtime, RL
  training, and all API-model results are paper-only.

Costs and limits: tool-call structure never survives an edit; pure-compaction turns still
count against the call budget; SCR is serving-specific (SGLang/vLLM), the FLOPs numbers drift
slightly between paper and repo, and the enforced budget arithmetic differs from the paper's
stated budget (26,624 vs 23,560 tokens).

### The no-compaction field

Two companion reports ([no-compaction-approaches.md](no-compaction-approaches.md),
[no-compaction-harnesses.md](no-compaction-harnesses.md)) extend the context-management
evaluation beyond the six approaches above. The published approaches sort into four postures:
budget the history (selective clearing — Anthropic's context-editing API clears stale tool
uses while keeping recent ones and instructions; Mastra's sliding window with a documented
cache cost); move the projection out (filesystem-as-context — Manus keeps state in files and
recites objectives; deepagents evicts oversized tool results to `/large_tool_results` with
preview stubs; Letta pages memory between core blocks, recall, and archival storage); curate
the standing artifact (Magentic-One's task and progress ledgers; ACE's evolving playbook with
delta updates; sleep-time agents that edit memory in the background); and spend the native
window (1M+ contexts with prompt caching, accepted until context rot degrades effective
use — Chroma's measurements). Folding (arXiv:2510.11967) and ReFold (arXiv:2610.07863)
compress active context with reversible, history-preserving removals; both are training-side
mechanisms without shipping-harness adoption. Compaction itself remains a shipped default
almost everywhere: Amp removed it in favor of handoffs between threads, and Claude Code pairs
the memory tool with server-side compaction as a fallback; NOOA stays the one analyzed harness
whose architecture keeps compaction dormant.

At long horizons (100+ turns, multi-hour runs) the load-bearing mechanisms in the evidence are
the ones that move state out of the window entirely — filesystem or paged memory — while
selective clearing and sliding windows postpone the same pressure; the harnesses report does
the mechanism-by-mechanism analysis.

Two further entries sharpen the posture map. Arcee AI's NAC ([arcee-nac.md](arcee-nac.md))
implements Random Labs' Slate architecture: a structurally tool-less orchestrator dispatches
workers as fresh OS processes whose final response becomes a committed episode and whose
context is discarded — workers never compact because dispatches are bounded by construction
(state passes between dispatches by value), a move-the-projection-out/curate-standing-artifact
hybrid — while the orchestrator and direct transcripts keep compaction at a 70% default, and
the compaction cut-point invariant independently matches pi's (no boundary separates a tool
call from its result). No benchmark evidence exists for it anywhere. Unreal Agent
([unreal-agent.md](unreal-agent.md)) sits outside the postures: its compaction is conventional
summarize-and-rebuild against provider-reported usage, and its contribution is the async
tool-call contract (a running placeholder result replaced or supplemented on completion) and
exactly-once crash recovery over an event-sourced runtime journal. Finally, the hypotheses
evaluation ([context-networking.md](context-networking.md)) adds a fifth posture from the
autoresearch field: context as search state — idea-population operators (tournament evolution
in AI co-scientist, island evolution in FunSearch, best-first search in AI Scientist-v2)
acting over a persistent typed store rather than a transcript. The same report evaluates the
operator's two posed compositions: native context passing is coherent as commit-and-cite
addressing (the baton orchestrator's REPL layer already provides the substrate) and a category
error as live-context dereference across processes; networked infinite context is buildable
from parts that all exist, with unboundedness accruing to the addressable store while
effective context stays a budgeted function of commit/deref/authority boundaries.

## The space of approaches

The survey situates the six in the wider field: near-zero loops (mini-SWE-agent's ~100-line
bash-only agent scoring >74% on SWE-bench Verified; Hugging Face Tiny Agents' while-loop over
an MCP client; rasbt's stdlib single script) at one end; structured SDKs (OpenHands' typed-event
software-agent-sdk) at the other; and most of the industry between (Aider, goose, opencode,
Codex CLI, Gemini CLI, gptme, Crush). Recurring answers include two-layer context control
(deterministic bounding at the tool boundary, LLM-mediated compaction at the session boundary),
subagents as child sessions returning summary receipts, safety as policy layers with undo on
the same substrate as persistence, and session operations as prefix cuts of event logs. The
ecosystem also churns: Open Interpreter is now a Rust fork of Codex with switchable harness
emulation, OpenHands' core moved to a standalone SDK, goose moved to a foundation — the
approaches are young, and none has consolidated.

## Evidence on which engineering choices matter

The benchmark report grounds the evaluation empirically (all figures from primary sources):

- Harness choice moves same-model scores by double digits. Terminal-Bench 2.0: GPT-5.4 mini
  scores 57.8% on Codex CLI and 37.8% on Terminus 2; Opus 4.6 spans 76.4% (Meta-Harness),
  62.9% (Terminus 2), and 58.0% (Claude Code).
- A near-zero harness is competitive at the top: mini-SWE-agent (>74% SWE-bench Verified,
  bash-only, no tool-calling API) and live-SWE-agent (79.2% on Opus 4.5, evolved on the mini
  base) show the loop is the primary instrument.
- Extra narrow tools can score below having none (SWE-agent ablations: search −6.0; RAG
  scaffold 2.67% vs 18.0% for its interface-centric design). The one addition that reliably
  pays is a single robust edit operation with a uniqueness check and error feedback (+7.7).
- Limits are load-bearing: step budgets (tau-bench's 30→100 step cap) and timeouts move scores
  and must be recorded with results.
- No published streaming-vs-blocking tool-execution comparison exists; the question is
  unmeasured in the ecosystem.

## Contrasting the approaches

Each approach's answer to the engineering problems every harness must solve:

| Problem | Pi | DeepSeek Harness | fx | Prime Agent | NOOA | Meta CLM |
| --- | --- | --- | --- | --- | --- | --- |
| Where policy lives | Hook seams; kernel ships none | Seam plugins; behavior as preset/patch data | Typed capability injection; default-deny embeds; ranked permission modes | Admission gates; refinement gates; supervisor-owned policy | Typed methods as enforced contracts; deterministic gates as ordinary code; strategies per method | Budget gates (`edit_gate`, `lm_call_cap`) around one bash action space; the model edits its own context under them |
| Session durability | Append-only entry tree, leaf pointer; single-process JSONL; pi-durable adds committed task graph + head markers | Turn-enclosed generations, lease single-writer, torn-tail repair, never renamed | Fenced fsynced log, byte-exact manifest, disposable replay cache, TLA+ checked | Append-only ledgers per concern; fork-by-prefix; descriptor adoption | Serialization at one boundary: `AgentSnapshot` v2 JSON with a type allowlist; live objects refused; optional SQLite event backend | Mirrored live-context file with `[[CTX_TURN]]` headers; parse-back re-pins the prefix and recovers turns; tool-call structure never survives an edit |
| Concurrency | `Promise.all` per batch, source-order persistence; durable rounds one task at a time | One classification → three schedulers; head-of-line commit cursor | Leading-prefix classes (cap 16); first writer alone; per-call threads | Per-file mutation queues; programmatic parallelism in the kernel; process isolation per session | Model-written parallelism (`asyncio.gather` over generated cells); no harness scheduler axis in the analyzed code | Single bash tool; subagent runtime withheld from the release |
| Context management | Compaction cut points at turn boundaries; tool results kept whole; cache warmer | Deterministic tool-bounding + LLM compaction modes; budgeted result sizes | Budgeted variable: 64 KiB results → spill handles; byte budgets for catalogs; self-calibrating estimates | Retrieval over kernel variables under caps; agentic compaction at 95%; harness-digest delivery | Pass by reference: bounded previews only, values live in the process; compaction shipped but dormant (75% summarizer, provider-rejection archive, model-callable collapse) | Context as a read-write file; compaction is a special case of the model's own editing; re-prefill priced (7.7× head edit) and mitigated at the serving layer (Suffix Cache Reuse, 65% FLOPs) |
| Extension surface | jiti in-process TS extensions over one `ExtensionAPI` | Three-role seams, preset patches, npm distribution | Function-pointer deps; typed host capabilities; ACP shared by all hosts | PTC; state-machine factories; gated refinement commits | Ordinary Python declarations (methods, docstrings, annotations); strategies; model-callable harness APIs (`ContextApi`, `EventsApi`) | Harness protocol (mirror file + parser + prompts); optional ICL steering and RL layers; sha16-pinned skills |
| Subagents | Ownership-indexed conversations, bottom-up abort, background boundaries | Subagent providers (spawn/fork/SDK-external) | One-level, captured non-escalating authority; children invisible to external resume | Recursive spawn (depth 2), durable message results, quiescence factories | Depth-bounded `delegate` (max 4) constructing subagents of the same class; model-written fan-out over generated subcalls | Withheld from the release ("experimental features not part of this release"); Software World ran in the Pi harness |

Reading the table by column rather than by row shows what each approach optimizes for: Pi for
surface minimality and a documented, resumable session; dsh for modularity and one
reconstructable log; fx for enforced budgets and checked durability; Prime for retrieval-based
context and auditable autonomy; NOOA for context economy by reference, with compaction kept
off the critical path; CLM for making the context itself the editable artifact, with the cost
priced and mitigated at the serving layer. The benchmark evidence cuts across the columns:
same-model score spreads are large, the minimal loop is competitive, and most incremental
scaffolding does not pay for itself — so the engineering problem each harness solves hardest
is the one that distinguishes it.

## Cross-harness highlights

Where independent engineering arrived at the same answer, as observation:

- **Append-only event log as the session substrate**, realized differently: Pi as an entry
  tree with a leaf pointer, dsh as turn-enclosed generations under a lease, fx as a fenced
  fsynced log with TLA+ specs, Prime as separate ledgers per concern.
- **Turn boundaries as the only mutation points** for fork, compaction, and delivery; dsh
  makes crash repair and fork the same code path with different causes.
- **Concurrency from declared per-tool safety classes with ordered commits** in all three
  loop-level designs (dsh, fx, pi-durable).
- **Intent-before-effect journaling with explicit replay contracts** (fx, pi-durable; dsh via
  never-replay of failed programs plus synthesized interrupt closers).
- **Cache-aware prompt assembly** (dsh records change reasons and byte-stable catalogs; Pi
  replays prompt state from transcript entries; rasbt pins a stable prefix).
- **Fail-closed, honestly reported boundaries** (dsh's closed outcome unions and enforcement
  tables; fx's latched failure states; both refuse to guess).
- **Compaction made dormant rather than load-bearing**: NOOA budgets the projection, not the
  value — bounded previews with whole values in the process — and ships three compaction paths
  that stayed unused at reported token levels; the other harnesses budget values (bytes, cut
  points) and treat compaction as a required stage.

## Open questions on the approaches

- Where the minimal-loop ceiling sits: the benchmark record rewards interfaces (edit
  reliability, one interactive surface) and penalizes narrow tool additions, but long-horizon,
  multi-party, or compliance-heavy workloads are underrepresented in published results; no
  benchmark yet measures where heavier scaffolds begin to pay.
- Streaming interleaving: each loop-level design has a commit discipline for ordered logs
  (head-of-line cursor, leading-prefix fences, source-order persistence), and none publishes
  measurements of streamed tool output interleaved with the model stream under that discipline.
- Formal specification cost/benefit: fx is the only analyzed harness with TLA+ modules and
  runtime replay of TLC-generated state graphs; what the minimum viable spec set is for a
  given harness's durability claims is unexplored.
- Self-modification safety: Prime's gated, versioned refinement is the most developed
  mechanism, and its documented exploit shows the open problem; no benchmark measures
  refinement value against its risk.
- Pass by reference versus execution isolation: NOOA's no-compaction architecture requires
  in-process execution (its sandbox backend trades reference semantics away at the boundary),
  and its per-event budget fields are shipped no-ops; the tension between reference-based
  context economy and execution isolation is unresolved in every analyzed harness.
- Approach portability: Open Interpreter's harness-emulation switch (claude-code, swe-agent,
  minimal, and others on one core) suggests harness approaches are becoming testable,
  swappable artifacts; whether any approach's advantages survive that kind of controlled
  comparison is unmeasured.
- External-memory benchmarks conflict across vendors (Mem0, MemOS, and Zep report different
  LOCOMO/DMR results with different scoring), and ACE, Folding, and ReFold have no independent
  replications; compaction-free claims rest on vendor-reported numbers more often than on
  shared harnesses.
- Context-as-editable-artifact and networking costs are stack-specific: CLM's 7.7× head-edit
  price and its Suffix Cache Reuse mitigation are measured on one serving stack, and its
  paper/repo numbers drift; the context-networking verdicts identify the missing primitives
  (cross-session addressing, read grants, deref budgets, passivation consistency) but no
  implementation measures them.

Design work for baton-cli starts from these reports and this evaluation; no design decisions
are drawn here.
