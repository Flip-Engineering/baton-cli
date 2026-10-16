# Design sketch: baton-cli

Status: design-phase input. This sketch describes what a minimalist, state-of-the-art harness
looks like if it takes the best from every sampled harness and research approach, given two
fixed constraints: the harness is written in Bend2 and compiles native, and it is a seat driven
by the baton orchestrator (tasking, messages, receipts, wake delivery). Every choice cites the
reports in [docs/research/](../research/) that ground it; the traceability table at the end
maps decisions to sources.

## Thesis

A thin loop over three data planes, where state lives in values, the transcript is append-only,
and everything the orchestrator touches is content-addressed. The benchmark evidence says the
loop is the instrument and most scaffolding does not pay for itself ([benchmarks.md](../research/benchmarks.md)):
state-of-the-art is engineering discipline in four places — durability correctness, context
economy, async-streaming semantics, and orchestrator-native passing — not feature count.

## Three data planes

```
┌─────────────────────────────────────────────────────────────┐
│ LOOP (thin; hooks are the only policy surface)              │
│  turn = model stream + tool batch; boundaries for steering  │
├──────────────┬──────────────────────┬───────────────────────┤
│ SESSION LOG  │ LIVE VALUE PLANE     │ ORCHESTRATOR PLANE    │
│ fenced       │ process heap: typed  │ cells (cell:sha256),  │
│ append-only  │ context variables,   │ version-CAS bindings, │
│ JSONL +      │ whole tool results,  │ repl: citations,      │
│ byte-exact   │ Bend2 program state  │ grants, wake inbox    │
│ manifest +   │                      │                       │
│ replay cache │                      │                       │
└──────────────┴──────────────────────┴───────────────────────┘
        ▲                 │ previews only           ▲
        └── durability    ▼                          └── commit-and-cite
            at one boundary (snapshot with type allowlist)
```

- **Session log.** fx's engineering bar on Pi's shape: fenced, fsynced, offset-confirmed
  appends behind a state-machine validator; byte-exact manifest with a disposable binary replay
  cache for resume; turn-enclosed, with every exit path closing the turn with a reason and
  crash repair and fork sharing one mechanism at different causes
  ([fx.md](../research/fx.md) §10, [pi.md](../research/pi.md) §6,
  [deepseek-harness.md](../research/deepseek-harness.md) §5). Fork, compaction, and orchestrator
  delivery are prefix operations on this one log.
- **Live value plane.** Bound the rendering, not the value
  ([nooa.md](../research/nooa.md) §3): tool results stay whole as values in the process; the
  model sees typed, data-defined previews; serialization happens at exactly one boundary
  (durability, with a type allowlist and refusal of live objects). This is the no-compaction
  architecture, and it is available precisely because the harness's second data plane is its
  own process — which is what compiling Bend2 native provides.
- **Orchestrator plane.** The part no sampled harness has: commit-and-cite context passing,
  version-pinned MVCC dereferences that return the cited representation — a bounded preview
  for large cells, paged reads beyond it — macaroon-caveat grants, and an append-only shared
  ledger for state two seats must both see
  ([networked-context-program.md](../research/networked-context-program.md);
  [baton#777](https://github.com/Flip-Engineering/baton/issues/777)).

## The loop

Pi's turn semantics as the reference: one assistant response plus its complete tool batch is
the atom of persistence and compaction; a tool result never separates from its call (enforced
in cut points and in ordering); a truncated response fails every pending tool call with a
re-issue instruction ([pi.md](../research/pi.md) §4, §12). Hooks (`beforeToolCall`,
`finishTurn`, `prepareRequest`, `prepareNextTurn`) are the only policy surfaces;
approval and context policy live there, never in features. Steering is admitted only at
declared boundary kinds — model, cancelled, finalizing ([fx.md](../research/fx.md) §7). The
loop rations nothing: no step counter, no run-level time allowance. Operations carry ordinary
timeouts as part of their tool contracts — a shell command fails when its timeout expires —
and elapsed time is telemetry, not a gate. Runaway control is the operator's stop, which is
always effective; benchmark harnesses step-cap for measurement, and that is where step caps
belong.

## Tools

Minimal by evidence: bash, read, one robust edit (uniqueness-checked, errors fed back), and
the inbox read — narrow utility tools measurably hurt, and the single edit operation is the
one addition that reliably pays ([benchmarks.md](../research/benchmarks.md) SWE-agent
ablations). Plus the Bend2 code lane: generated Bend2 programs execute directly under the same
confinement and logging as discrete tools — dsh's PTC contract (fresh confined process,
byte-stable SDK section, typed failure taxonomy, failed programs never replayed) with the
harness's own compiled language as the runtime
([deepseek-harness.md](../research/deepseek-harness.md) §4). Each tool carries its contract as
data: concurrency safety class, idempotency/writes declarations, permission target, and result
representation (inline preview, spill-to-handle, or paged)
([fx.md](../research/fx.md) §3). Execution: leading-prefix groups by declared class with a
writer fence; a `running` placeholder result committed immediately and replaced or supplemented
on completion ([unreal-agent.md](../research/unreal-agent.md) §5); intent-before-effect
journaling for effectful calls ([fx.md](../research/fx.md) §4); ordered commits through a
head-of-line cursor so the log stays model-ordered. Oversized results spill to
content-addressed handles with previews, searchable after resume — the handle serves the
cross-process case, while the value itself may still be live in-process.

## Bounds are representations, not accounting

Nothing in the harness enforces a quota. Every model-visible surface is a representation whose
size is bounded by its own contract: previews are bounded by the rendering format's spec (item
count, character count, depth); event fields are bounded by the event schema; oversized tool
results change representation — they become a handle with a preview, and paging reads the rest
on demand; dynamic tail blocks render whatever their expression yields, and whole-block
eviction handles the pathological case. The amount of data an agent can process is bounded by
the execution environment, and the amount it can *see* is bounded by the representation it is
shown — no ledger measures either.

Two hard gates exist and both are named failure paths, not accounting: admission (cells are
size-capped at the orchestrator boundary) and reaction (if the provider rejects a request, the
overflow archive sheds old events — an exception handler, not a policy engine). Token-denominated
ledgers would be fiction anyway: token calibration needs a completed provider response, and
the moments where a bound would matter are exactly the moments without one
([deref-and-consistency.md](../research/deref-and-consistency.md) §1.3 — its enforcement
analysis is superseded on this point by the representation contract). Abuse-limiting rate
accounting belongs to the orchestrator's operations plane, outside the harness.

This is also what "bounded" means everywhere below: a property of a representation, checkable
by reading its spec, never a running counter.

And the harness rations nothing anywhere: no step counters, no time allowances over the run.
The only external control on how long a seat works is the operator's stop — a judgment call,
made by something that can see the work, at the moment it matters.

## Context and compaction

Three regions, as NOOA renders them: a byte-stable static prefix, an append-only typed event
stream with stable tags, and a dynamic tail re-evaluated each turn — live-state updates
re-render the tail without invalidating the cached prefix. Compaction ships in triplicate and
stays dormant by headroom: an opt-in summarizer at 75% of the window, a reactive archive on
actual provider rejection, and model-callable collapse with originals addressable by tag
([nooa.md](../research/nooa.md) §3.6). If compaction fires, it is lossy-verbatim reclamation:
user intent and final answers verbatim, everything else displaced into searchable records
([fx.md](../research/fx.md) §13). From CLM the design takes only the pricing discipline — every
context mutation is measured and surfaced in telemetry (a head edit costing 7.7× an append is
the honesty standard) — not the read-write-context mechanism
([context-language-models.md](../research/context-language-models.md)).

## Orchestrator integration

The seat is a first-class session: its context variable commits as cells at turn boundaries
under a declared snapshot schema; briefs and reports carry `repl:` citations; dereferences are
MVCC reads — serve last-committed with the version marked in the receipt — returning the cited
representation, a bounded preview with paged reads beyond it; cross-seat read authorization is a
server-minted, non-transferable grant; shared state is an append-only ledger, the only sharing
mechanism consistent with baton's recorded non-goals
([context-networking.md](../research/context-networking.md),
[addressing-and-authority.md](../research/addressing-and-authority.md),
[deref-and-consistency.md](../research/deref-and-consistency.md)). The committed store doubles
as a search-state population: idea-operators (tournament, top-k, annealing-style exploration
  schedules) act as ranked reads over a typed, scored store — the fifth context-management posture
([context-networking.md](../research/context-networking.md) §3.4), and the natural fit for
baton's knowledge layer.

## Modes and engineering discipline

Modes are agent presets composing a fixed tool catalog, minimal first
([deepseek-harness.md](../research/deepseek-harness.md) §3; the benchmark evidence favors the
minimal loop). Engineering discipline carried wholesale: CI gates on binary size and
trivial-command wall clock; formal-first contract specification — small state-machine models of
the seat↔orchestrator protocol in the spirit of fx's `DurableSession.tla`,
`DurableSteer.tla`, and `AgentRouting.tla`, with TLC-generated states replayed against the
runtime before and after implementation ([fx.md](../research/fx.md) §1, §11);
fail-closed, honestly reported boundaries — closed outcome unions, full/partial enforcement
tables, latched failure states, never a silent fallback
([deepseek-harness.md](../research/deepseek-harness.md) §6, [fx.md](../research/fx.md) §10).

## Deliberately lacking

- No plugin marketplace: preset composition over a fixed catalog (dsh's Cordis machinery costs
  more than a minimal harness recovers).
- No full-screen TUI: the event stream is the interface; human views derive from it (fx's
  process-boundary protocols as the pattern; its scrollback investment is a human-viewer
  cost).
- No self-modifying harness state in v1: Prime's refinement is the highest-risk pattern in the
  set (its own documented exploit), behind reviewed versioned commits as a later milestone.
- No narrow utility tools beyond the evidence-backed set.
- No compaction on the critical path.

## Open bets, to be measured

1. Async-streaming tool execution has no published A/B against blocking execution; the harness
   instruments this from the first milestone (same model, pinned versions, logged limits).
2. The Bend2 code lane (PTC in the harness's own compiled language) is unproven: the minimal
   experiment is one program surface with confinement, byte-stable SDK rendering, and a typed
   failure taxonomy, measured against discrete tool calls.
3. The orchestrator-plane experiments E1–E3 (commit-and-cite, one navigation path, the
   measurement campaign) are defined in
   [networked-context-program.md](../research/networked-context-program.md).

## Traceability

| Decision | Grounded in |
| --- | --- |
| Fenced append-only log; turn enclosure; crash repair = fork | fx.md §10; pi.md §6; deepseek-harness.md §5; unreal-agent.md §6 |
| Turn semantics (length fails pending calls; result cohesion) | pi.md §4, §12 |
| Hooks as the only policy surface | pi.md §8, §11 |
| Minimal tool set; one edit investment | benchmarks.md; minimal-harness-survey.md |
| Contracts-as-data per tool | fx.md §3; deepseek-harness.md §1.1 |
| Async streaming: prefix classes, ordered commits, placeholder→final | fx.md §4; unreal-agent.md §5; deepseek-harness.md §1.1 |
| Intent-before-effect; idempotency classes | fx.md §4; pi.md §9 (pi-durable); unreal-agent.md §5 |
| Bounded rendering; values live in-process | nooa.md §3; prime-agent.md §1 (contrast) |
| Three-region transcript; cache stability | nooa.md §3.1; deepseek-harness.md §6; no-compaction-approaches.md §1 (Manus) |
| Spill handles for cross-process results | fx.md §3, §10 |
| Compaction dormant; lossy-verbatim if fired | nooa.md §3.6; fx.md §13; no-compaction-approaches.md §2 |
| Pricing discipline for context mutations | context-language-models.md |
| Bend2 code lane (PTC in own language) | deepseek-harness.md §4; prime-agent.md §2; nooa.md §2 (CodeAct) |
| Orchestrator plane: commit-and-cite, MVCC derefs, grants, shared ledger | context-networking.md; addressing-and-authority.md; deref-and-consistency.md; networked-context-program.md; baton#777 |
| Presets, not microkernel; minimal first | deepseek-harness.md §3, §7; benchmarks.md |
| CI size/latency gates; formal-first protocol specs | fx.md §1, §11 |
| Bounds as representations, not accounting | nooa.md §3.2; fx.md §3; deref-and-consistency.md §1 (superseded on enforcement) |
| Fail-closed honest reporting | deepseek-harness.md §6; fx.md §10 |
| Search-state posture over the knowledge store | context-networking.md §3.4 |
| Refinement deferred behind reviewed commits | prime-agent.md §3; networked-context-program.md |