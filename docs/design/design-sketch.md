# Design sketch: baton-cli as a set of core concepts

Status: design-phase input. Earlier revisions of this sketch were organized by component (loop,
tools, planes). This revision is organized by concept, because the researched harnesses are best
understood — and best combined — at the level of the concepts driving them: each sampled harness
is a different arrangement of the same small set of ideas, and this harness's arrangement is the
claim being made here. Each concept states: the idea, the mechanism realizing it, the failure
modes it makes unreachable, and what the agent itself sees of it. Sources cite
[docs/research/](../research/).

The claim in one sentence: a harness is a small set of commitments held mechanically — one log,
two planes, turn-bounded mutation, declared contracts, one language, no rationing, honest
failure, an orchestrator plane, and an unbounded addressable store — and the agent operates
inside those commitments as its native interface, with no other apparatus at all.

```
┌──────────────────────────────────────────────────────────────┐
│ THE AGENT'S INTERFACE (what the model sees and calls)        │
│  previews of live values · a queryable event log · tools     │
│  whose contracts are visible · citations it can deref ·      │
│  programs in the harness's own language · typed errors       │
├──────────────┬───────────────────────┬───────────────────────┤
│ SESSION LOG  │ LIVE VALUE PLANE      │ ORCHESTRATOR PLANE    │
│ fenced       │ process heap: typed   │ cells, bindings,      │
│ append-only  │ variables, whole      │ citations, grants,    │
│ JSONL +      │ results, Bend2 state  │ wake inbox, knowledge │
│ manifest     │                       │ layer                 │
└──────────────┴───────────────────────┴───────────────────────┘
        ▲                │ previews only           ▲
        └── durability   ▼                           └── commit-and-cite
            at one boundary
```

## 1. One log; everything else is a projection

The session is an append-only, turn-enclosed event log — fenced, fsynced, offset-confirmed
appends behind a state-machine validator, with a byte-exact manifest and a disposable replay
cache ([fx.md](../research/fx.md) §10). Model context, resume, fork, compaction, crash repair,
and the orchestrator's view are all folds over this log; there is no second place where session
state lives. Crash repair and fork are the same operation at different causes
([deepseek-harness.md](../research/deepseek-harness.md) §5).

*Excludes:* parallel state stores that can disagree with the transcript; resume bugs of the
"reconstruct what must have happened" variety; any model-visible content that was not logged.
*Surfaced:* the agent can query its own past — the event log is an API (`events.query`,
typed, tagged), so its history is addressable data, not scrollback
([nooa.md](../research/nooa.md) §2.6).

## 2. Two planes: values live, renderings are bounded

Whole tool results live as values in the process. The transcript carries format-bounded
previews — item count, character count, depth are properties of the rendering spec, checkable
by reading it. When a result must cross a process boundary it changes representation: a handle
plus a preview, paged on demand ([fx.md](../research/fx.md) §3). Serialization to the log
happens at exactly one boundary, with a type allowlist and refusal of live objects
([nooa.md](../research/nooa.md) §3.4). There are no quotas, no counters, no token ledgers: the
amount of data the agent can process is bounded by the execution environment, the amount it
sees is bounded by the representation shown, and neither is measured — measuring them would be
fiction anyway, since token calibration requires a completed provider response and the moments
that matter have none ([deref-and-consistency.md](../research/deref-and-consistency.md) §1).

*Excludes:* compaction on the critical path; quota accounting; every "context pressure"
failure in #718. *Surfaced:* the model sees the invariant and can rely on it — "the variable
is not truncated; index it" — with paging when a rendering is large.

## 3. Turns are the only mutation points

One assistant response plus its complete tool batch is the atom. Every exit path closes the
turn with a reason; crash repair is fork with a different cause; orchestrator operations —
deliver, cite, promote a shared binding — happen at turn boundaries
([deepseek-harness.md](../research/deepseek-harness.md) §5.1, [pi.md](../research/pi.md) §4).
A truncated response fails every pending tool call with a re-issue instruction; a tool result
never separates from its call, enforced in cut points and in ordering
([pi.md](../research/pi.md) §12).

*Excludes:* mid-flight state ambiguity; torn sessions; the class of failure where a delivered
message lands inside a half-executed turn. *Surfaced:* steering arrives only at declared
boundary kinds — model, cancelled, finalizing ([fx.md](../research/fx.md) §7) — so the agent
experiences interruption as a clean boundary, and citations it receives always point at
settled, committed versions.

## 4. Declared contracts, honored mechanically

Tools and generated programs carry their contracts as data: concurrency safety class,
idempotency/writes declarations, permission target, result representation (inline preview,
spill-to-handle, or paged), timeout semantics ([fx.md](../research/fx.md) §3). The loop
schedules from the declaration — leading-prefix concurrent groups by class with a writer fence,
ordered commits through a head-of-line cursor ([fx.md](../research/fx.md) §4) — and effectful
calls journal an intent before running. The prompt-facing side of a contract renders from the
same predicate the executor enforces, so description and enforcement cannot drift
([deepseek-harness.md](../research/deepseek-harness.md) §4). The seat↔orchestrator protocol
itself is specified as small state machines and model-checked before implementation, with
TLC-generated states replayed against the runtime ([fx.md](../research/fx.md) §11).

*Excludes:* per-tool special cases in the loop; prompt/behavior drift; approval logic baked
into features. *Surfaced:* the model reads each tool's contract as part of the tool — the
description it sees is generated from the same data the scheduler obeys.

## 5. One language, end to end

The harness is Bend2 and compiles native. Generated programs are Bend2, executed natively
under the same confinement and logging as any tool — dsh's PTC contract with no foreign
runtime ([deepseek-harness.md](../research/deepseek-harness.md) §4). The developer's surface
and the model's surface are the same objects: NOOA's deepest insight, that the agent
interface can be ordinary declarations of the host language, adapted from Python classes to
Bend2 modules ([nooa.md](../research/nooa.md) §1).

*Excludes:* the Node/Python foreign-runtime seam every PTC predecessor carries; the
review/execute gap between harness code and model-written code. *Surfaced:* programs the
model writes are in the language of the harness it runs in — batched operations, one streamed
result, same logging.

## 6. Ration nothing

No step counter, no run-level time allowance, no quota narration — ever. Termination is one of
three things: the task completes, the model yields, or the operator stops. Operations carry
ordinary timeouts as tool contracts (a shell command fails when its timeout expires), and
elapsed time is telemetry. Benchmark harnesses step-cap for measurement; that is where step
caps belong, in instruments ([benchmarks.md](../research/benchmarks.md)).

*Excludes:* mid-task kills by arbitrary scalar — the same class of damage as #718, inflicted
deliberately; the harness second-guessing the trajectory. *Surfaced:* the agent never sees a
limit warning, a countdown, or a remaining-budget; it works until done or stopped.

## 7. Fail closed, speak exactly

Every boundary normalizes the unknown into a closed outcome union and reports what actually
happened: approvals fail closed with `unavailable`; sandbox enforcement reports full or
partial with named reasons; failed programs resolve as typed result fields and never replay;
a latched writer stops making effects rather than guessing
([deepseek-harness.md](../research/deepseek-harness.md) §6, [fx.md](../research/fx.md) §10).

*Excludes:* silent fallbacks; guessed states; the wedge where a consumer mistakes an
uncertain condition for a settled one. *Surfaced:* errors arrive as typed, addressable facts
the model can reason about, retry deliberately, or escalate — not as prose it must interpret.

## 8. The orchestrator is a plane, not a puppeteer

The seat's context variable commits as cells at turn boundaries under a declared snapshot
schema; briefs and reports carry `repl:` citations; dereferences are version-pinned MVCC
reads returning the cited representation; cross-seat read authorization is a server-minted,
non-transferable grant; shared state is an append-only ledger. Live-context dereference
across processes is out, by recorded design decisions everywhere
([context-networking.md](../research/context-networking.md) §2, §4;
[networked-context-program.md](../research/networked-context-program.md);
[baton#777](https://github.com/Flip-Engineering/baton/issues/777)).

*Excludes:* transcript-inlining delivery floods (#718, #720); the cross-process live-deref
category error; context state duplicated between seat and orchestrator. *Surfaced:* citations
are first-class in the agent's language — citing and dereferencing committed context is as
ordinary as calling a function, and what arrives is always a value with a
reference-shaped address.

## 9. The store is unbounded; the window is navigation

Append-only ledgers everywhere — the seat's own log, orchestrator cells, the knowledge layer —
make the addressable context unbounded while each participant's effective context is what it
navigates to: its local working set plus the committed versions it cites and derefs under
declared representation bounds. The committed store doubles as a search-state population:
idea-operators (tournament, top-k, exploration schedules) act as ranked reads over a typed,
scored store — the fifth context-management posture
([context-networking.md](../research/context-networking.md) §3.4,
[no-compaction-approaches.md](../research/no-compaction-approaches.md)).

*Excludes:* compaction pressure as a design driver; the lossy boundary moves from the context
window to commit/deref/authority time, where it is explicit and chosen. *Surfaced:* the
agent navigates its own and peers' committed context through the same variable grammar it
uses for everything else — the weak form of networked infinite context, buildable from parts
that all exist.

## What the composition forbids

Taken together the concepts leave no room for: a plugin marketplace (presets compose a fixed
catalog — [deepseek-harness.md](../research/deepseek-harness.md) §3, §7), a full-screen TUI
(the event stream is the interface; human views derive from it), narrow utility tools (the
ablations penalize them — [benchmarks.md](../research/benchmarks.md)), self-modifying harness
state in v1 (Prime's refinement behind reviewed commits is a later milestone —
[prime-agent.md](../research/prime-agent.md) §3), or compaction on the critical path.

## The bets

Three claims in this sketch are design positions, not established results, and each names its
own measurement:

1. Async-streaming tool execution outperforms blocking execution on real workloads — no
   published A/B exists; instrument it from the first milestone.
2. The Bend2 code lane is better than discrete tool calls for batched operations — measure
   against discrete calls with the PTC contract above.
3. Commit-and-cite beats transcript inlining on token cost and cache behavior for
   orchestrator-mediated work — the E1–E3 ladder in
   [networked-context-program.md](../research/networked-context-program.md).

## How the concepts compose

- 1 + 2 is the no-compaction architecture: the log never needs shrinking because bulk never
  enters it.
- 3 + 8 is orchestrator passing: turn-bounded commits on both sides make citations settle.
- 5 + 2 is the native code lane: generated programs read whole values by reference and render
  one bounded result.
- 9 + the search-state posture is the knowledge layer: a population with operators, not a
  transcript with a summary.
- 6 is what makes the rest coherent: no concept above needs a counter, and none has one.