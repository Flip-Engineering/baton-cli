# Synthesis: architectural patterns for baton-cli

This document synthesizes the six research reports in this directory into design guidance for
baton-cli, a minimal Bend2 agent harness for the baton orchestrator (possibly renamed Orchestra).
Method: each named harness was analyzed at code level (shallow clones at recorded HEAD commits;
see each report's Sources), the survey covered fifteen additional harnesses, and the benchmarks
report pulled figures from primary sources. GLM 5.3 Flash subagents authored the reports;
this synthesis was written from their concepts sections.

Reports: [pi.md](pi.md), [deepseek-harness.md](deepseek-harness.md), [fx.md](fx.md),
[prime-agent.md](prime-agent.md), [minimal-harness-survey.md](minimal-harness-survey.md),
[benchmarks.md](benchmarks.md).

## Convergent patterns

Five patterns recur across every harness analyzed, implemented independently in each codebase.

### 1. The session is an append-only event log; everything else is a projection

Pi stores sessions as immutable entry trees with a leaf pointer (fork = append a child of an
earlier node). DeepSeek's session log is the program: model history, pending input, tool
declarations, approval policy, and turn boundaries are all folds over one append-only,
turn-enclosed event stream. fx keeps an offset-confirmed, fsynced `events.jsonl` with a
state-machine validator; manifest, index, and UI state are re-derivable projections with
byte-exact staleness checks. Prime Agent runs sessions, spawn topology, and refinement history
as separate append-only JSONL ledgers. The survey found the same shape in Codex rollouts,
OpenHands typed events, gptme logs, and mini-SWE-agent's trajectory-equals-messages invariant.

Consequence for baton-cli: the session format is the design centerpiece. Model context, resume,
fork, compaction, and the orchestrator's view are all projections of one log. Correctness of
resume comes from the log shape, not from recovery code.

### 2. The turn is the unit of consistency; prefix operations are the only mutations

DeepSeek encloses all durable side effects in `turn/start`…`turn/end` and closes every exit path
with a reason; crash repair, fork, and interrupted-turn settling are the same operation with
different causes. Pi makes the turn (one model response plus its complete tool-result batch) the
atom for persistence, compaction cut points, and durable run phases. The survey's pattern:
fork, summarize, and compaction are prefix cuts or suffix replaces of the event log, and turn
boundaries are the only safe mutation points.

Consequence for baton-cli: the orchestrator's operations — resume a seat, fork a seat, compact a
seat's history, deliver an input — are all turn-boundary operations on one log. This matches the
orchestrator's existing resume/fork semantics exactly.

### 3. Concurrency is scheduled by declared safety class, committed in model order

DeepSeek classifies each tool (`isConcurrencySafe` → execution mode) and drives three schedulers
from that one classification: a rolling pool in the native loop, a bounded PTC sub-dispatch lane
(maxParallelSubCalls = 10), and tool-binding parallelism; ordered commits through a
head-of-line cursor keep the log model-ordered. fx groups leading prefix calls by declared class
(read-only / subagent / host-concurrent, capped at 16), runs the first writer alone, and fences
writers with file locks. Pi runs tool calls in parallel by default and persists results in
assistant source order.

Consequence for baton-cli: async-streaming tool execution (a stated design default) needs exactly
this machinery: a declared concurrency class per tool, streaming output as chunked events
appended in model order, a commit cursor, and cancellation of in-flight tools at turn end. The
reports show this is standard, load-bearing harness machinery, not an optional extra.

### 4. Effects are journaled before they run; recovery is replay under a contract

fx commits a `tool_intent` with a barrier before effect-bearing batches; on resume, ambiguous
calls are rerun under a stable execution id or answered as possibly-run, per a declared
idempotency/writes classification. pi-durable commits tool-call intent before execution and
reruns only when both the stored intent and the current tool definition declare replay-safe.
DeepSeek never replays a failed PTC program and synthesizes interrupted-turn closers rather than
truncating.

Consequence for baton-cli: tool calls are durable tasks with an intent-before-effect commit and
an explicit replay contract. This is also what makes orchestrator-driven fork/resume safe: a
forked seat can answer interrupted tools honestly.

### 5. Prompt assembly is cache-aware, and the prefix is an asset

DeepSeek records change reasons in request headers, admits tool-catalog changes as deltas, keeps
the tool catalog identical across modes, and renders the PTC SDK section byte-stable. Pi replays
prompt and tool state from transcript entries so unchanged state is never re-sent. rasbt's
mini-coding-agent (survey) pins a stable prompt prefix for cache reuse.

Consequence for baton-cli: the session format and prompt assembly must be designed together so
that wake deliveries and tool-catalog changes extend the prefix rather than rewriting it.

## What the benchmarks add

The benchmarks report (primary-source figures) sets the floor and the first investments:

- A near-zero harness is competitive at the top: mini-SWE-agent (bash-only, no tool-calling API,
  fresh process per action, linear history) scores >74% on SWE-bench Verified.
- Harness spread on the same model is large and real: on Terminal-Bench 2.0, GPT-5.4 mini scores
  57.8% on Codex CLI versus 37.8% on Terminus 2; Opus 4.6 spans 76.4% (Meta-Harness), 62.9%
  (Terminus 2), 58.0% (Claude Code). Harness choice moves scores by double digits.
- Extra narrow tools can score below having none (SWE-agent ablations: search tool -6.0, RAG
  scaffold 2.67% vs 18.0% for its ACI); the one tool that consistently pays is a single edit
  operation with a uniqueness check and error feedback (+7.7).
- Limits are load-bearing: step budgets and timeouts move scores and are logged as part of
  results.

Design translation: start bash + read + one robust edit tool + inbox; add nothing until a
measured gap justifies it; record limits as logged harness parameters.

## The Bend2-native opportunity: programmatic tool calls in the harness's own language

DeepSeek's PTC mode and Prime Agent's one-kernel-tool design both let the model write program
text that batches tool operations, instead of issuing discrete tool calls. Both run a foreign
runtime for this (Node/TypeScript for dsh, Python for Prime). baton-cli's harness is written in
Bend2 and compiles native — the model can emit Bend2 program text that the harness executes
directly, with the same confinement and logging machinery as discrete tools. No foreign runtime,
one language across harness, session tooling, and generated programs. This is the one capability
in this research that none of the analyzed harnesses has, and it aligns with the async-streaming
default: a generated program is a natural batching unit with one streamed result stream.

Research questions this raises, tracked in the README: what the generated-program surface
exposes, how programs confine (reuse the sandbox machinery of shell tools), and how program
results commit under the ordered log.

## Non-goals confirmed by the evidence

- A plugin microkernel with npm-style distribution (DeepSeek/Cordis) costs more than a
  minimal harness recovers; preset composition of a fixed tool catalog achieves the same
  mode-switching at the seam level.
- A full-screen TUI is a human-viewer investment; a headless orchestrator seat's interface is the
  event stream itself (fx's process-boundary protocols — `fx ask` stdout/stderr split, ACP
  ndJSON JSON-RPC — are the relevant prior art, and fx formalized durable session and steering
  semantics in TLA+ specs: `sdk/tests/model/DurableSession.tla`, `AgentRouting.tla`,
  `DurableSteer.tla`).
- Self-modifying harness state (Prime's refinement) is valuable for long-horizon autonomy but is
  the highest-risk pattern in the set (Prime documents its own RCON-exploit failure mode); it is
  a later milestone behind reviewed, versioned commits, not a v1 feature.

## Target shape

1. Session: append-only, turn-enclosed event log in Bend2; fork/resume/compact/deliver as
   turn-boundary prefix operations; the orchestrator's messages and receipts are events in the
   same log.
2. Tools: minimal set (read, write, edit, shell, inbox read) with declared concurrency classes,
   streaming chunked outputs committed in model order, intent-before-effect commits, and an
   explicit replay contract.
3. Programmatic lane: generated Bend2 programs as PTC, confined and logged like any tool.
4. Prompt assembly: cache-aware; stable prefix; tool catalog identical across presets.
5. Presets: minimal first (per DeepSeek's minimal mode and the benchmark evidence), standard
   later.
6. Boundaries: fail-closed, honestly reported; limits recorded as logged harness parameters.

## Open questions (carried)

- Exact concurrency semantics of streamed tool output interleaved with the model stream
  (fx marks its in-turn tool concurrency as an open question too).
- Whether compaction should be an operation on the log (dsh: rewrite preserving raw history;
  fx: raw history immutable under compaction) or a projection (survey's two-layer model).
- Generated-Bend2-program confinement and capability surface.
- Session format versioning and migration (dsh's v0/vN generation model is the most developed
  prior art).
