# Design sketch: baton-cli

Status: proposal for the design phase, no implementation yet. This document states the shape of
a minimal Bend2 harness for the baton orchestrator and the reasons each choice has, drawn from
the sixteen reports in [docs/research/](../research/): the eight code-level harness studies, the
two no-compaction surveys, the benchmark survey, the context-networking evaluation, both
prior-art reports, and the networked-context program. Mechanisms cite the report they come from;
the three claims that are design positions rather than conclusions are marked as bets at the end.

## 1. What it is

One native Bend2 binary that runs one seat: it takes tasking, messages, receipts, and wakes over
the baton2 protocol; it runs a model turn loop against a small tool set; it appends everything to
a session log; and it can hand context to another seat by citation. Target size is a few thousand
lines, readable in an evening. There is no registry, no full-screen interface, no harness-local
memory service, no subagent spawning, no quotas, and no step cap.

## 2. The session log

Append-only JSONL, one file per seat, with turns bracketed. The format follows Unreal Agent's
item vocabulary — a versioned header, then `fork`, `input`, `turn`, `model_response`,
`tool_call_status`, and operation records with contiguous sequence numbers validated on append
and load, committed through a temporary file plus fsync and directory sync
([unreal-agent.md](../research/unreal-agent.md) §6). Tool-call status is persisted atomically
together with the operations it waits for, which closes the window between "translation
succeeded" and "dispatch recorded".

Invariants, each arrived at independently by more than one harness:

- Every turn closes with a reason on every exit path, including crash repair; an aborted stream
  settles as an interrupted message rather than disappearing
  ([deepseek-harness.md](../research/deepseek-harness.md) §1.1).
- A tool result never separates from its call, enforced in cut points and in ordering
  ([pi.md](../research/pi.md) §4; [arcee-nac.md](../research/arcee-nac.md) §4).
- Output truncated by the model's own token limit fails every pending tool call with a re-issue
  instruction ([pi.md](../research/pi.md) §12).
- Effectful calls journal an intent before running ([fx.md](../research/fx.md) §4).
- A writer that finds the log no longer ends where it last committed latches a failure state
  ([fx.md](../research/fx.md) §10).
- Inputs are idempotent by a caller-supplied id and are persisted before processing
  ([unreal-agent.md](../research/unreal-agent.md) §3).

Crash repair and fork are the same operation at different causes: a fork copies a log prefix and
starts a new continuation ([deepseek-harness.md](../research/deepseek-harness.md) §5;
[prime-agent.md](../research/prime-agent.md) §7). A fork must not inherit in-flight calls without
results; Unreal Agent ships that as a live `FIXME` and it is the defect that would poison a
branch permanently ([unreal-agent.md](../research/unreal-agent.md) §12).

Compaction exists as an appended turn with a provenance digest over the compacted prefix, a
retained tail, and carry-forward of every pending call with its latest stub
([arcee-nac.md](../research/arcee-nac.md) §4;
[unreal-agent.md](../research/unreal-agent.md) §7). It is expected never to fire.

## 3. Context: two planes

The process holds whole values. The transcript carries renderings whose size is a property of
the rendering format — item counts, character counts, depth, checkable by reading the format —
and every rendering has a handle to the whole value behind it
([nooa.md](../research/nooa.md) §3.2). Output past its bound spills to a content-addressed file
under the session directory and the model receives preview plus path
([fx.md](../research/fx.md) §3; [unreal-agent.md](../research/unreal-agent.md) §4;
[arcee-nac.md](../research/arcee-nac.md) §4). Serialization to durable form happens at exactly
one boundary, and live objects are refused ([nooa.md](../research/nooa.md) §3.4). Truncation is
typed and never silent ([context-networking.md](../research/context-networking.md) §3.2).

The prompt is three regions: a byte-stable static prefix (framework prompt, tool schemas, seat
charter), an append-only tagged event stream, and a dynamic tail re-evaluated each turn over
live state ([nooa.md](../research/nooa.md) §3.1). The tool catalog is written once and masked at
decode rather than mutated, because adding or removing a definition invalidates the prefix from
that token and leaves earlier turns referencing tools that no longer exist
([no-compaction-approaches.md](../research/no-compaction-approaches.md) §1;
[deepseek-harness.md](../research/deepseek-harness.md) §10). Provider-resident parts — reasoning
signatures, provider tool-call ids — are re-attached only when the current provider and model
match ([fx.md](../research/fx.md) §9).

The reason this shape matters is measured: NOOA reaches 82.2% on SWE-bench Verified at roughly 28
model calls and 1.1M tokens per task against comparison harnesses' 66 calls and 2.2M
([nooa.md](../research/nooa.md) §3.5), and in twelve-hour containerized runs the
context-managing methods keep improving across the full window while an append-only baseline
stops improving inside the first two hours
([context-language-models.md](../research/context-language-models.md) §5).

## 4. The loop is async-first

A turn may end with work in flight. Pending calls are durable operation records — versioned,
serializable, stable ids, at-most-once semantics ([unreal-agent.md](../research/unreal-agent.md)
§4) — and the transcript holds a fixed stub for each while the operation runs. Completion
replaces the stub inside the uncommitted staging window, or appends a second item for the same
call id where replacement is impossible; replacement is the primary path because the two-item
form is provider-dependent ([unreal-agent.md](../research/unreal-agent.md) §5).

Results commit in batches at turn boundaries: arrived operations and inputs are drained together
under an idle cap with a short grace window so nearly simultaneous completions share one turn
([unreal-agent.md](../research/unreal-agent.md) §3). Batching keeps an append-only transcript
cheap — N results produce one prefix extension — and commits stay model-ordered through a
head-of-line cursor while completion order varies
([deepseek-harness.md](../research/deepseek-harness.md) §1.1).

The model's join primitive is a handle: end the turn and the seat sleeps until something lands,
then read the tail or the full output ([prime-agent.md](../research/prime-agent.md) §3). Ending a
turn with nothing running ends the session. Steering, wakes, stops, and settings arrive as
control inputs in the same single-writer inbox, committed immediately and delivered at the next
boundary; a steering message never queues behind a tool call
([unreal-agent.md](../research/unreal-agent.md) §3; [arcee-nac.md](../research/arcee-nac.md) §2).
Effects keep writer fences: reads overlap freely, the first writer runs alone
([fx.md](../research/fx.md) §4).

## 5. Tools and the program lane

`bash`, `read`, `edit`, and the orchestrator inbox, plus generated Bend2 programs executed
natively in the same confinement, logging path, and operation layer as any tool. The program
lane follows dsh's contract: one reserved entry point, a byte-stable SDK section rendered in
sorted order, nested calls re-entering the full guarded pipeline with parent-child call-id
correlation, a bounded overlap pool, typed failure outcomes, and no replay of a failed program
([deepseek-harness.md](../research/deepseek-harness.md) §4). Where dsh runs programs on Node and
Prime on Python, this harness runs them in the language it is written in.

Each tool carries its contract as data: name and schema, concurrency class, idempotency and
writes declarations, permission target, result representation, timeout semantics
([fx.md](../research/fx.md) §3). The edit tool is the only one with real internal machinery:
unique match or refuse, the diff shown before applying, the preimage captured so undo restores
exact bytes ([fx.md](../research/fx.md) §5), and Anthropic's interface discipline — absolute
paths, formats close to text the model has seen, no line-count arithmetic in the format
([minimal-harness-survey.md](../research/minimal-harness-survey.md) Anthropic section). It is the
one addition the ablations price as worth having, at +7.7 points
([benchmarks.md](../research/benchmarks.md) SWE-bench section); narrow utility tools measurably
lose, and one interactive execution surface is competitive with many.

Nothing further is added until a measured gap argues for it. The exception is the seat extending
itself, which is the next section.

## 6. Self-extension

A tool is a Bend2 module with a declared contract. The model writes one with `edit`, admits it
through a model-callable registration step, and it loads through the same module loader,
confinement, and logging as the shipped four. There is no registry, no dependency resolution, and
no installer that fetches anything: extension comes from the seat's own writing or from an
orchestrator-mediated artifact with provenance.

Four properties make this safe enough to leave available:

- The contract is validated at admission, and the description the model reads is generated from
  the same data the executor enforces, so description and behavior cannot drift
  ([deepseek-harness.md](../research/deepseek-harness.md) §4).
- Admission is a logged event carrying the module digest, the admitting principal, and the
  approval that authorized it; installing capability requires the same authorization as any other
  effectful action ([deepseek-harness.md](../research/deepseek-harness.md) §2).
- Extensions inherit the seat's authority and cannot widen it; escalation is refused rather than
  clamped ([fx.md](../research/fx.md) §8).
- Extension state is in the log, so a resumed seat knows which capabilities it had, and nothing
  about capability is ambient.

Self-extension is context economy as much as capability: a minimal tool set forces composition,
and repeated composition is what should be compiled. A program written five times in a session
becomes a tool, and every subsequent use costs fewer turns and less transcript. Prime stores an
orchestration graph as a versioned, refinable artifact for the same reason
([prime-agent.md](../research/prime-agent.md) §4), and the measured version of the claim is
CLM's skill evolution, where an evolved procedure took a held-out task from 38.3 to 74.2 at lower
compute behind a Pareto gate ([context-language-models.md](../research/context-language-models.md)
§5).

Promotion follows the same gate: an extension that pays on one branch is a candidate shared
artifact — a cell carrying the module source, its declared contract, and its evaluation record —
adopted by other seats explicitly under a grant. The gate is statistical where a task suite
exists (promote when the mean-reward delta beats the paired standard error, ties broken by cost,
held-out split touched once after the archive freezes —
[context-language-models.md](../research/context-language-models.md) §4) and a review gate where
one does not ([prime-agent.md](../research/prime-agent.md) §6).

Catalog changes are deliberate and rare: registration happens at a turn boundary, emits a
`harness.change` event, and records a change reason in the request header, because a catalog
change invalidates the cached prefix from the changed block onward
([deepseek-harness.md](../research/deepseek-harness.md) §10). The shipped tool set changes only
through repository work; self-extension adds capability to a seat and does not alter what
"minimal" means.

## 7. Fork, branch, and ensemble

A fork carries the seat's state of modification, so the fork record is a triple with a basis
digest: the log prefix, a harness-state version vector (admitted extensions with per-module
digests and versions, plus the seat's standing typed state), and a workspace checkpoint
(preimages, or a checkpoint before multi-file mutation in the style of Gemini CLI's shadow-git
snapshots — [minimal-harness-survey.md](../research/minimal-harness-survey.md) Gemini CLI
section). NAC's provenance digests over a compacted prefix are the model for the digest
([arcee-nac.md](../research/arcee-nac.md) §4), and fx's checkpoint metadata — with a typed
mismatch event naming what changed — is the model for the check
([fx.md](../research/fx.md) §12).

Loading a branch compares its basis: harness core version, admitted extension set and digests,
tool schema hash, model. A mismatch either refuses the load or runs in a declared degraded mode,
and it is reported as a typed event, never as a silent difference in behavior.

Three consequences for ensemble work. Trajectories carry their capability set, in the spirit of
CLM's harness fingerprint in usage records, so a comparison across branches does not confound
capability with strategy ([context-language-models.md](../research/context-language-models.md)
§3). Adoption of another branch's extension is a new admission event on the adopting branch, so
both branches keep self-describing histories and no log is rewritten. Promotion to the shared
plane is the only cross-branch movement of capability, and it happens through the orchestrator
under a grant.

## 8. The orchestrator plane

Hand-off artifacts — a plan, an inventory, an index, a decision record, and not the raw
transcript — commit as cells into the seat's `worker:<seat>` layer at turn boundaries, and briefs
and reports carry citations (`repl:<scope>:<name>@<version>`). Receivers dereference through the
orchestrator: a version-pinned read that returns the cited representation, bounded with paged
reads beyond it, and marks the version in its receipt, so a read issued while the owner is inside
a turn is served from the last committed version
([context-networking.md](../research/context-networking.md) §2;
[deref-and-consistency.md](../research/deref-and-consistency.md) §2).

Grants follow the capability record: attenuation-only derivation with a recorded lineage and
subtree revocation from the object-capability lineage, request-time caveats (`run`, `binding`,
`version <= V`, expiry) evaluated at deref time from macaroons, and persistability declared per
grant for grants that outlive a passivated seat, in the spirit of persistent capabilities
([addressing-and-authority.md](../research/addressing-and-authority.md) §1). Revocation cuts
future dereferences and does not retro-invalidate an already-resolved citation, because citations
pin versions. Shared state is an append-only ledger; live shared mutable context stays closed,
on the distributed-shared-memory record, where a fence bump per commit reproduces false sharing
in the reader's cache ([deref-and-consistency.md](../research/deref-and-consistency.md) §3).

Commits are deliberate acts rather than a per-turn rhythm: every rebind bumps the scope fence and
invalidates fence-keyed projection caches
([context-networking.md](../research/context-networking.md) §6). Peer content arrives as
untrusted input with ledger-derived provenance, is sanitized, and cannot carry a self-cited
authority claim ([context-networking.md](../research/context-networking.md) §4.2); an editable
or imported context is an injection channel, and the corpus names compaction summaries as a place
injections have survived ([context-language-models.md](../research/context-language-models.md)
§7).

## 9. Standing state in the seat

Words the model needs to keep in view across turns live on one small typed surface: a workset
with a goal, ordered items carrying scope, acceptance, and dependencies, a status, and a
verification recipe — NAC's shape ([arcee-nac.md](../research/arcee-nac.md) §5) — rendered into
the dynamic tail each turn, so no recitation turn is needed. Markdown notes files are prohibited
by the same design that forbids them in NAC's orchestrator prompt, and Anthropic's initializer
agent chose JSON over Markdown for the same reason, that models overwrite Markdown more readily
([no-compaction-approaches.md](../research/no-compaction-approaches.md) §2).

## 10. Safety and reversibility

Two explicit layers: a sandbox mode controlling what the seat can technically do, enforced by the
operating system with network off by default and repository metadata read-only inside writable
roots, and an approval policy controlling when it must ask
([minimal-harness-survey.md](../research/minimal-harness-survey.md) Codex CLI section). Every
boundary fails closed with a closed outcome union and reports what happened: full or partial
enforcement, named denial reasons, `unavailable` for an answerer that throws
([deepseek-harness.md](../research/deepseek-harness.md) §6). Approvals are invocation-only and do
not create reusable grants ([arcee-nac.md](../research/arcee-nac.md) §7). Undo is content-backed:
preimages per mutation, checkpoint-before-mutate for multi-file work, and a report of
`unavailable` rather than a guess when the preimage is missing ([fx.md](../research/fx.md) §5).

## 11. Deliberate omissions

- No plugin registry or distribution channel; extension is local or orchestrator-mediated
  ([deepseek-harness.md](../research/deepseek-harness.md) §8).
- No full-screen interface; the event log is the interface, and human views derive from it
  ([fx.md](../research/fx.md) §7, §15).
- No harness-local memory service; the standing store is the orchestrator's knowledge layer, the
  position gptme's cross-harness memory store and baton's own graph already take
  ([minimal-harness-survey.md](../research/minimal-harness-survey.md) gptme section;
  [no-compaction-approaches.md](../research/no-compaction-approaches.md) §7).
- No subagent spawning, factories, or model-side decomposition; a seat that needs help asks its
  conductor ([prime-agent.md](../research/prime-agent.md) §11.2).
- No quotas, counters, or step caps in a working seat. Benchmark instruments cap steps because
  they are instruments ([benchmarks.md](../research/benchmarks.md) concept 5); operational
  limits such as per-call timeouts are properties of individual tools.
- No stateless execution per action; a live, streaming shell is required by the async contract
  ([minimal-harness-survey.md](../research/minimal-harness-survey.md) "What does not transfer").

## 12. Instrumentation

Three questions in the corpus are unmeasured, and the harness ships the switches to answer them:
async versus blocking tool execution (no published controlled comparison exists —
[benchmarks.md](../research/benchmarks.md) unknowns), the program lane versus discrete calls, and
citation hand-off versus inline transfer. The switches are the context postures themselves —
append-only, projection-bounded, writable-mirror — in the spirit of Open Interpreter's harness
emulation ([minimal-harness-survey.md](../research/minimal-harness-survey.md) Open Interpreter
section).

Records the seat emits by default: ATIF-style trajectory items including the capability set;
per-deref receipts with cited version, resolved cell id, digest match, bytes delivered, shed
markers, and latency ([deref-and-consistency.md](../research/deref-and-consistency.md) §4.4);
provider-counted and estimated token counts kept separate; and parse-failure events, since format
failures suppress measured scores and are invisible unless logged
([benchmarks.md](../research/benchmarks.md) Aider section).

## 13. Engineering discipline

Binary size and startup latency gated in CI ([fx.md](../research/fx.md) §1). The
seat-to-orchestrator protocol specified as a small state machine, model-checked with witness
configurations that must violate each named invariant, then replayed against the runtime
([fx.md](../research/fx.md) §11). Codec fixtures and fuzz tests, which is where Unreal Agent's
repository carries its engineering weight ([unreal-agent.md](../research/unreal-agent.md) §6).
Tests outnumbering source is expected rather than exceptional.

## 14. Bets

1. Async-first tool execution beats blocking execution on tokens and wall-clock for long-horizon
   work. Settled by the emulation switch, same model, pinned harness version, logged parameters.
2. Generated Bend2 programs beat discrete tool calls for batch operations. Settled by running the
   same task set with and without the lane.
3. Citation hand-off beats inline transfer on token cost and cache stability, with
   replay-exactness holding across seat restarts
   ([context-networking.md](../research/context-networking.md) §5.1). Settled by a two-seat task
   where one seat's work needs the other's intermediate state, against an inline baseline and a
   re-derivation baseline.

Each has a falsification condition: if commits must be frequent to stay useful, if deref costs
make the reader re-derive anyway, or if async does not reduce turns in practice, the
corresponding choice is revised.

## 15. Milestones

1. Log, loop, four tools, and a headless seat that completes a baton-assigned task; codec
   fixtures and fuzz; protocol spec written and checked.
2. The async operation layer: stub contract, batching, handles, crash-resume of in-flight work.
3. The program lane, then self-extension with an admission path and an evaluation record.
4. Commit-and-cite between two seats, grants and deref receipts, then the measurement campaign.

## 16. Open questions

- Whether an extension admitted on one branch can be merged into another's log, or only adopted
  as a new admission (the current position: adoption only, so both histories stay self-describing).
- Who runs the promotion gate when no task suite exists.
- Whether catalog changes must wait for turn boundaries, which is the conservative reading of the
  cache evidence and costs latency before a fresh capability is usable.
- Commit cadence for hand-off artifacts, and its interaction with receiver cache stability.
- Deref representation bounds: what a first version of a cross-seat read should return, given that
  no corpus system bounds a cross-session read ([deref-and-consistency.md](../research/deref-and-consistency.md) §5).
- Whether a cross-scope dereference needs a defined snapshot, or every networked read names
  exactly one binding version ([addressing-and-authority.md](../research/addressing-and-authority.md) §6).