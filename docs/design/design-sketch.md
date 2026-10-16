# Design sketch: baton-cli

Status: design proposal. No implementation exists. This revision incorporates the findings of the
seven-agent adversarial review consolidated in [audit-findings.md](audit-findings.md); the audit
documents carry the full citations, and this document states the resulting design. Scope is not
reduced by build phasing: the phasing notes in §15 sequence work, they do not remove mechanisms.

The target is the **baton2** orchestrator (the Bend2 line), including the REPL layer being added to
it (`docs/capabilities/coordination-repl.md`, `docs/33-shared-objects-repl-layer.md` in the baton2
tree). The JavaScript baton line exists and carries a landed version of the same layer; the seat
targets baton2 and treats the JS line as reference evidence for the layer's semantics.

## 1. What it is

One native Bend2 binary that runs one seat: it takes tasking and delivers reports over the baton2
coordinator surface, runs a model turn loop against a small tool set, appends everything to a
session log, and hands context to other seats by citation through the orchestrator's REPL layer.

Size, stated against the measured reference rather than aspirationally: the baton2 Bend2
coordinator is 4,484 lines of Bend2 plus 714 lines of authored C for a comparable scope
(coordination, durable state, worker lifecycle, Git, CLI) ([feasibility-bend2.md](feasibility-bend2.md)
§"Proposed amendments" item 10). The four tools, the log, and the loop fit in that range; the
durable session log, the provider client, the out-of-process program lane, and the extension paths
put the floor near it. C is part of this harness: Base ships no process spawn, no fsync, rename,
stat or mkdir, no TLS, no HTTP, and no JSON at the pin, and baton2 already ships C bindings for the
process and JSON halves.

## 2. The session log

Append-only JSONL, one file per seat, turns bracketed. The item vocabulary follows Unreal Agent: a
versioned header, then `fork`, `input`, `turn`, `model_response`, `tool_call_status`, and operation
records with contiguous sequence numbers validated on append and load
([unreal-agent.md](../research/unreal-agent.md) §6). Tool-call status is persisted atomically with
the operations it waits for, which closes the window between a successful translation and a
recorded dispatch.

Durability is a named effect family, because Base provides no fsync, rename, stat, or locking
([feasibility-bend2.md](feasibility-bend2.md) item 4):

- Commit an appended record with `O_APPEND` plus `fsync(file)`.
- `fsync(directory)` at file creation, replacement, and rotation.
- Temp file plus `rename` for rotation and compaction only, not for every commit.
- A `flock` single-writer lock, with a writer that finds the log no longer ends where it committed
  latching a failure state rather than guessing ([fx.md](../research/fx.md) §10).
- Frames past a few hundred kilobytes cross as `List<U32>` bytes through the byte-read and
  byte-write calls; `String` is a linked list of characters.

Invariants, each verified in more than one analyzed harness ([audit-evidence.md](audit-evidence.md)
grading table rows 1-16):

- Every turn closes with a reason on every exit path, including crash repair; an aborted stream
  settles as an interrupted message ([deepseek-harness.md](../research/deepseek-harness.md) §1.1).
- A tool result never separates from its call, in cut points and in ordering
  ([pi.md](../research/pi.md) §7; [arcee-nac.md](../research/arcee-nac.md) §4).
- Output truncated by the model's own token limit fails every pending tool call with a re-issue
  instruction ([pi.md](../research/pi.md) §4).
- Effectful calls journal an intent before running ([fx.md](../research/fx.md) §4).
- Inputs are idempotent by a caller-supplied id and are persisted before processing
  ([unreal-agent.md](../research/unreal-agent.md) §3).
- Crash repair and fork are one operation at different causes
  ([deepseek-harness.md](../research/deepseek-harness.md) §5).

Crash windows are specified rather than implied: the durable barrier before each effect, the
recovery answer for a possibly-run effect (`interrupted`, or rerun where the tool declares itself
replay-safe), torn-tail truncation to the last complete frame, and child-process reaping after a
crash ([fx.md](../research/fx.md) §4, §10; [unreal-agent.md](../research/unreal-agent.md) §6;
[prime-agent.md](../research/prime-agent.md) §9). A fork never inherits in-flight calls without
results; Unreal Agent ships that defect as a live `FIXME` and it is the failure that poisons a
branch permanently ([unreal-agent.md](../research/unreal-agent.md) §12).

**Compaction is a safety stage with a defined trigger**, not a dormant path. The trigger is
proactive at 75% of the window plus a reactive archive when the provider rejects a request
([nooa.md](../research/nooa.md) §3.6); the event region is expected to stay small because tool
bodies spill to handles and standing state lives in the dynamic tail, and it is not bounded by
construction. Every compaction is an appended turn carrying a provenance digest over the compacted
prefix, a retained tail, and carry-forward of every pending call with its latest stub
([arcee-nac.md](../research/arcee-nac.md) §4; [unreal-agent.md](../research/unreal-agent.md) §7).
No-compaction is a measurement arm of the seat, not an invariant it depends on.

## 3. Context: two planes

The process holds whole values. The transcript carries renderings whose size is a property of the
rendering format, and every rendering has a handle to the whole value behind it
([nooa.md](../research/nooa.md) §3.2). Output past its bound spills to a content-addressed file
under the session directory and the model receives preview plus path
([fx.md](../research/fx.md) §3); Unreal's capture files and NAC's `output_id` paging are the two
other recorded variants of the same idea. Serialization to durable form happens at exactly one
boundary, and in Bend2 that boundary is the effect call — values cross as strings, byte lists, or
integers, and a decoded frame is a hand-built tree
([feasibility-bend2.md](feasibility-bend2.md) item 9). Truncation is typed and never silent
([context-networking.md](../research/context-networking.md) §3.2).

Cross-turn residency is stated honestly: what persists across turns is the standing workset and the
spill handles; within-turn bulk lives in program scope; NOOA's cross-turn in-process statefulness
is out of scope because tools and generated programs run under OS confinement, which NOOA's own
limitations section names as trading reference semantics away
([steelman.md](steelman.md) §1 item on residency; [nooa.md](../research/nooa.md) §3.6).

The transcript is three regions: a byte-stable static prefix (framework prompt, tool schemas, seat
charter), an append-only tagged event stream, and a dynamic tail re-evaluated each turn over live
state — the workset, the bound address of the session, and any knowledge slice the orchestrator
attached ([nooa.md](../research/nooa.md) §3.1). The tool catalog is assembled once at seat start and
changes only at turn boundaries, emitted as a `developer/message` delta with a change reason in the
request header, so the prefix invalidation is priced and visible
([deepseek-harness.md](../research/deepseek-harness.md) §10). Decode-time masking of a fixed catalog
is the recorded alternative, and it is vendor-reported and provider-dependent
([no-compaction-approaches.md](../research/no-compaction-approaches.md) §1).

The measured state of the evidence, in full: NOOA reports 82.2% on SWE-bench Verified at
approximately 28 model calls and 1.1M tokens per task, against OpenCode's 78.6% at a similar call
count and roughly 1.3M tokens and PI's 78.2% at 66 calls and 2.2M — all paper-reported, with no
corpus reproduction ([nooa.md](../research/nooa.md) §3.5; [audit-evidence.md](audit-evidence.md)
§"Vendor numbers"). No corpus measurement covers a long-horizon orchestrator seat. Two later
results bear on the posture: in twelve-hour runs the context-managing methods kept improving while
an append-only baseline stopped inside two hours, and that evidence belongs to writable-context and
summarization postures ([context-language-models.md](../research/context-language-models.md) §5,
paper-only); and long-horizon decay tracks per-step reliability more than context shape, with
bounding the window *steepening* decay (logit slope −0.69 against −0.44, p=3e-6, n=10,664)
([research-open-questions.md](research-open-questions.md) §2, arXiv:2609.01660). The second finding
is why §9 gates completion on the verification recipe rather than on transcript state.

## 4. The loop is async-first

A turn may end with work in flight. Pending calls are durable operation records — versioned,
serializable, stable ids, at-most-once semantics ([unreal-agent.md](../research/unreal-agent.md)
§4) — and the transcript holds a fixed stub for each. Completion replaces the stub inside the
uncommitted staging window or appends a second item for the same call id; replacement is the
preferred path where the provider accepts it, and provider acceptance is a milestone-2 entry check
because it is recorded as failing on some non-OpenAI providers
([unreal-agent.md](../research/unreal-agent.md) §12, §13).

The pending-operation state machine is part of the design, not left to the implementation:
states (`pending | running | waiting | completing | terminal`), per-seat and per-operation caps,
deadlines with typed expiry outcomes, a heartbeat rendered as an ordinary user message at a stated
cadence, cancellation semantics including what the transcript records, lost-result semantics for an
operation whose process died, process reaping, and a quiescence definition — completion is the
absence of in-flight entries and unevaluated settles
([deepseek-harness.md](../research/deepseek-harness.md) §4;
[unreal-agent.md](../research/unreal-agent.md) §5; [prime-agent.md](../research/prime-agent.md)
§4, §11.1).

Results commit in batches at turn boundaries: arrived operations and inputs are drained together
under an idle cap with a short grace window so nearly simultaneous completions share one turn, and
commits stay model-ordered through a head-of-line cursor while completion order varies
([unreal-agent.md](../research/unreal-agent.md) §3;
[deepseek-harness.md](../research/deepseek-harness.md) §1.1). The model's join primitive is a
handle: end the turn and the seat sleeps until something lands, then read the tail or the full
output ([prime-agent.md](../research/prime-agent.md) §3). Steering, wakes, stops, and settings
arrive as control inputs in the same single-writer inbox, committed on arrival and delivered at the
next boundary; a steering message does not queue behind a tool call
([unreal-agent.md](../research/unreal-agent.md) §3;
[deepseek-harness.md](../research/deepseek-harness.md) §1.1), with NAC's batch-granularity steering
delay recorded as the boundary of that property ([arcee-nac.md](../research/arcee-nac.md) §2, §10).
Effects keep writer fences: reads overlap freely, the first writer runs alone
([fx.md](../research/fx.md) §4).

A harness-driven speculative mode is part of the design surface: a predicted next call runs in a
copy-on-write sandbox and commits in trajectory order after validation, giving the model-driven and
harness-driven postures a switch to be measured against each other
([research-open-questions.md](research-open-questions.md) §5, citing PASTE arXiv:2603.18897,
TomasuLLM arXiv:2609.38201, Speculative Actions arXiv:2510.04371). Harbor's shipped PASTE flag,
which never fired once in a twelve-of-eighty-nine-to-seventeen-of-eighty-nine regression, is the
recorded caution that a switch without counters is invisible
([research-open-questions.md](research-open-questions.md) §5, arXiv:2604.20938 §V).

## 5. Tools and the program lane

`bash`, `read`, `edit`, and the orchestrator inbox, plus an out-of-process program lane.

Each tool carries its contract as data: name and schema, concurrency class, idempotency and writes
declarations, permission target, result representation, timeout semantics
([fx.md](../research/fx.md) §3). Permission enforcement is executable, not metadata: an OS sandbox
profile, an approval arbiter with a closed outcome set, an authority snapshot captured per turn, the
effect-intent journal, write fences, and nested-call handling
([fx.md](../research/fx.md) §4, §5; [arcee-nac.md](../research/arcee-nac.md) §7). Approvals are
invocation-only and do not create reusable grants
([arcee-nac.md](../research/arcee-nac.md) §7).

The edit tool carries the machinery the ablations price: unique match or refuse, the diff shown
before applying, the preimage captured so undo restores exact bytes
([fx.md](../research/fx.md) §5), and Anthropic's interface discipline — absolute paths, formats
close to text the model has seen, no line-count arithmetic in the format
([minimal-harness-survey.md](../research/minimal-harness-survey.md) Anthropic section).

**The program lane runs out of process**, because Bend2 has no evaluator to call
([feasibility-bend2.md](feasibility-bend2.md) §"Use 3"): the program and its SDK module are written
into a directory under the session directory; `bend <program> <args>` runs the interpreter lane as a
child through the process effect family with stdout and stderr captured into the log; nested tool
calls re-enter the seat over a Base TCP loopback socket carrying the JSON frame codec, so every
effect passes the guarded pipeline and the child holds no authority the seat did not grant
([feasibility-bend2.md](feasibility-bend2.md) item 1). The lane's real constants are part of its
specification: 60-110 ms of process per call, one SDK round trip per nested call, and no type
checking of the generated program (item 7); compiling a program once and reusing the binary is the
measured alternative (3.0 s to C plus 4.2 s to link at the reference's size).

The lane's stated uses include targeted test selection as a first-class case: selecting, generating,
and running a targeted subset is what the recorded twenty-minute-full-suite failure at
twelve-hour scale needs ([research-open-questions.md](research-open-questions.md) §9).

Nothing further is added to the shipped tool set until a measured gap argues for it
([benchmarks.md](../research/benchmarks.md) synthesis; narrow tools measure negative). The seat
extends itself through the paths in §6.

## 6. Self-extension

A seat adds capability through three paths that Bend2 can express, since it has no runtime module
loader ([feasibility-bend2.md](feasibility-bend2.md) item 2):

1. **Declarative tools admitted as data at run time** — name, argument schema, argv template,
   permission target, writes declaration, module digest — executed by a compile-time-checked
   dispatcher `def`, because a table of tool closures cannot be invoked repeatedly and the
   dispatcher must take its subject as a parameter.
2. **Bend2 tools admitted as a repository act**, gated out of process by `bend --check-only`, with
   the tool's contract written as a `law` that must be proved.
3. **C-ABI modules** loaded through `dlopen`, for effects the language cannot express.

Authority is enforced at the runtime boundary, not by types: a user-declared record is forgeable, so
the checker cannot carry capability authority ([feasibility-bend2.md](feasibility-bend2.md) item 3,
item 9). The design therefore states the authority properties it is measured against — process
separation, a structurally-only pre-action path, fail-closed at both levels, and externalized signed
evidence ([research-open-questions.md](research-open-questions.md) §1, arXiv:2606.26057):

- Admission runs orchestrator-side where the grant plane allows it, and where it does not, the
  in-seat path is declared a residual risk with its mitigations named: attenuation-only authority,
  and admission evidence (module digest, admitting principal, approval hash) recorded and signed so
  it is verifiable outside the seat.
- An admitted extension never widens authority; escalation is refused rather than clamped.
- The description the model reads is generated from the same data the executor enforces, so
  description and behavior cannot drift ([deepseek-harness.md](../research/deepseek-harness.md) §4).
- Admission is a logged event, so a resumed seat knows its capability set and nothing about
  capability is ambient.

Admitted extension descriptions are bounded like any other rendering, with fx's catalog figures as
the starting point: the description block is capped at 2% of the window and 1,024 bytes per
description, entries past the cap are refused at admission, and dropped entries are noticed
([fx.md](../research/fx.md) §14).

Self-extension is context economy as much as capability: a minimal surface forces composition, and
repeated composition is what should be compiled. The measured precedent is ALITA-G, where a
harvest–parameterize–deduplicate–select pipeline over successful trajectories reached 83.03% pass@1
on GAIA with roughly 15% token reduction, and CLM's skill evolution, where an evolved procedure took
a held-out task from 38.3 to 74.2 at lower compute behind a Pareto gate
([research-open-questions.md](research-open-questions.md) §3; [context-language-models.md](../research/context-language-models.md) §5).

Promotion follows the destination's existing rule rather than a new one: knowledge records promote
through the orchestrator's admit gate (§8), and capability moves between branches as an orchestrator
artifact adopted by a new admission event on the adopting branch, never as a log merge.

## 7. Fork, branch, and ensemble

The design uses baton2's three mechanisms as they exist
([integration-baton.md](integration-baton.md) §3): provider-session fork with a turn cursor, branch
start with a workspace snapshot and a fresh conversation, and resume of the same conversation.
Fork-and-Flush (arXiv:2610.07447) is the branching method baton2 implements, and its inheritance is
workspace plus complete task inputs plus selected findings plus native configuration with **no log
prefix** (`bend2/src/coordinator/branching-model.bend:13`).

On top of that, this design **proposes an extension to the branch record** — an orchestrator-side
change, stated as such: each branch records a basis digest comprising the harness core version, the
admitted extension set with per-module digests, the tool schema hash, and the model. Loading a
branch compares the basis and **refuses on mismatch** rather than running in a degraded mode.
Today's nearest existing field is the route version tuple carrying a vendor CLI version
([integration-baton.md](integration-baton.md) item 6); the extension-set and schema-hash components
are new, and the mechanism that would produce them does not exist yet.

Three consequences for ensemble work:

- Trajectories carry their capability set, in the spirit of CLM's harness fingerprint in usage
  records, so cross-branch comparison does not confound capability with strategy
  ([context-language-models.md](../research/context-language-models.md) §3).
- Hand-off artifacts follow the three-part record rule: decisions and constraints stored exactly;
  repeated evidence carried as task-justified statistics; raw observations retained only where their
  effect is not reconstructible from the statistics
  ([research-open-questions.md](research-open-questions.md) §7, arXiv:2608.14528).
- Workspace checkpoints are designed with bounded storage and restore tests, so a branch's files and
  its log agree ([minimal-harness-survey.md](../research/minimal-harness-survey.md) Gemini CLI
  section; [arcee-nac.md](../research/arcee-nac.md) §10).

## 8. The orchestrator plane

The seat's hand-off artifacts — a plan, an inventory, an index, a decision record, shaped by the
three-part record rule — commit as cells into its `worker:<seat>` layer, and briefs and reports
carry citations (`repl:<scope>:<name>@<version>`).

Implementation status is stated for each half, because the halves differ
([integration-baton.md](integration-baton.md) §4, §5):

- **Reading is landed on both lines.** `repl.cite` is one version-pinned read returning one binding
  row; the bounded, landed alternative is a cited object rendered into the brief with untrusted
  framing.
- **Writing is not reachable by a seat today.** Manifests and bindings are kernel/embedded
  surfaces on the JS line; the Bend2 line is adding the layer. The seat-side commit path is
  therefore a **named requirement of the Bend2 REPL layer**, tracked with an owner, not an
  assumption: seat context commits as cells at turn boundaries under a declared snapshot schema,
  with the snapshot content convention (what a committed context artifact contains) and the commit
  cadence as open design items.

Dereferencing follows the prior-art record: a version-pinned read that returns the cited
representation, bounded with paged reads beyond it, marking the version in its receipt so a read
issued while the owner is inside a turn is served from the last committed version
([deref-and-consistency.md](../research/deref-and-consistency.md) §2). The grant model is stated in
two layers: the first cross-seat experiment uses one orchestrator-minted read grant scoped to one
citation and one reader, and the full model — attenuation-only derivation with a recorded lineage,
subtree revocation, request-time caveats evaluated at deref time, persistability declared per grant,
and revocation that cuts future reads without retro-invalidating a resolved citation — is the design
target over the grant mechanism that exists (`claimGrant {boardRunId, board}`)
([addressing-and-authority.md](../research/addressing-and-authority.md) §1, §6;
[integration-baton.md](integration-baton.md) item 7). Shared state is an append-only ledger; live
shared mutable context stays closed ([deref-and-consistency.md](../research/deref-and-consistency.md)
§3). Peer content is untrusted input with provenance, sanitized, and cannot carry a self-cited
authority claim.

**Knowledge is the standing store, and it already exists.** Baton runs two: the orchestrator's Cairn
graph — 19 node types, 14 edge types, four groundings, repository-scoped over the append-only
coordination ledger, records minted by orchestrator derivation from settled outcomes and admitted
through one admit gate under a run lease — and a seat-authored SQLite store in the Bend2 line with
four scopes ([integration-knowledge.md](integration-knowledge.md) §1-§2). The seat holds no write
authority over Cairn, reaches it through one bounded, provenance-framed read, and emits evidence
rather than claims: the read rides the dynamic tail rather than the tool catalog, its write path is
the ordinary settlement report, and emission happens at settlement, never per turn, because per-turn
seat writes would multiply fence bumps and collapse the candidate/admit separation (§3-§7). Five
pollution obligations are part of the contract: never write `Contradicts` or `Supersedes`, never
write a claim without a prior-sequence or artifact evidence reference, never write per turn, never
mark recalled content as instruction, and never treat the workset as a knowledge input
([integration-knowledge.md](integration-knowledge.md) items 1, 5, 7).

## 9. Standing state in the seat

Words the model needs to keep in view across turns live on one typed surface: a workset with a goal,
ordered items carrying scope, acceptance, and dependencies, a status, and a verification recipe
([arcee-nac.md](../research/arcee-nac.md) §5), rendered into the dynamic tail each turn. Markdown
notes files are prohibited by the same rule NAC's orchestrator prompt states, and Anthropic's
initializer agent chose JSON for the same reason
([no-compaction-approaches.md](../research/no-compaction-approaches.md) §2).

Two invariants attach to it. The workset commits at the same turn boundary that any bounding or
compaction event consumes, so the durable write precedes the loss event rather than depending on a
prompt nudge ([steelman.md](steelman.md) item 7;
[no-compaction-harnesses.md](../research/no-compaction-harnesses.md) §9). And **completing the
verification recipe is a required step before a completion receipt may be emitted**, with the
recipe's execution recorded in the log — the cheapest response to the finding that per-step
reliability, not context shape, drives long-horizon collapse
([research-open-questions.md](research-open-questions.md) §2, arXiv:2609.01660, arXiv:2609.04298
§3.4).

## 10. Safety and reversibility

Two explicit layers: a sandbox mode controlling what the seat can technically do, enforced by the
operating system with network off by default and repository metadata read-only inside writable
roots, and an approval policy controlling when it must ask
([minimal-harness-survey.md](../research/minimal-harness-survey.md) Codex CLI section). Every
boundary fails closed with a closed outcome union and reports what happened: full or partial
enforcement, named denial reasons, `unavailable` for an answerer that throws
([deepseek-harness.md](../research/deepseek-harness.md) §6). Undo is content-backed: preimages per
mutation, checkpoint-before-mutate for multi-file work, and `unavailable` reported rather than
guessed when a preimage is missing ([fx.md](../research/fx.md) §5).

**No reviewer reads a whole transcript.** Safety reviews, approval decisions, extension admission,
and orchestrator inspection operate over bounded windows with provenance pointers or over checkpoint
digests, because monitor miss rates on dangerous actions rise by 2× to 30× past 800K tokens
([research-open-questions.md](research-open-questions.md) §3, arXiv:2605.12366). This is a
consequence of long-lived, append-only logs and belongs with the safety design rather than with the
instrumentation.

## 11. Deliberate omissions

- No plugin registry or distribution channel; extension happens through §6's three paths, locally or
  orchestrator-mediated ([deepseek-harness.md](../research/deepseek-harness.md) §8).
- No full-screen interface; the event log is the interface
  ([fx.md](../research/fx.md) §7, §15).
- No harness-local knowledge or memory store: Cairn is the standing store, the seat's SQLite store
  belongs to the Bend2 line's own seats, and this harness holds neither (§8;
  [integration-knowledge.md](integration-knowledge.md) §5).
- No subagent spawning, factories, or model-side decomposition; a seat that needs help asks its
  conductor ([prime-agent.md](../research/prime-agent.md) §11.2).
- No ambient caps: task-scoped step, token, and time parameters arrive with the tasking, are
  recorded in the session, and are enforced uniformly; per-call timeouts are properties of individual
  tools ([benchmarks.md](../research/benchmarks.md) concept 5;
  [audit-evidence.md](audit-evidence.md) §5 item 5).
- No stateless execution per action; the async contract requires a live, streaming shell, which in
  Bend2 is a C effect family holding child handles in a table with an event-loop-safe read rather
  than a typed session object ([feasibility-bend2.md](feasibility-bend2.md) item 8;
  [minimal-harness-survey.md](../research/minimal-harness-survey.md) "What does not transfer").

## 12. Instrumentation

Three questions remain unmeasured, and the harness carries the switches to answer them: async
against blocking tool execution (the token half unmeasured; the wall-clock half has adjacent
evidence), the program lane against discrete calls, and citation hand-off against inline transfer.
The switches are the context postures themselves — append-only, projection-bounded, writable-mirror
— plus the speculative mode of §4
([research-open-questions.md](research-open-questions.md) §5, §8;
[minimal-harness-survey.md](../research/minimal-harness-survey.md) Open Interpreter section).

Default emissions: ATIF-style trajectory items including the capability set; per-deref receipts with
cited version, resolved cell id, digest match, bytes delivered, shed markers, and latency; for every
knowledge record consumed, the node id, grounding, validity version served, and the read record id;
provider-counted and estimated tokens kept separate; parse-failure events
([deref-and-consistency.md](../research/deref-and-consistency.md) §4.4;
[integration-knowledge.md](integration-knowledge.md) item 3;
[benchmarks.md](../research/benchmarks.md) Aider section).

**Divergence counters** are part of the instrumentation design: every switchable mechanism logs a
write-side and a consumer-side counter, and a write without a consumer is reported as an invariant
violation, which is how a comparable harness caught two integration bugs invisible to manual
inspection — and how a shipped switch that never fired was discovered
([research-open-questions.md](research-open-questions.md) §6, arXiv:2604.20938 §V).

## 13. Engineering discipline

Primary discipline: codec fixtures, log replay, crash injection, and permission-denial fixtures,
following Unreal Agent's ratio of tests to source
([unreal-agent.md](../research/unreal-agent.md) §6). The protocol state machine is specified and
property-tested, and model-checked with witness configurations that must violate each named
invariant once the machine exists to check
([fx.md](../research/fx.md) §11). Toolchain gates replace the binary-size gates the review rejected
as inherited from a user-facing binary: the pinned toolchain version checked before a build, a
rebuild obligation for every C effect on every toolchain update because the effect ABI carries no
promise, clang-only C output, and the fail-stop conditions that are not `Result` values (allocation
failure, an unbalanced array tree, channel deadlock), which the supervisor must cover because the
run loop has no catch ([feasibility-bend2.md](feasibility-bend2.md) item 6).

The loop-shape constraint is a design input, not an implementation detail: every loop in the seat is
one self-recursive `def` carrying a state sum type, with nested matches inside the arms, `@unsafe`
where an arm keeps waiting without shrinking an argument, one name per binding, and handles threaded
through the loop's state, because two defs cannot call each other and a `match` cannot head a `do`
block ([feasibility-bend2.md](feasibility-bend2.md) item 3).

## 14. Bets

Each states its falsification condition.

1. **Async-first tool execution beats blocking execution.** The wall-clock half has adjacent
   evidence; the token-and-turn half does not
   ([research-open-questions.md](research-open-questions.md) §1, §6). Falsified if turns and tokens
   do not fall on a fixed task set.
2. **The program lane beats discrete calls for batch and targeted-test work.** Settled against the
   lane's real costs (60-110 ms of process per call, one round trip per nested call, no type
   checking) and against the alternative of compiling once and reusing the binary
   ([feasibility-bend2.md](feasibility-bend2.md) item 7). Falsified if the compiled-once path
   matches it.
3. **Citation hand-off beats inline transfer** on token cost and cache stability, with
   replay-exactness holding across seat restarts
   ([context-networking.md](../research/context-networking.md) §5.1). Falsified if commits must be
   frequent to stay useful, or if deref costs make receivers re-derive anyway.
4. **Deliberate commits beat per-turn commits** on receiver cache stability, since every rebind
   bumps the scope fence and invalidates fence-keyed projections
   ([context-networking.md](../research/context-networking.md) §6). Falsified if hand-off value
   decays faster than cache cost accrues.
5. **A graph read ranked by a score that outcomes move beats a fixed-weight ranked read** at the
   same read volume, which is the search-state posture over the knowledge layer. Falsified if the
   fixed-weight read matches it, which is today's state because the weights are constants
   ([integration-knowledge.md](integration-knowledge.md) item 8).

## 15. Phasing

Phasing sequences work; it does not remove mechanisms. Two ordering corrections come from the
review: the cheapest measurements move into early exits, and the orchestrator experiments come after
what they need.

1. Log, loop, four tools, and a headless seat completing a baton2 task; durability effect family;
   codec fixtures, fuzz, crash injection, permission-denial fixtures. Exit criteria include the
   provider-contract check (replacement versus second-item results on the target providers) and the
   projection-bounding measurement against transcript growth.
2. The async operation layer with the pending-operation state machine, quiescence, and loss
   handling. Exit criterion: the async-versus-blocking A/B.
3. The out-of-process program lane with targeted-test selection; the first compile-after-five
   promotion through an evaluation gate.
4. The orchestrator half: cite and deref receipt with a bounded render; then seat-side commit
   admission once the Bend2 REPL layer carries it; then the two-seat commit-and-cite experiment and
   the measurement campaign.

Self-extension, branch capability promotion, and the ensemble machinery are designed here in full
and sequenced as their dependencies land.

## 16. Open questions

- The Bend2 REPL layer's landing surface: what a seat-side commit call will accept, and whether the
  snapshot content convention belongs to the layer or to the harness.
- Where extension admission runs: orchestrator-side, or in-seat with signed evidence as the
  compensating control.
- Whether the knowledge read is evented or served from cache, who authors a seat-side record and
  with what evidence, and the growth boundary for a graph the design intends to be permanent.
- Whether the Bend2 law-file drift recorded in the knowledge audit (schema law, promotion arity,
  missing evidence predicate) compiles.
- Commit cadence for hand-off artifacts, and its interaction with receiver cache stability.
- The deref representation bound for a first cross-seat read, given that no corpus system bounds a
  cross-session read ([deref-and-consistency.md](../research/deref-and-consistency.md) §5).
- Whether a cross-scope dereference needs a defined snapshot, or every networked read names exactly
  one binding version ([addressing-and-authority.md](../research/addressing-and-authority.md) §6).
- Whether generated programs should be type-checked at admission (`bend --check-only` on the
  generated program), given that the interpreter lane does not check them.
