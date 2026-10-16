# Design sketch: baton-cli

Status: proposed seat design. The seat is unimplemented. The research corpus and earlier
[audit-findings.md](audit-findings.md) describe the designs and source revisions they examined.
This sketch distinguishes current source contracts, proposed interfaces, diagnostic observations,
and paper-reported results. Implementation dependencies preserve the full design scope.

The target is **Baton**, using its native Bend2 coordinator. Current-source statements here refer
to `b1f006a6308bbb00e29a24322e4f7d5164774470` and its recorded Baton fork of Bend 2.0.25. Release
installation and live acceptance require their own evidence. Historical JavaScript mechanisms are
reference material at `1e050e420a99d775d3d2f943453c23535a701fd9`; that revision's `impl/` tree was
removed from the native line in `2b8449af`. Baton's required product scope includes the compiler
and a persistent Bend2 REPL. The REPL accepts Bend2 source only. The coordinator/REPL lane owns
its interface and context substrate; the proposed seat's commit-and-cite interface depends on
that work.

## 1. Seat and coordinator

The proposed seat is a native Bend2 binary. It receives complete tasking, runs model turns and
tools, appends session history, reports through Baton, and exchanges versioned context through the
interface in §8. Baton stores complete task and guidance text in its database.

At the reviewed source, the native receiver accepts `baton2 DATABASE receive SESSION HARNESS MODEL
EFFORT CWD LOG MESSAGE_ID` through stored endpoint argv. Admission and settlement recognize Codex,
OMP, Muse, and Claude Code. Integrating a Bend2 seat requires a correctly identified adapter plus
the corresponding admission, receiver, wake, and settlement changes. The coordinator lane owns
that integration, including per-harness prompt delivery, frame classification, and settlement
(`bend2/src/coordinator/control.bend`, `control-laws.bend`, `delivery.bend`, `turn.bend`, `message-status.bend`,
and `bend2/src/harness/*-player.bend`). Existing endpoint details are internal adapter contracts. The change also covers configuration,
blocked-state and delivery-sweep predicates, direct-turn support, and the launch dispatcher. The
reviewed dispatcher's final branch launches Claude Code; a Bend2 adapter needs an explicit branch
and a test that unsupported identities refuse before launch. The affected law expectations require
matching changes.

Agent-facing commands use concise action verbs with inferred session and action context: `inbox`,
`read`, `report`, `ask`, `send`, `guide`, and `finish`. Complete owned reads receive automatic
handling on the corresponding successful native settlement. Baton preserves the first handling
receipt. Task completion is a request followed by Conductor confirmation. The coordinator resolves
message and action identities; agents provide task text and decisions through these commands.
Dispatch admission validates immediate parent–child routes in either direction, Conductor-to-
descendant routes, explicit tight Ensemble peers, and operator–top-level-Conductor routes before
storing input or waking its recipient (`bend2/src/coordinator/commands.bend`, `message_route`).

Every agent initialization receives the coordinator's generated random string and fixed
instruction. The instruction requests brief ideation on the string's abstract qualities and use
of those qualities in interpreting the task, together with its explicit requirements and evidence.
This applies to all initialized agent sessions. At the reviewed source,
`lower(hex(randomblob(64)))` produces a 128-character hexadecimal string. Baton retains the seed,
instruction, and actual guidance under the native execution identity; associated retries reuse
their recorded seed (`bend2/src/coordinator/native-initial-input.bend`). Interpretive stances remain
permitted. Performance and sampling reproducibility require separate measurement.

The source-size figures in [feasibility-bend2.md](feasibility-bend2.md) describe its foreign KIT
snapshot. Source scope, artifact sizes, startup cost, and required C effects will be measured for
the actual seat. The reviewed toolchain requires authored host effects for process management,
durability, TLS, HTTP, and JSON; existing Baton effects are reuse candidates with contracts to check.

## 2. Session log and recovery

The proposed log is append-only JSONL with a versioned header and contiguous sequence numbers.
Records include inputs, turns, model responses, tool-call status, operation intents, observations,
and branch lineage. Append and load both validate framing and sequence. A committed tool status
records the operations it awaits ([unreal-agent.md](../research/unreal-agent.md) §6).

The durability effect family provides:

- `O_APPEND` writes and `fsync(file)` at each declared durable commit.
- Directory sync after creation, replacement, and rotation.
- Temp-file replacement for rotation and derived context projections.
- A single-writer lock and a typed refusal when the committed writer position has changed.
- Byte-oriented reads and writes for large frames, using the pinned effect ABI.

The feasibility continuation demonstrates write, file sync, rename, directory sync, and stat
through authored C effects on the pinned Linux toolchain in native and interpreted runs. Its P03
probe ends with exit 2 when it unlinks the already-renamed temporary path; it retains the committed
file and the actual status. P03 exercises whole-file publication. Append-mode writes with per-commit
file sync, the single-writer lock, and the seat's crash-window durability and recovery contract
remain to be implemented and tested. Base signatures and reused effects need their own contract
checks ([feasibility-bend2.md](feasibility-bend2.md) item 4;
[fx.md](../research/fx.md) §10). `String` uses linked characters at the reviewed toolchain, so frame
representation is an implementation and allocation choice. Base read offsets and sizes use U32;
the C `File.size` effect returns `EOVERFLOW` above `UINT32_MAX`. A log using these interfaces needs
segment rotation or an authored wider-offset effect. These representation limits create no work
or runtime budget.

Log and operation invariants are specified separately:

- Each turn records its actual completion or interruption reason. Operation state survives a turn
  ending while work continues.
- Each tool result retains its call identity and provider-required ordering across replay and
  context projection ([pi.md](../research/pi.md) §7; [arcee-nac.md](../research/arcee-nac.md) §4).
- An incomplete model-emitted call records its parse or provider failure. Calls already admitted
  retain their observed state and ownership. A truncated response never authorizes blind reissue.
- Each effectful call commits an intent before execution. The operation retains the tool's
  idempotency class and the actual attempt identity ([fx.md](../research/fx.md) §4).
- Inputs are persisted before dispatch and deduplicated under coordinator- or provider-resolved
  identities. Native tasking retains the complete text.
- Crash repair resumes the original execution lineage. A branch records a new lineage and an
  explicit inherited snapshot (§7). The two paths may reuse log validation routines.

Recovery distinguishes an unstarted intent, an observed running operation, a retained result, and
an effect whose outcome is unknown. An intent record alone cannot establish whether an external
effect ran. Recovery queries the original process or provider where possible and retains exact
uncertainty otherwise. Re-execution requires the tool's actual idempotency mechanism or an
authorized decision with duplicate-effect implications recorded. Replay must exercise the crash
window between an external effect and the result commit.

A torn final frame is preserved as diagnostic evidence, repaired to the last complete frame, and
reported by a typed repair event. A writer-position violation retains the original log and refuses
further conflicting writes. Recovery reattaches to observable owned children and reaps confirmed
exited children. Observer restart, silence, and connection loss provide no authority to terminate
unfinished work ([fx.md](../research/fx.md) §4, §10;
[prime-agent.md](../research/prime-agent.md) §9).

Context compaction appends a derived projection with its source digest, retained tail, pending
operations, and workset version. Complete original records and spill contents remain recoverable.
The implementation chooses a trigger from the provider's actual context capacity, request shape,
and measured headroom. Provider context refusals retain their exact outcomes and recovery state.
NOOA's reported 75% trigger is a source-specific policy ([nooa.md](../research/nooa.md) §3.6).
Append-only context, projection bounding, and writable context are experimental configurations (§12).

## 3. Context representations

The runtime holds complete values and renders declared projections for the model. Each projection
identifies its complete retained value and records any omitted bytes. Large values spill under the
session directory with content identity and paging support
([nooa.md](../research/nooa.md) §3.2; [fx.md](../research/fx.md) §3).

Serialization follows the actual host-effect boundary: strings, byte lists, and integers at the
pinned ABI, with decoding into explicit data structures
([feasibility-bend2.md](feasibility-bend2.md) item 9). A durable value's encoding is versioned and
round-trip checked. Projection limits describe delivered context; complete values remain readable. Local spill reads
declare their byte projection and retain a complete value handle, page position, and delivered- and
omitted-byte receipts. Provenance records the source class, including peer input, tool output, and
model-authored content.

The initial seat preserves a typed workset, operation records, and spill references across turns.
Generated-program values live in that program's process. The seat may later store cross-turn
values in the required persistent Bend2 REPL through an explicit storage and recovery contract
(§8). In-process object
identity, durable serialization, and process confinement are separate properties. The initial
program lane specifies durable serialization and an executor policy independently; each needs its
own implementation evidence.

Requests have a stable framework prefix and tool schemas, a tagged event projection, and a dynamic
tail containing the current workset, session address, pending work, and attached knowledge.
Catalog changes occur at turn boundaries and record their reasons and observed cache effects
([deepseek-harness.md](../research/deepseek-harness.md) §10). Provider-specific schema masking is a
separate comparison ([no-compaction-approaches.md](../research/no-compaction-approaches.md) §1).

[NOOA v1](https://arxiv.org/html/2607.20709v1) reports GPT-5.5 xhigh on SWE-bench Verified: 82.2%
at about 28 calls and 1.1M tokens per task, OpenCode 78.6% at a similar call count and about 1.3M
tokens, and PI 78.2% at 66 calls and 2.2M tokens. These paper-reported configurations provide
comparators for the experiment; the proposed seat has no corresponding measurement.

[Context Language Models v1](https://arxiv.org/html/2609.37725v1), Figure 27, reports continuing
improvement over twelve hours for context-managing methods; the append-only baseline stopped
improving within roughly two hours. That result covers writable-context and summarization
configurations. [The reliability study v1](https://arxiv.org/pdf/2609.01660v1) reports cumulative
step failures and worse decay under a compressed-context regime that also deletes prior reasoning.
Its reported decay slopes are per horizon doubling. The proposed tests measure context effects
and outcome reliability under their own task and model conditions.

## 4. Async operations

A turn may return while its operations continue. Each durable operation records its internal
identity, version, owner, native process or provider identity, intent, observed state, partial
output, and complete result reference. Dispatch deduplication and tool-specific idempotency are
separate contracts. Actual external-effect guarantees depend on the executor and recovery evidence.

The transcript carries a status projection for each pending call. Within an unsubmitted staging
window the seat may update that projection. Once submitted, the provider adapter emits accepted
continuation items with the original call identity. Replacement and repeated-item forms require
provider-specific acceptance checks ([unreal-agent.md](../research/unreal-agent.md) §12–§13).

Observation and lifecycle remain distinct. A wait may return while the underlying operation stays
owned and running. Provider or OS refusals, disconnects, process exits, and externally enforced
limits retain exact errors and provenance. Their lifecycle implications depend on actual protocol
and settlement evidence. Silence or a disconnected observer alone leaves the outcome unknown.
Explicit cancellation comes from an actor authorized for the affected work. The proposed seat's
completion report includes pending operation identities, observed states, ages, and retained result
references. At the reviewed coordinator, a completion request carries its authored body; native
reconciliation separately projects pending counts and the oldest pending message identity. The
seat's per-operation pending-state report requires an implemented mechanism. Ages inform the
Conductor's decision.

Baton requires no duration, token, or step estimate and enforces no such budget on admission,
continuation, pause, truncation, stop, or unfinished work. Tasking may carry recorded measurement
parameters. Heartbeats and age observations report state. A never-settled operation remains
visible to its owner and Conductor until actual settlement or authorized cancellation resolves it.

The implementation names its wake and wait mechanism. The tested Base `Chan.recv` signature has
no timeout, and the reviewed inventory exposes no built-in select or race. The probe establishes
that signature and its observed blocking behavior. A concrete event effect or observation-polling
composition must be specified and tested. The TCP probe receives peer close as an empty string;
`None{}` represents timeout. A socket observation loop needs an explicit EOF transition. A bounded
observation wait preserves the operation.
Arriving results persist immediately under their operation identity. The head-of-line cursor
orders provider-visible items; durable observations and result handles remain available while an
earlier call is pending. Adapter checks establish which observations the model can receive during
that wait. A provider requiring all call results before continuation has a recorded blocking
restriction. The cursor has no elapsed-time closure rule.

Steering, wakes, stops, and settings enter the single-writer input path and are delivered at their
valid control boundaries. Record the actual control latency for each adapter. Reads may overlap;
mutations run under their selected physical write guards. These controls and result handles retain
their complete provenance ([prime-agent.md](../research/prime-agent.md) §3, §9;
[unreal-agent.md](../research/unreal-agent.md) §3, §5).

The design also includes harness-driven speculation: predicted calls execute in isolated working
state, and externally visible effects require validation and their actual commit mechanism.
Compare this with blocking and model-driven async execution. [PASTE v1](https://arxiv.org/html/2603.18897v1)
reports up to 48.5% lower average completion time; [v2](https://arxiv.org/html/2603.18897v2) and
[v3](https://arxiv.org/html/2603.18897v3) report up to 43.5%. These are serving-layer results with named
baselines. [TomasuLLM v2](https://arxiv.org/html/2609.38201v2) reports lower single-session latency
with additional drafter tokens and compute. Section 5.4 reports a coarse cost proxy of about 2.1
seconds of speculative compute per wall-clock second saved. This measured additional cost is an
adverse prior for the proposed seat; its transfer to this design remains unmeasured. The paper's
configured maximum chain depth is six, its measured chains commit at most four candidates, and its
separate depth sweep estimates speedup by replay. [Speculative Actions v1](https://arxiv.org/html/2510.04371v1)
reports its largest latency improvement in chess. The seat's token and turn costs remain unmeasured.

Mechanism telemetry records both admission and consumption. [Harbor v1](https://arxiv.org/html/2604.20938v1)
reports enabled mechanisms with zero execution counters and distinguishes smoke runs too short to
reach a mechanism's trigger. Section 12 makes that distinction explicit in this proposal's experiments.

## 5. Tools and generated programs

The initial tools are `bash`, `read`, `edit`, and the coordinator inbox, plus a generated-program
execution path. Tools declare their schema, concurrency class, idempotency mechanism, writes,
permission target, result representation, observation semantics, and cancellation behavior
([fx.md](../research/fx.md) §3).

Actual enforcement consists of the selected OS executor policy, authorized approval outcomes,
effect-intent journal, captured authority, and write guards. Existing session authorization applies
to subsequent actions within its scope. Nested SDK calls preserve their parent and pass through
the same applicable checks. Each result states the enforcement and authority actually used
([fx.md](../research/fx.md) §4–§5; [arcee-nac.md](../research/arcee-nac.md) §7).

The edit tool accepts an exact unique match or reports ambiguity, captures the preimage, and
records the resulting diff. Undo uses the retained original bytes. Its interface uses absolute
paths and familiar text formats ([fx.md](../research/fx.md) §5;
[minimal-harness-survey.md](../research/minimal-harness-survey.md), Anthropic section).

The initial generated-program path runs Bend2 out of process. The seat writes the program and a
versioned SDK under its session directory, starts `bend <program> <args>` through authored process
effects, and captures complete stdout, stderr, and status. SDK calls use a local codec endpoint and
retain parent attribution. The reviewed upstream CLI supplies no embedded evaluator contract;
the seat's later persistent evaluator depends on the required Baton Bend2 REPL interface
([feasibility-bend2.md](feasibility-bend2.md), Use 3).

A same-UID child inherits ambient filesystem, process, and network authority available to that
user. Routing SDK calls through a socket mediates those calls. Confinement requires actual OS
mechanisms around direct child effects. No confined Bend2-child probe was executed in this review.
The proposed tests exercise direct writes, process launches, and network access against the
executor's declared authority and retain the OS outcomes. They include a child attempting a direct
write to the session log and an unrelated same-UID process attempting an SDK request. The protocol
must demonstrate its caller identity and replay behavior. Exact process credentials and a nonce are
options to evaluate. Captured process output and sanctioned SDK calls retain attribution; direct
ambient effects require their own observation evidence. SDK framing, terminator handling, result
encoding, and authentication require explicit protocol tests.

The original 60–110 ms invocation and 3.0 s C-generation plus 4.2 s linking figures are Darwin
observations for named programs. Distinct Linux trivial-program probes reported 0.33–0.39 s;
runtime-lead observed 0.544 s interpretation and 0.642 s checking in separate runs. The deployment
comparison measures actual program sizes, SDK round trips, interpreted
execution, compile-once reuse, and concurrent load. The feasibility worker's P11 diagnostic reports
0.353 s checking, 0.420 s C emission, 0.855 s linking, 0.032 s native startup and execution, and
0.409 s interpretation for its trivial dispatcher. The retained full-coordinator build at the
reviewed source records 2101.119 s C emission and 142,651,376 KiB maximum RSS, with opt-in compiler
diagnostics enabled. These single-run observations establish their own source, configuration, and
host costs; a promoted program needs its own size and reuse measurement.

The interpreter checks before running and reports reliance on unsafe or foreign definitions.
Admission records the applicable checker result, including `--check-only` where that is the chosen
gate. The JS-hosted loader also checks and can call exported non-IO Bend2 definitions, returning
JS-projected values. P10 demonstrates that interface in a Bun host. This loader is an execution
backend; the REPL accepts Bend2 source only. A typed seat result-codec
contract remains untested. Relative to the native seat, the host is a separate process whose
authority, startup cost, and SDK interaction still need evaluation.

Targeted test selection is one use of this path: generate or select relevant tests, execute them,
and retain the selection basis and coverage limits ([research-open-questions.md](research-open-questions.md)
§9). Additional tools require a task-supported gap and comparative evidence. Section 6 defines the
extension paths.

## 6. Extension admission

The design includes three extension paths:

1. Declarative tools admitted as data: name, schema, argv template, permission target, writes,
   declaration digest, and artifact identity. A statically checked dispatcher executes the
   declaration using the pinned compiler's parameter-subject convention. Constructor names share
   a global namespace at the reviewed compiler; declarations admitted as data avoid adding new
   constructors to that namespace.
2. Bend2 tools admitted through repository changes, with `bend --check-only` and the relevant
   contract laws checked under the pinned toolchain. The path requires passing laws for the contract it uses;
   features relying on the knowledge contract require the corresponding repaired law evidence.
3. Trusted native C-ABI modules loaded through `dlopen` for authored effects. Such code runs with
   the loader process's authority. It needs a separate process boundary to receive confinement
   beyond that process's own restrictions.

The particular affine-reuse probe refused a duplicated argument. That result constrains the
tested dispatcher example; other representations require their own source and compiler evidence
([feasibility-bend2.md](feasibility-bend2.md) item 2).

The model proposes an extension. An authorized orchestrator admission records the principal,
existing authority or approval, declaration digest, artifact identity, and applicable execution
policy. A user-constructed record establishes data shape; authority provenance requires an actual
admission and enforcement path. An in-process admission alternative must name the actor controlling
its policy and its remaining ambient authority.

Executed bytes must match admitted bytes. The proposed executor uses protected content-addressed
storage or verifies bytes at the execution boundary with a demonstrated race-free binding to the
executed object. An fd-based design must protect the checked object against concurrent mutation
and demonstrate the actual execution path, including interpreter behavior. A digest check followed
by a pathname execution still needs race protection. A content-derived path or declaration digest
alone leaves that binding unresolved.
Authored C effects also need the actual string ABI: `io_cstr` appends a NUL while its returned
length excludes that terminator. Effect tests include multi-string packing and the exact bytes
passed across the boundary. Artifact changes require the corresponding authorized admission. The displayed contract is derived
from the actual executor data and version; changes remain auditable across recovery.

[Unfireable Safety Kernel v1](https://arxiv.org/html/2606.26057v1) describes process separation,
pre-action enforcement, fail-closed decisions, and external evidence as individually insufficient
necessary properties within its model. Its machine-checked result covers a particular pure
decision function; signing and evidence integration are tested separately. This seat requires its
own enforcement evidence.

Descriptions have declared renderings and handles to complete contracts. Rendering records omitted
bytes while keeping full schemas readable. These context bounds preserve admitted work and
capability records.

Repeated compositions are candidates for measured reuse. [ALITA-G v1](https://arxiv.org/html/2510.23601v1)
preserves implementation diversity and reports 83.03% GAIA validation pass@1 for its 3×
configuration with roughly 15.5% fewer tokens than its original Alita baseline. Its harvesting and
evaluation conditions limit transfer. [Context Language Models v1](https://arxiv.org/html/2609.37725v1)
reports KVStore 38.3→74.2 with a Qwen3.6-27B agent and Claude Fable 5.1 proposer. These are
paper-reported outcomes; candidate promotion here needs local comparative evidence.

Current knowledge promotion uses destination-owner pull through Baton's scoped SQLite API.
Cross-branch capability adoption is a separate authorized admission. Original attempts, receipts,
and unselected artifacts keep their lineage.

## 7. Fork, branch, and ensemble

The reviewed coordinator distinguishes provider-specific conversation fork, a workspace branch
with a fresh conversation, and continuation of an existing native conversation. Adapter support
and inheritance differ by mechanism ([integration-baton.md](integration-baton.md) §3).

For branching ensembles, the source records a settled workspace snapshot, complete task inputs,
selected knowledge, native configuration, and evaluator provenance. `branching-model.bend` defines
the record; `branching.bend` constructs the input and knowledge snapshots. Candidates receive fresh
native conversations over separate workspace copies. Evaluation records scores and acceptance;
selection retains its reason and candidate evidence, then continues the selected conversation.
Loose or tight coordination defines how candidates exchange guidance during the round
(`docs/bend2/branching-ensembles.md` at the source pin).

[Fork-and-Flush v1](https://arxiv.org/html/2610.07447v1) supplies research precedent for workspace
inheritance with fresh chat. Its finite-horizon experiments are evidence about those runs. Baton
retains the snapshot, native tasking, and selection contracts above. Experimental horizons add no
runtime duration, token, or step control to this design.

This design proposes an additional branch basis: seat version, model configuration, admitted
extension artifacts and digests, and schema version. At new branch admission, incompatible basis
data produces a typed refusal and retains the original snapshot. A versioned migration requires
an explicit compatible contract. Existing owned work remains governed by its recorded execution.
The current route version tuple is separate from this proposed extension-set basis.

A snapshot is taken at a boundary with its included effects settled. Pending work stays with its
original owner; any required cancellation is explicit and authorized. Each branch records the
capabilities that affect interpretation of its score. Checkpoints have restore tests establishing
agreement between files, inputs, and log provenance.

Handoff projections carry exact decisions and constraints, task-justified summaries or statistics,
and source references. Complete original observations remain retained independently of that
projection. [The handover analysis v1](https://arxiv.org/html/2608.14528v1) motivates this structure
under conditional statistical assumptions; arbitrary adaptive agent trajectories need their own
validation. Storage and archival policy preserve the ability to resolve cited evidence.

## 8. Versioned context and knowledge

The proposed cross-seat artifacts include plans, inventories, indexes, and decisions under declared
versioned schemas. Reports cite exact committed versions. At the reviewed Bend source, a seat REPL
cell, binding, commit, and dereference-grant interface remains unimplemented. The separate Bend2
REPL and context work owns that substrate. Historical JavaScript contracts and JSON-array cells in
the native managed-query codec are separately identified mechanisms. The managed-query admission
store already retains immutable bootstrap content, artifact digests, and ownership witnesses. Reuse
requires checking that contract against the proposed named cells, versions, leases, and read receipts.

A proposed read identifies one immutable version, supports a declared preview and complete paged
reads, frames peer content as untrusted data, and records provenance, delivered bytes, and version.
This requires its own read evidence. Native message handling receipts describe their actual owned
reads and successful settlement; cross-seat context reads have a distinct contract.

A proposed context commit records the complete artifact, schema, owner, and version at an explicit
boundary. The implementation must specify atomicity, snapshot content, authority, cadence, and
recovery. The first experiment can use an orchestrator-issued permission for one reader and cited
version. Grant lineage, attenuation, caveats, revocation, persistence, and OS enforcement remain
named design requirements. The historical `claimGrant {boardRunId, board}` record supplies reference
material about its own version. The [seL4 manual 9.0.1](https://sel4.systems/Info/Docs/seL4-manual-9.0.1.pdf)
sections 3.1.5 and 3.2 provide a comparison for derivation lineage and revocation of derived
capabilities. [Macaroons (NDSS 2014)](https://research.google/pubs/macaroons-cookies-with-contextual-caveats-for-decentralized-authorization-in-the-cloud/)
provide a credential-attenuation and contextual-caveat comparison. These mechanisms establish
requirements to evaluate for Baton grants; the proposed Baton interface requires its own evidence.

The current standing knowledge store is Baton's authored SQLite store. Its scoped CLI, MCP, and
browser readers and destination-owner promotion have source consumers at the reviewed pin.
Knowledge consumption through those readers requires an explicit pull. The native task prompt
includes knowledge instructions; automatic knowledge-briefing composition remains proposed.
Historical Cairn kinds, grounding rules, candidate admission, and read-path findings apply to
their own source revision ([integration-knowledge.md](integration-knowledge.md)).

The reviewed relation upsert permits lineage replacement on a caller-supplied relation ID;
`agent-native.bend` preserves that ID. The failure evaluator reproduced the SQL behavior in
isolated SQLite. [Baton issue 785](https://github.com/Flip-Engineering/baton/issues/785) separately
records a production-binary public coordinator reproduction at the reviewed source: a sibling
replaces the original relation and becomes its author, while changed finding content refuses with
`finding-id-conflict`. That issue retains its own command and artifact provenance. Relation
protection remains proposed; candidate conflict contracts preserve identical retries and refuse
changed authorship or content, with ownership and namespace alternatives evaluated explicitly. Lineage-sensitive features require the actual immutable or ownership-checked
contract before claiming preserved authorship. Original records and failure evidence are retained.

The proposed seat emits settlement reports with evidence references and reads recalled content as
data. Its workset records task progress. Knowledge admission separately determines whether a
claim and relation have adequate evidence and authority. The proposal's restriction on a seat
authoring `Contradicts` or `Supersedes` is an admission-policy choice requiring its own mechanism;
the current API already accepts authored knowledge. Growth, archive, retrieval, and provenance
policies need evaluation against the actual target store.

## 9. Standing workset

A typed workset carries the goal, scoped items, acceptance conditions, dependencies, status, and
verification recipe. Its declared projection appears in the dynamic tail each turn
([arcee-nac.md](../research/arcee-nac.md) §5). Baton owns complete task text and control identity;
the workset and spill records use program-managed storage.

Workset updates validate schema and preserve the provenance and source class of their content,
including peer messages, tool outputs, and model authorship. A context
projection names the durable workset version it consumed and preserves all pending control and
operation references. Compaction retains the complete original evidence (§2).

Before requesting task completion, the seat records the verification recipe's actual execution,
results, and material limitations. The Conductor evaluates that evidence and confirms completion
under the task's acceptance conditions. Automatic handling of successfully consumed native messages
is a separate coordinator responsibility (§1). Failed verification retains the work and findings
for correction or an authorized scope decision.

## 10. Authority, review, and undo

The executor uses an explicit authority profile defining filesystem, process, and network access.
Its approval policy determines which actions require a new authorized decision; prior session
authorization remains applicable. The implementation identifies the exact OS mechanisms and their
tested coverage. Each boundary reports denial, unavailable enforcement, or the enforcement actually
provided. An unavailable required boundary refuses the affected new action while preserving owned
work and evidence ([deepseek-harness.md](../research/deepseek-harness.md) §6).

Undo restores captured preimages. Multi-file changes use a checkpoint with an executable restore
contract. Missing original bytes produce an explicit unavailable result
([fx.md](../research/fx.md) §5). Same-UID ambient authority and native-module execution retain the
limits stated in §5–§6.

Review projections identify their complete retained transcript. [The monitor study v1](https://arxiv.org/html/2605.12366v1)
tests incremental monitoring of transcript prefixes ending at tool calls and reports failures
under long benign prefixes. A chosen fixed-size reviewer window needs its own measurement of
misses, false positives, distributed attacks, and omitted context. Complete evidence remains
available for source review and replay.

## 11. Runtime interfaces and ownership

- Extension execution uses the three paths in §6, with their actual admission and authority.
- The primary interface is the CLI and structured event log, with complete readable artifacts.
- The Conductor owns delegation and integrates requests for additional seats. The seat reports
  needed help through the coordinator.
- Standing knowledge uses the scoped coordinator API. Proposed admission and grant interfaces
  are owned in §8.
- A live process supervisor holds actual child handles and provides streaming observation through
  authored effects. Its process table, restart binding, and result custody implement the operation
  contract (§4; [feasibility-bend2.md](feasibility-bend2.md) item 8).
- Native control, actual outcomes, and authorized decisions govern unfinished work as specified in
  §4. Experimental measurement conditions remain attached to their reports.

## 12. Experiments and instrumentation

Experiments compare blocking, model-driven async, and harness-driven speculation; generated
programs and discrete calls; and citation handoff and inline transfer. Context configurations
include append-only input, bounded projections, and writable context. Each comparison holds named
inputs and source versions fixed or explicitly records the difference.

Trajectory records include capabilities, operation lifecycle, and actual outcomes. Context read
evidence includes the cited version, digest, bytes delivered, omitted-byte markers, and latency.
Consumed knowledge retains its source record, version, evidence, and read identity. Parsing errors
and provider refusals retain complete provenance. Provider-counted and estimated usage are reported
separately ([deref-and-consistency.md](../research/deref-and-consistency.md) §4.4;
[benchmarks.md](../research/benchmarks.md), Aider section).

Reports state source, toolchain, provider/model/effort, allocation, trial count, pairing, uncertainty,
actual tokens, wall time, and compute where observable. Each comparison states the smallest paired
effect its suite can resolve at the reported power and statistical assumptions. Initialization seeds retain the required
instruction (§1); recording a seed alone establishes no provider-sampling determinism. Finite
measurement conditions describe observed runs and create no runtime task budget. Observation
boundaries preserve live owned work. Reports identify right-censored outcomes and apply the same
observation conditions to each comparison arm.

The async comparison separates result batching from asynchrony with a declared batching sweep or
one-result-per-turn replay arm. It reports per-operation commit latency, reordering, and steering
and control latency. Each arm records the provider's accepted continuation form and any blocking
restriction.

Each switchable mechanism records admission, activation, and consumption. An inactive path is
reported as unexercised. For an operation whose declared contract requires eventual consumption,
an actual settled attempt with a missing consumer is a failure requiring investigation. In-flight
work keeps its pending status. This permits integration diagnosis without treating every zero
counter or elapsed wait as a failure ([Harbor v1](https://arxiv.org/html/2604.20938v1)).

## 13. Validation and toolchain

Validation covers codecs, replay, crash injection, authority denial, undo, and operation continuity
([unreal-agent.md](../research/unreal-agent.md) §6). The state-machine specification names each
invariant and an example that violates it. Property checks and model checking apply to the
implemented machine with their actual assumptions and explored state space
([fx.md](../research/fx.md) §11).

Builds record the exact compiler and authored C effects. The recorded baton741–baton776 compiler
fork and its full-coordinator build carry `qualification: false`; they are diagnostic evidence.
Release qualification remains separate work tracked in [Baton PR 772](https://github.com/Flip-Engineering/baton/pull/772). Toolchain changes require recompilation
and ABI validation for those effects. Clang output and fail-stop behavior require supervisor
tests: allocation failure, malformed array structure, and blocked channels have different outcomes
from returned `Result` failures ([feasibility-bend2.md](feasibility-bend2.md) item 6).

Compiler guidance comes from the actual pin. The reviewed JSON header requires matching a
parameter or constructor field, dependency declarations before callers with self-recursive loops,
and Data-only constructor fields. Modality and affine duplication follow the relevant compiler
rules. The observed `knowledge-laws.bend` check failed at its first compiler error. Additional
missing helpers and arity drift were source findings. Repair and execution of that law remain
named target work; a failing unrelated law is not an automatic prerequisite for every seat feature.

## 14. Hypotheses

Comparisons state quality and uncertainty alongside resource effects. Each component claim is
evaluated independently.

| Hypothesis | Comparison and falsification |
| --- | --- |
| Async execution lowers latency and may reduce turns or tokens. | Compare blocking and async on the same tasks and quality criteria. Each claimed resource improvement fails when the comparison does not support it. |
| Generated programs improve batch and targeted-test execution. | Compare discrete calls, repeated interpretation, and compile-once reuse across chain lengths, fan-out, model capability, and atomic calls. Reject an advantage unsupported at matched quality and actual cost. |
| Citation handoff lowers transfer cost while preserving exact recovery. | Compare inline transfer and receiver re-derivation with versioned reads, including commit cadence and cache effects. Reject the claimed advantage if stale or costly handoff removes the benefit or recovery changes the cited value. |
| Deliberate context commits improve receiver cache stability. | Compare commit cadences and the validity of the information delivered. Reject the claim if measured cache effects and handoff usefulness fail to support it. |
| Outcome-updated graph ranking improves retrieval. | Compare fixed-weight and outcome-updated ranking on the actual target graph at equal read volume and declared retrieval quality. Reject the claim if the fixed-weight comparison matches it within the measured uncertainty. |

Candidate/admission graph semantics, outcome-updated ranking, and cross-seat grant behavior remain
implementation dependencies. Historical Cairn weights describe its own revision. Context and
reliability experiments retain separate controls ([research-open-questions.md](research-open-questions.md)).

## 15. Implementation dependencies

Independent lanes can proceed concurrently. Integration depends on the contracts each lane uses;
the complete scope includes extensions, branch capability adoption, ensembles, and commit-and-cite.

| Lane | Required dependencies | Evidence produced |
| --- | --- | --- |
| Native seat and durable log | Correct harness identity; receiver and settlement integration; log and host-effect contracts. | Headless task completion; codec, crash, restore, and native input-handling results. |
| Provider and context behavior | Actual target adapter, provider acceptance, durable values and projections. | Replacement/continuation compatibility; context growth, projection, and cache measurements. |
| Async operations | Durable intent, native identity, observation, cancellation authority, and result custody. | Blocking/async comparison; live-work continuity and uncertain-effect recovery cases. |
| Generated programs and extensions | Process executor, SDK attribution, actual authority policy, and artifact identity. | Discrete/interpreted/compiled comparisons; direct-child authority and admitted-byte tests; promotion evidence. |
| Branch integration | Settled snapshot, complete inherited tasking, evaluator provenance, and basis contract. | Fresh-conversation inheritance, selection, continuation, restore, and capability-adoption evidence. |
| Versioned context and knowledge | Actual Bend2 REPL/context interface, exact-version reads, own read evidence, and required lineage contract. | Initial two-seat citation read; seat commit admission; commit-and-cite and retrieval comparisons. |

These are dependency and acceptance statements. Diagnostic observations and proposed experiments
remain separately reported until executed. Follow-up issues track [native seat integration](https://github.com/Flip-Engineering/baton-cli/issues/2),
[uncertain tool-effect recovery](https://github.com/Flip-Engineering/baton-cli/issues/3), and
[admitted artifact execution](https://github.com/Flip-Engineering/baton-cli/issues/4).

## 16. Open engineering decisions

- The Bend2 adapter and its exact receiver, control, and settlement integration.
- Provider result-continuation forms, wake implementation, and evidence for recovering external
  effects with uncertain outcomes.
- Context projection triggers, complete-log storage and archive policy, and restore guarantees.
- The persistent Bend2 REPL's value, commit, snapshot, and read-permission contracts.
- Extension admission placement, trusted native-module authority, and atomic binding of admitted
  bytes to executed bytes.
- Repair of the publicly reproduced relation lineage replacement, plus the intended
  knowledge-law contract and its actual compiler result.
- Knowledge provenance admission, evented or cached reads, graph growth, and retrieval evaluation.
- Context commit cadence, exact-version read representation, snapshot consistency, and revocation.
- Generated-program checking at admission and its measured cost relative to reuse.
