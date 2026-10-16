# Revised proposed design text for design-sketch.md (design-lead, round 1)

Concrete replacement text, in the sketch's own voice, for the sections the evaluation found
unreproducible, unsupported, or in conflict with the operator requirements. Each block is followed
by a one-line reason. Unchanged sections are not repeated. Citations are to the canonical source
`SRC` = `/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/source`
at `b1f006a6`, and to the pinned corpus `CLI:` = the baton-cli checkout at `5941316491`.

## §1 What it is

**Replace** the first two sentences with:

> One native Bend2 binary that runs one seat. The seat is a native harness process: the `baton2`
> coordinator launches it through the session's stored endpoint argv, whose tail is
> `receive SESSION HARNESS MODEL EFFORT CWD LOG MESSAGE_ID`, and the agent inside the turn calls
> back through the coordinator's CLI — `baton2 DATABASE {inbox, read, report, ask, send, guide,
> finish, confirm, acknowledge}` (`SRC:docs/bend2/architecture.md:25`,
> `SRC:bend2/src/coordinator/main.bend:44`). There is no wire protocol: the seat is driven, not
> connected to. Registration is a named coordinator change: the coordinator admits native turns
> only for Codex, OMP, Muse and Claude Code (`SRC:bend2/src/coordinator/control.bend:125,198,281`;
> `SRC:bend2/src/coordinator/delivery.bend:20`), so the seat either matches one of those four
> adapter protocols (`SRC:bend2/src/harness/*-player.bend`) or the repository adds a
> `harness/bend2-player.bend` adapter and extends the three admission sets and settlement
> (`SRC:bend2/src/coordinator/message-status.bend`). That decision is milestone 1.

**Add** to the goal:

> Every seat receives the coordinator's per-attempt initialization seed unchanged: the coordinator
> generates `lower(hex(randomblob(64)))`, reuses it across fresh and profile retries, and prepends
> the seed and its fixed instruction to the seat's guidance
> (`SRC:bend2/src/coordinator/native-initial-input.bend:10-21`). The seat treats the seed as an
> opaque initialization identifier and never reseeds.

**Add**, on commands: the seat adds no new command syntax; its verbs are concise action verbs, and
each new coordinator verb is one.

*Reason: the sketch's "existing CLI protocol (baton2)" describes neither the CLI nor a protocol,
and omits the closed harness set that decides whether the seat can be driven at all.*

## §2 The session log

**Replace** the commit-discipline sentence:

> Appends are in place with `O_APPEND` (`File.open(path,"a")`,
> `SRC:toolchain-home/bend2/effs/file_open.c`) plus `fsync(file)` per commit through an authored C
> effect; the directory is synced only when the file is created, replaced, or rotated; temp-file
> plus `rename` is reserved for rotation and compaction. A `flock(LOCK_EX|LOCK_NB)` gives the
> single-writer discipline the reference coordinator already uses: the `SessionLock` effect is
> declared in `SRC:bend2/src/host/session-lock.bend` and its C half lives in
> `SRC:bend2/src/host/process-spawn.c` (`flock(LOCK_EX|LOCK_NB)` at `:2438` and `:5096`; the
> database lock is `sqlite.c:881`). Frames past a few hundred kilobytes use `List<U32>` bytes
> through `File.read_bytes`/`write_bytes`, because `String` is a linked list of characters. Base
> ships no `File.sync`, `File.rename` or `File.stat`; the six-signature durability effect family is
> a required host layer, not a convenience.

**Replace** the compaction sentence:

> Compaction is a required context policy, not a dormant emergency path: projection budgets for
> every tool result, explicit overflow handles, a live headroom estimate, and a reclaim operation
> that carries forward pending calls with their latest stubs. The reclaim trigger is a boundary —
> proactive at 75% of the window and reactive on provider rejection — and append-only
> never-compaction is the measurement arm it is compared against.

*Reason: one commit discipline for the whole log rewrites the log per append; and the corpus's
recorded long-horizon result contradicts an append-only default.*

## §4 The loop is async-first

**Add** an operation-observation discipline before async is admitted, written to the operator's
constraint that no runtime step, token or time quota, and no arbitrary ceiling, controls admission,
continuation or unfinished work:

> States are an *observed* lifecycle, not a gate: `pending, running, settled, failed, cancelled,
> completed`, plus `unknown` for a result that has not arrived while the operation remains owned and
> running. `lost` is entered only on concrete lifecycle evidence — a provider or OS rejection, a
> disconnect with provenance, a child process exit — because elapsed silence alone cannot establish
> that a result will never arrive; silence stays `unknown` with the operation still owned.
> Baton requires no duration, token or step estimate to admit, pause, stop, truncate or gate
> unfinished work, and installs no such budget. Work may end or be interrupted in exactly four ways,
> and none of them is a Baton runtime cap: (1) an actual provider or OS rejection, a disconnect, a
> process exit, or an externally enforced limit, retained with its provenance and with the
> operation's unfinished state; (2) an explicit authorized cancellation — the model for its own
> operations, the Conductor for the seat (`stop`/`force-stop` already ship:
> `SRC:bend2/src/coordinator/commands.bend:594-609`); (3) an observation wait that returns while the
> operation stays owned and running, so the wait is bounded and the work is not
> (`docs/research/prime-agent.md:45`, `collect(timeout_ms)`, which limits the wait and does not stop
> the child); (4) finite benchmark measurement conditions, which are instrument properties rather
> than seat runtime caps (`CLI:docs/design/research-open-questions.md:194-212`). A heartbeat is
> informational only: it never terminates, parks or gates the work it reports on
> (`docs/research/unreal-agent.md:46` keeps pending calls alive and heartbeats them).
> Quiescence, not "turn ended", is the completion contract: the session is open while an operation
> is in flight and closes when nothing is. Child process groups are recorded and reaped.
>
> Task-scoped step, token and time parameters arriving with tasking are recorded in the log and
> reported as ledger fact, never required as an estimate and never enforced as a gate. A
> policy-driven park on a provider quota outcome is rejected: the outcome is retained evidence and a
> Conductor decision, and the seat never parks or caps itself.

**Add**, as a milestone-2 entry gate: the provider contract — whether the target provider accepts a
replacement or a second item for the same call id — is checked before the operation layer is built.

*Reason: one never-settling operation otherwise holds the session open, and the "primary path"
result form is provider-dependent and unmeasured.*

## §5 Tools and the program lane

**Replace** the program-lane paragraph:

> Generated Bend2 programs run out of process. The program and a byte-stable SDK module are written
> under the session directory; `bend <program> <args>` runs as a child through the process family
> with its stdout and stderr captured into the log; nested tool calls re-enter the seat over a
> loopback socket, so tool calls made through the lane pass the guarded pipeline and are logged and
> attributable. There is no in-process evaluator (`bend --help` lists no `repl`, `eval`,
> `test`, `debug` or `fmt`) and no compiled-in type check of the generated program. Per-call cost is
> a platform property and is measured on the deployment platform before the lane is judged against
> discrete calls.

*Reason: Bend2 has no evaluator to call; the lane's cost constant is darwin-specific.*

**Replace** the authority sentence. Socket re-entry is a transport and a routing discipline; it does
not by itself deny a same-UID child filesystem or process access:

> The child is an ordinary same-UID process. Socket re-entry is a routing convention, not an
> authority boundary: the child retains full ambient OS authority — filesystem, process spawn, raw
> network — for anything it does outside the SDK, and only effects the program expresses through
> the SDK are mediated, logged and attributable. Base ships no sandbox effect
> (`SRC:toolchain-home/bend2/effs/`, verified at 2.0.25), so the real boundary is OS confinement
> the seat must establish before spawning: on Linux, rootless namespaces plus seccomp (for example
> bubblewrap); on macOS, `sandbox-exec`; network off except the loopback path; explicit writable
> roots with repository metadata read-only. That confinement is **untested on the pinned
> toolchain** — no probe has run a confined Bend2 child — and the design must state plainly that
> until it lands the child inherits the seat's OS authority. The discriminating probe is: from
> inside a spawned child, attempt a direct write outside the writable roots and a direct process
> spawn, and record what the OS, not the protocol, denies.

## §6 Self-extension

**Replace** the loading sentence and the safety bullets' authority claim:

> A tool enters one of three ways, and none is a runtime module load: (a) declarative tools admitted
> as data — name, argument schema, argv template, permission target, writes declaration, module
> digest — executed by a compile-time-checked dispatcher def whose subject is a parameter; (b)
> repository-level Bend2 tools admitted as a repository act, gated out of process by
> `bend --check-only` / `--checkup`, with the contract written as a `law` that must be proved; (c)
> optional C-ABI modules via `dlopen`, carrying no checker verdict. Authority is enforced at the
> effect boundary and by the operating system, because a user-declared Bend2 record is forgeable
> and no type establishes provenance. Admission of durable capability is the orchestrator's act, not
> the seat's; the model proposes, an admission outside the seat's own address space installs, and the
> admission record carries a digest, the admitting principal, and the authorizing approval.

*Reason: no runtime module loader exists; the checker cannot carry authority; and a model-callable
in-seat admission fails the process-separation and structurally-only-path properties of the
machine-checked authorization formalism.*

## §7 Fork, branch, and ensemble

**Replace** the fork record:

> The coordinator's branching record already carries the workspace snapshot, the complete task
> inputs, the selected findings, the native configuration and an evaluator command
> (`SRC:bend2/src/coordinator/branching-model.bend:13` fixes the *schema*; the *behavioural*
> inheritance is `SRC:bend2/src/coordinator/branching.bend:64-73`, `input_snapshot`,
> `knowledge_snapshot` and `round_task`, described in `SRC:docs/bend2/branching-ensembles.md` as
> Fork-and-Flush), and each candidate starts a fresh native
> conversation over that snapshot. It carries no log prefix and no harness-state vector. The
> extension this design proposes — a capability-set digest and a typed basis check at load — is a
> proposal over that record, with one rule made explicit: a fork happens only at a completed turn
> boundary after pending operations are settled or cancelled, and a basis mismatch refuses the load
> rather than running degraded.

*Reason: no operation copies a log prefix; the triple is a proposal, and degraded load has no
compatibility table.*

## §8 The orchestrator plane

**Replace** the opening with a dependency statement:

> The commit-and-cite plane does not exist on the target line yet. At the pinned source the Bend2
> tree has no REPL, cell, binding, citation or deref-grant mechanism, and the JavaScript
> implementation that has one was retired from this repository on 2026-10-02 (commit `2b8449af`,
> "Use the native coordinator source and contributor entry points"), so it is not present at HEAD
> at all and is reproducible only at its own revision `1e050e42`. Commit-and-cite therefore ships
> in the reachable order: first the orchestrator-side, version-pinned read — a citation that
> resolves to exactly one binding version, a bounded render into the brief with untrusted framing,
> and a per-read receipt minted as its own rows, since a message receipt is recipient-owned and
> turn-scoped and cannot be reused — and only then seat-side commit admission, if and when the
> separate REPL lane (#778) lands that substrate. Grants, caveats, attenuation trees, fences and
> persistability stay named proposals, not mechanism. The `context/` subsystem's "cells" are JSON
> array cells of a managed-query codec and are never cited as this substrate.

*Reason: the substrate is absent on the target line; the audit's "JS line only" is itself a claim
about a revision not under review, and a message receipt is not a deref receipt.*

**Replace** the knowledge and quotas bullets:

> No harness-local memory service: the standing store is the coordinator's own knowledge store
> (`SRC:bend2/src/coordinator/knowledge.bend`), which the seat reaches with `baton2 knowledge` and
> which is read by the CLI, the MCP adapter and the Orchestra browser. The seat emits at settlement
> — its report and evidence references — never per turn, and it never writes `Contradicts` or
> `Supersedes`.
>
> No runtime step, token or time quota, and no arbitrary ceiling, controls admission, continuation
> or unfinished work. Task-scoped step, token and time parameters arriving with tasking are
> recorded and reported; they do not terminate, park or gate-keep the seat's work, and a
> task-scoped budget used that way remains a conflict. No duration, token or step estimate is
> required to admit, pause, stop, truncate or gate work, and no Baton runtime cap is installed:
> work ends through an actual provider or OS rejection, disconnect, process exit or externally
> enforced limit (retained with provenance and unfinished state), through an explicit authorized
> cancellation, or because a bounded observation wait returns while the operation stays owned and
> running. Silence is not evidence of loss; the operation stays `unknown` and owned until concrete
> lifecycle evidence says otherwise. None of this introduces a gating layer.

## §12–§13 Instrumentation and discipline
Keep the async-versus-blocking and citation-versus-inline switches; add silent-flag auto-exclusion
(a mechanism that logs no consumer is reported as an invariant violation). Keep codec fixtures,
fuzz, replay, crash injection and permission-denial fixtures in milestone 1; move model checking
after the protocol state machine exists; replace "binary size and startup latency gated in CI" with
a coordinator-spawn smoke budget.

*Reason: the corpus's instrumentation lessons and the steelman's sequencing fix.*

## §14–§15 Bets and milestones

Resequence so evidence precedes architecture: the provider-contract check and the
projection-bounding A/B are exit criteria of milestones 1-2; the async A/B exits milestone 2; the
program lane and the first compile-after-five exits milestone 3; commit-and-cite E1 exits
milestone 4, with Harbor-Index and LOCA-bench named. The fork triple, degraded load, grant caveats,
the TLA+ gate and the size gates leave milestone 1.

*Reason: the load-bearing measured number is earned by a mechanism the confined seat does not
implement, and the two novel mechanisms are the unmeasured ones.*

## Accepted corrections from failure-evaluation's independent round (append; root integrates)

Each is a further amendment, verified or re-runnable at the pin. None introduces a gating layer.

**§2 — crash repair is two mechanisms, not one.** Add: a torn tail on load truncates to the last
complete frame and emits a typed `log.repaired` event; this is distinct from the foreign-writer
latch (`SessionWriterChanged`), which stays a refusal. Add the resumed-effect trio: an intent
barrier, declared idempotency class per tool, and typed *possibly-run* answers on resume, so a crash
between effect and commit never silently re-runs a completed effect and never silently refuses the
session. (Source: failure-evaluation S1, S2; the sketch has the intent journal but neither the repair
nor the possibly-run answers.)

**§4 — name the wait mechanism.** Base has no deadline-bounded wait: `Chan.recv` takes no timeout and
there is no select or race, only `IO.sleep` and `IO.now`. The batched drain and the join handle
therefore specify their mechanism explicitly — sleep-poll over the durable pending table, or a new C
wait effect family — because "idle cap with a short grace window" as written presumes a timer-select
the language does not have. This is a mechanism choice, not a budget: it never gates unfinished work.
(Source: failure-evaluation P5.)

**§5/§6 — admitted tools execute by content address.** A digest over a declaration pins the
declaration, not the bytes; a declarative tool whose argv names an artifact inside the seat-writable
workspace can be admitted once and execute different bytes later. Admitted artifacts are copied to a
content-addressed path and executed from there, or re-digested at spawn with a typed
refusal-on-change recorded in the log. (Source: failure-evaluation S4.)

**§9 — the workset and spill reads get valves.** Workset mutations pass a schema valve carrying
provenance, and spill-handle reads are byte-capped with a receipt, because the workset is re-rendered
into the dynamic tail every turn and is therefore the highest-salience injection channel in the
design. (Source: failure-evaluation S5.)

**§11 — the standing store needs lineage hardening and a GATE PREREQUISITE.** The shipped seat
knowledge store rewrites relation lineage on a caller-supplied id
(`SRC:bend2/src/coordinator/knowledge.bend:288`, `ON CONFLICT(id) DO UPDATE SET author=excluded.author,…`,
with `SRC:bend2/src/coordinator/agent-native.bend:215` preserving the caller's id), which violates
operator requirement 6 for the store §11 designates. The fix class is small: immutable relation ids,
or author-namespaced ids at ingest, or a conflict guard like the one findings already have. The
design must not depend on that store until the fix lands. Separately, milestone 1 carries a
prerequisite: every `*-laws.bend` in the tree compiles under `--check-only`, because the pinned tree
is red today (`bend bend2/src/coordinator/knowledge-laws.bend --check-only` exits 1). (Source:
failure-evaluation S6, P1; I re-ran the check and read both SQL sites.)

**Contested, not adopted:** a persisted deadline per operation class that auto-marks `lost` and
closes the attempt, and a deadline on the head-of-line commit cursor. Both are failure-evaluation's
S7.2/S7.5 and correction 5; both place a duration in control of unfinished work, which the operator
ruling forbids. The quiescence concern they address is kept: a never-settling operation stays
observable (`unknown`, owned, heartbeated) and is reported to the Conductor, who owns the decision.
