# Integration audit: the baton-side surface the sketch assumes

Verdict: the sketch's "baton2 protocol for tasking, messages, receipts, wakes" describes no single
system — two orchestrators exist in one repository, with different seats, tasking paths and wake
paths, and only one has the REPL/citation layer §8 depends on. Verdict: the §7 fork triple
contradicts both mechanisms baton calls fork and the branching method baton already implements,
which inherits the workspace and deliberately discards the conversation. Verdict: §8's cells,
bindings, citations and fences are landed, its grants are not, and no external seat can reach the
commit half.

Citation convention: a bare path is in `/Users/wahargis/Development/Experiments/baton` at HEAD
`1e050e420a99d775d3d2f943453c23535a701fd9` (2026-09-22, the line the research corpus cites). A
path prefixed `baton2:` is in the Bend2 line at
`/Users/wahargis/Development/Experiments/baton-postrelease-751-761-20261015`, commit `10c2ae6d`
(2026-10-16), the freshest checkout of that line. `[INFERENCE]` marks a deduction from a cited
mechanism rather than a statement found in it.

## 1. Two orchestrators

| | baton (`archive/javascript`) | baton2 (`bend2-rewrite`) |
|---|---|---|
| Source | `impl/src/*.mjs` (Node) | `baton2:bend2/src/**` (Bend2 plus C bindings) |
| Entry | CLI, `baton serve` resident, MCP bridge | `baton2 DATABASE COMMAND ARGS` (`baton2:docs/bend2/architecture.md:25-30`) |
| Seat protocol | swarm bridge over loopback HTTP, plus MCP | native `receive` endpoints, plus `baton2_action`/`baton2_ack` MCP for one harness |
| REPL cells/citations | landed (`docs/33`) | absent |

The Bend2 checkout carries no `impl/` tree (verified: no `impl/` directory in the `10c2ae6d`
worktree). The MCP surface (`impl/MCP.md`), the REPL layer (`docs/33`), `claimGrant` and the swarm
native bridge exist only on the JavaScript line. The sketch's §1 names the protocol `baton2` while
§8 names `worker:<seat>` layers and `repl:<scope>:<name>@<version>` citations; those facts come
from different lines and do not co-occur today.

`bend2/src` contains no `repl` token except an unrelated knowledge relation string
(`baton2:bend2/src/coordinator/knowledge.bend:186`, `'citation:'||id`). Its `bend2/src/context/`
subsystem is a managed-query/retention engine (`baton2:docs/bend2/semantic-context-spec.md`,
`baton2:bend2/src/context/service.bend:103-168`) in which `cell` means a JSON array cell
(`baton2:bend2/src/context/operations.bend:180`). A Bend2 seat expecting the sketch's REPL layer on
the other end of the wire has no other end.

## 2. The seat protocol as it exists

### 2.1 Who owns the seat

Both orchestrators own the seat's process and drive a native harness conversation. Neither exposes
a task queue a harness client polls.

- baton2: the session row holds a delivery endpoint (argv array); the process committing a report,
  question or message invokes it with the message ID and `receive` launches the harness
  (`baton2:docs/bend2/architecture.md:184-194`, `:266-287`). Supported harnesses are Claude Code,
  Codex, OMP and Muse (`baton2:docs/bend2/architecture.md:146-151`).
- baton: the adapter set is closed — `CLI_ADAPTERS = {codex, claude, zcode, glm, pi, muse}`
  (`impl/src/cli-adapters.mjs:878`) — each rendering the brief through
  `renderBrief(brief, CLI_PROMPT_DIALECT)` (`impl/src/cli-adapters.mjs:117`), with dispatch
  carrying `session: {mode: new|resume|fork, id, lastTurnId}` (`impl/src/mcp-northbound.mjs:624`).

`[INFERENCE]` A Bend2 binary is not a baton seat: `CLI_ADAPTERS` has no registration path and
`adapter-contract.mjs` validates cards for a fixed tier (`impl/src/adapter-contract.mjs:1-26`).

### 2.2 Tasking

- baton2: `baton dispatch "task text"` / `--stdin` / `--file PATH` owns complete task input,
  stores it in `direct_turn_requests`, and wakes the recipient through the ordinary message
  operation (`baton2:docs/bend2/agent-commands.md:207-217`,
  `baton2:docs/bend2/architecture.md:134-137`); the retained attempt seals the rendered native
  input as `ATTEMPT/prompt.txt` (`baton2:docs/bend2/architecture.md:211-217`).
- baton: `swarm.recruit` takes `objective`, `options`, `permissions`, `mode`, `resumeFrom`,
  `workId`, `autoWake` (`impl/src/swarm-contract.mjs:298-303`); `_composeRecruitBrief` composes the
  brief (`impl/src/swarm-runtime.mjs:6861`) and `renderBrief` renders it into the harness prompt
  (`impl/src/cli-adapters.mjs:110-119`).

Tasking reaches a seat as a composed prompt string in both systems. It is not something a seat
pulls.

### 2.3 Messages and receipts

- baton2: `messages` stores caller-supplied unique IDs, sender, recipient, kind, full body and an
  optional native acceptance receipt (`baton2:docs/bend2/architecture.md:67`). Seat verbs are
  `baton inbox`, `report`, `ask`, `send PLAYER TEXT`, `guide PLAYER TEXT`, `read ID...`,
  `acknowledge`/`ack` (`baton2:docs/bend2/agent-commands.md:7-36`). Receipts derive from
  recipient-owned complete reads of the current turn and preserve their first stored value
  (`baton2:docs/bend2/architecture.md:86-91`); a successful completed turn creates the first
  receipt automatically while failed turns and unread input stay pending
  (`baton2:docs/bend2/agent-commands.md:17-20`).
- baton: `swarm.guide` is the in-swarm authority channel and `swarm.notify` the peer channel
  (`impl/src/swarm-contract.mjs:309-330`); `swarm.notifications` is the receipt read, with row
  shape `delivered / read / actedOn / reply / replies` beside swarm provenance
  (`impl/src/swarm-contract.mjs:332-337`). The run-layer spelling is
  `baton_run_message_receipt` (`docs/49-mcp-primary-surface.md:472`).

### 2.4 Completion

- baton2: `baton finish 'body'` is a completion request to the recorded parent
  (`baton2:docs/bend2/agent-commands.md:67-84`); the coordinator answers `confirm PLAYER`, and
  `completion-confirmed --request ID --to PLAYER` selects an exact retained request. A parentless
  session gets a structured refusal.
- baton: completion is the turn boundary plus the trust gate, not a seat verb. The coordinator
  launches the gate at every provider turn end (`docs/35-turn-checkpoints.md:13-15`, citing
  `coordinator.mjs:9901-9913`); a `pausable`-carded turn end mints `turn.paused` with steering
  acts `nudge`, `wait`, `claim` (`docs/35-turn-checkpoints.md:25-35`, `:60-70`), and
  `steering.registered` is landed (`impl/src/application-observation.mjs:173`).

### 2.5 Wakes

- baton2 has no seat-side wake subscription. Each Conductor harness has one wake path: the
  endpoint in its session row, invoked with the message ID
  (`baton2:docs/bend2/architecture.md:266-287`). OMP receives mid-turn guidance as native `steer`
  frames (`baton2:docs/bend2/architecture.md:175-182`); a Claude Code Conductor receives
  `notifications/claude/channel` and calls `baton2_ack` (`baton2:docs/bend2/architecture.md:289-311`);
  a retained OMP child's question reaches its parent as a `question` message with a native request
  ID (`baton2:docs/bend2/native-interactions.md:1-23`).
- baton has the wake plane the sketch describes, and it is landed rather than proposed. The class
  table is `WAKE_CLASS_TABLE` (`impl/src/wake-stream.mjs:120`), the delivery method
  `notifications/baton/wake` (`impl/src/mcp-northbound.mjs:932`), the tool family `baton_wakes
  {subscribe, since, unsubscribe}` (`impl/MCP.md:159`). Both mechanisms `docs/54-native-wake.md`
  presents as design are in code: the `## Recent wake events` brief block
  (`impl/src/swarm-runtime.mjs:7059-7106`) with its limit row `brief.wake_events.items`
  (`impl/src/limits.mjs:369`), and `autoWake` declared on `swarm.recruit`
  (`impl/src/swarm-contract.mjs:298-303`), carried into the bridge environment
  (`impl/src/swarm-native-bridge.mjs:93`, `:573-616`), published by `SwarmNativeAccess.prepare`
  (`impl/src/swarm-native-access.mjs:18-24`). The `Status: proposed` header at
  `docs/54-native-wake.md:3` is stale.

### 2.6 What an external seat must implement

baton (JavaScript line): a seat invokes its own bridge client and implements no protocol.

- Transport is loopback HTTP on 127.0.0.1 with an ephemeral port and a bearer token in the
  `Authorization` header, chosen so native agents can use it "through curl or the module's own node
  CLI entry" (`impl/src/swarm-native-bridge.mjs:24-29`). The client entry is
  `node swarm-native-bridge.mjs <swarm.command> [jsonArgs]`, reading `BATON_SWARM_BRIDGE_URL` and
  `BATON_SWARM_BRIDGE_TOKEN` (`impl/src/swarm-native-bridge.mjs:46-50`); the other environment keys
  are named at `:93` and `:134`, including `BATON_SWARM_BRIDGE_AUTOWAKE`.
- The callable set is closed and brief-rendered: `SWARM_SEAT_VERB_NAMES` is the knowledge verbs plus
  three seat reads (`impl/src/swarm-native-access.mjs:89-94`). The reads are `run.package.read`,
  `run.contributions.read`, `run.peers.read`, each `permission: 'read'` with identity field `runId`
  (`impl/src/swarm-runtime.mjs:1260-1294`).
- The seat publishes with `swarm.update {event: 'swarm.contribution_recorded', payload: {body}}`,
  and "ending a turn without publishing leaves the work unreachable"
  (`impl/src/swarm-native-access.mjs:102-103`). `swarm.capture` and `swarm.check` are root-only
  (`impl/src/swarm-native-access.mjs:103`). Token scope is `{swarmId, participantId, runId}`;
  identity is minted from the token table, never from the request body
  (`impl/src/swarm-native-bridge.mjs:4-12`).

baton2: the seat is the native harness; its commands are
`baton2 <db> {inbox, report, ask, send, guide, finish, confirm, ...}`
(`baton2:docs/bend2/agent-commands.md:7-15`), plus `baton2_action` and `baton2_ack`
(`baton2:docs/bend2/agent-commands.md:144-149`, `baton2:docs/bend2/architecture.md:291-301`). No
HTTP/JSON protocol exists on that line.

### 2.7 Minimum obligations

- baton2: read the pending input and acknowledge it, since a failed turn retains unacknowledged
  input (`baton2:docs/bend2/architecture.md:203-209`); report or ask through the recorded parent
  (`baton2:docs/bend2/architecture.md:167-170`); send a completion request and accept the
  coordinator's confirm (`baton2:docs/bend2/agent-commands.md:67-84`); one active attempt per
  logical session under an OS file lock (`baton2:docs/bend2/architecture.md:138-144`).
- baton: publish a contribution before the turn ends (`impl/src/swarm-native-access.mjs:103`);
  treat every refusal as durable and visible to the orchestrator, since it is reported to the
  runtime refusal lane and shows as `lastRefusal`
  (`impl/src/swarm-native-bridge.mjs:13-20`); read from the record the brief names, keyed by
  `packageDigest` and `since` seq (`impl/src/swarm-native-access.mjs:86`).

## 3. Fork, flush, branch, ensemble

### 3.1 Three mechanisms are called fork

1. Native session fork (baton). Dispatch takes `session: {mode: new|resume|fork, id, lastTurnId}`
   (`impl/src/mcp-northbound.mjs:624`), with `lastTurnId` admitted only for `fork`
   (`impl/src/mcp-northbound.mjs:1699-1700`, `impl/src/runtime-recovery.mjs:379-387`). It maps to
   Codex `thread/fork` (`impl/src/codex-appserver.mjs:902`) and Claude `--fork-session`
   (`impl/src/claude-session.mjs:470`). What it carries is the provider's own conversation plus a
   turn cursor.
2. Branch start (baton2). A round snapshots the source workspace into a private Git index, creates
   one worktree per child at that snapshot, and starts a fresh native conversation in each
   (`baton2:docs/bend2/branching-ensembles.md:46-58`).
3. Crash repair and continuation. Neither system forks a log. baton2 resumes the same recorded
   native conversation under the same ID (`baton2:docs/bend2/architecture.md:234-241`, `:365-370`);
   baton admits `resume` on the same session (`impl/src/runtime-recovery.mjs:379-387`). No
   operation copies a log prefix into a new continuation.

### 3.2 Flush

`flush` names two transports, neither of them a context operation: `stream.omp.flush` is a
4096-byte coalescing chunk for OMP streams (`impl/src/limits.mjs:166`, read at
`impl/src/omp-rpc.mjs:40`), and `_flushLedgerSync` syncs a pending group-commit before a lease
release or checkpoint (`impl/src/coordination-ledger-writes.mjs:560-578`,
`impl/src/coordination-ledger.mjs:1119`). In Fork-and-Flush flush means discarding the chat context
while keeping the workspace (`arXiv:2610.07447` abstract); that sense is realized in baton2 as the
fresh conversation of §3.1(2), and no baton operation is named `flush`.

### 3.3 The branching ensemble method is Fork-and-Flush, workspace-only

`baton2:docs/bend2/branching-ensembles.md:100-104` names the paper. The round is one row,
`branch_rounds`, with columns exactly: `id, ensemble, owner, source, ancestor, workspace,
branch_count, snapshot, task, inputs, knowledge, includes, evaluator, direction, harness, model,
effort, command` (`baton2:bend2/src/coordinator/branching-model.bend:13`), plus
`branch_candidates(round, ordinal, session, workspace, branch)` (`:14`), `branch_evaluations` and
`branch_selections` (`:16-17`). Each boundary records the source Player, workspace snapshot,
complete task inputs, selected findings, native configuration and evaluator command
(`baton2:docs/bend2/branching-ensembles.md:3-7`). Selection requires settled custody, no explicit
stop, one accepted evaluation and one unique best score (`:70-77`); continue dispatches guidance
into the selected conversation and workspace (`:82-84`); `ancestor` chains rounds (`:35-38`).

"Ensemble" carries three distinct meanings here, and the sketch's §7 uses none precisely: the
baton2 team record `ensembles`/`ensemble_members`/`sections` with loose or tight coupling
(`baton2:docs/bend2/architecture.md:69-73`, `baton2:docs/bend2/terminology.md:47-56`); the baton2
branching ensemble above; and baton's own design corpus, which used "ensemble" for cross-vendor
best-of-N and revised it away as wrong-engine, since pass@N is a repeated-sampling effect within
one vendor (`docs/13-revision-log-r2.md:44-46`).

### 3.4 Does anything record a harness-state version?

Partially, and not what the sketch needs. A vendor harness version is recorded and load-bearing in
route identity: `routeTupleKey` folds `card.version` (`impl/src/route-tuple.mjs:1-5`), parsed back
as `{harness, version, model, effort, modelFamily, taskType}` (`:21-27`), with concrete values
`codex` `0.144.0` (`impl/src/cli-adapters.mjs:602`) and `claude-code` `2.1.206` (`:664`), and the
deployment projects a public harness version (`impl/src/application-deployment.mjs:1999`). Nothing
records admitted capabilities, extension digests, module versions or a tool-schema hash: no
extension or admission mechanism exists, the adapter set is closed
(`impl/src/cli-adapters.mjs:878`), and the card axes are `governance`, `modelSelection`,
`permissions`, `workerPolicy`, `verbs` (`impl/src/adapter-contract.mjs:65-126`). The nearest
content-addressed identities a branch could compare are the REPL manifest digest, basis kind
`baton.repl_manifest` (`docs/33:50-56`), and the worker-session `authorityDigest` over
`{kind: 'authenticated-worker-session', principalId, sessionId}` (`impl/src/application.mjs:349-353`).

### 3.5 The sketch's fork triple against baton

| Sketch component | baton today | Verdict |
|---|---|---|
| log prefix | no operation copies a log; recovery resumes the same conversation (`baton2:docs/bend2/architecture.md:365-370`) | conflicts |
| harness-state version vector | no extension or admission record exists; only the route version tuple (`impl/src/route-tuple.mjs:1-5`) | no counterpart |
| workspace checkpoint | baton2 `snapshot` in `branch_rounds` (`baton2:bend2/src/coordinator/branching-model.bend:13`); baton worktrees (`impl/src/worktree.mjs`) | matches in shape, different owner |
| basis digest | baton2 checks source custody and evaluator output, not a digest over the fork's own basis (`baton2:docs/bend2/branching-ensembles.md:46-53`) | no counterpart |

The sketch's fork is a fourth mechanism: a context-carrying continuation fork. Fork-and-Flush
exists to avoid exactly that, and baton2 implements the paper.

## 4. The REPL layer

| Item | Landed? | Exact form | Reachable by an external seat |
|---|---|---|---|
| cells | yes | `cell:<sha256>` (`impl/src/coordination-admission.mjs:106`), content-addressed JSON to 64 MB (`docs/33:23-25`) | indirectly, as the object a citation resolves |
| manifests | yes | `ReplManifest`, digest basis `baton.repl_manifest`, `{runId, replRole}`, `replRole ∈ {shared, worker:<id>}` (`docs/33:50-56`); admission event `repl.manifest_admitted` (`:57-62`) | no: `repl.manifest` is `profile: 'kernel'`, `surfaces: ['embedded']` (`impl/src/application-semantics.mjs:1608-1614`) |
| bindings | yes | `(scope, name) → cell:<sha256>`, immutable-versioned, `repl.binding_set`/`_dropped` (`docs/33:77-81`); `admitReplBinding` validates scope and cell id (`impl/src/coordination-admission.mjs:6629-6633`); `replBindingSnapshot` (`impl/src/coordination-store.mjs:2266`) | no: `repl.binding` is kernel/embedded (`impl/src/application-semantics.mjs:1616-1624`) |
| citations | yes | grammar exactly `^repl:(shared\|worker:[A-Za-z0-9._:-]{1,256}):([A-Za-z0-9._-]{1,128})@([1-9][0-9]*)$` (`impl/src/coordination-admission.mjs:108`); resolution picks the one history row with that version, never latest (`:6731-6740`) | yes: `repl.cite` is `profile: 'ordinary'`, `surfaces: ['embedded','mcp']` (`impl/src/application-semantics.mjs:1625-1628`), tool `baton_repl_cite` (`impl/src/mcp-northbound.mjs:1356`, `:1805`, `:3060-3062`) |
| fences | yes | `bindingFence(runId, scope)` is a replay-derived count of that scope's binding events (`docs/33:82-89`), read at `impl/src/runtime-observation.mjs:3283-3286`; no `repl.read` event | internal only; readers' caches key on it |
| grants | partially: board-scoped only | `claimGrant` is closed to `{boardRunId, board}` (`impl/src/application.mjs:7843-7849`), minted by `mintMemberBoardGrant` (`:7729-7736`), CLI `--claim-grant` (`impl/src/application-cli.mjs:4116-4133`) | no deref grant; no caveats, attenuation lineage, subtree revocation or persistability anywhere |
| view limits | yes | `view.repl.bytes` 262144 shed-flagged (`impl/src/limits.mjs:256`); `MAX_REPL_BINDING_ITEMS = 512` (`impl/src/application.mjs:202`) with a shed-and-flag loop that never truncates silently (`:720-724`) | applies to the embedded view; the MCP cite returns one row |

Three corrections. First, commits are unavailable to a seat: every write path
(`repl.manifest_admitted`, `repl.binding_set`, `repl.binding_dropped`) is kernel/embedded
(`impl/src/application-semantics.mjs:1608-1624`) under orchestrator-lease or wrapper-bound worker
authority (`docs/33:57-62`, `:77-81`). Second, the run boundary is enforced on the brief path and
not on the shipped MCP read: `_replCiteInOwnRun` derives the run from the caller's task and refuses
`repl_citation_out_of_run` (`impl/src/runtime-observation.mjs:3298-3326`), while
`baton_repl_cite` passes the caller-supplied `args.runId` to `resolveReplCitation`
(`impl/src/mcp-northbound.mjs:3060-3062`). Third, the "cells" of §3 and the "cells" of §8 share a
word and no mechanism: the log's cut points and the REPL's content-addressed objects are unrelated.

## 5. What a seat cannot do today

1. **Commit context.** Manifests and bindings are kernel/embedded
   (`impl/src/application-semantics.mjs:1608-1624`). Orchestrator-side.
2. **Receive tasking as a protocol message.** Tasking is a composed prompt
   (`impl/src/cli-adapters.mjs:117`) or a stored dispatch
   (`baton2:docs/bend2/agent-commands.md:207-217`); nothing exists to poll. Undefined.
3. **Pull a wake in baton2.** The wake path is the session endpoint invoked by the committer
   (`baton2:docs/bend2/architecture.md:266-287`). Orchestrator-side.
4. **Speak the baton bridge without Node or an HTTP client.** The seat client is a Node script over
   loopback HTTP with a bearer token (`impl/src/swarm-native-bridge.mjs:24-50`). Harness-side: Base
   ships filesystem, TCP, UDP and environment effects, no OS process spawn and no JSON
   (`baton2:docs/bend2/examples/lang-host-interop.evidence.md:3-6`, listing `:98-118`, `IO.spawn`
   note `:121-124`), which is why baton2 ships its own C bindings
   (`baton2:docs/bend2/architecture.md:46-50`) and hand-rolled JSON
   (`baton2:bend2/src/json/canonical.bend`).
5. **Run `bash` from Bend2.** No process effect exists at the pin
   (`baton2:docs/bend2/examples/lang-host-interop.evidence.md:121-124`). Harness-side, and the
   largest hidden cost in §5.
6. **Be a baton seat at all.** `CLI_ADAPTERS` is closed (`impl/src/cli-adapters.mjs:878`).
   Orchestrator-side.
7. **Carry a fork basis.** No log copy and no version vector exist (§3.1, §3.4). Orchestrator-side
   for anything compared across branches; harness-side for the seat's own log.
8. **Get a deref grant.** The only grant is board-scoped
   (`impl/src/application.mjs:7843-7849`). Orchestrator-side.
9. **Cross-run cite.** Blocked by the tool's caller-supplied `runId`
   (`impl/src/mcp-northbound.mjs:3060-3062`). Orchestrator-side.
10. **Trust a peer's citation authority.** Provenance derives from the admission ledger, never a
    self-cited field (`impl/src/swarm-native-bridge.mjs:13-20`). Harness-side.
11. **Bound its own reads by the orchestrator's limits.** A Bend2 seat rendering a cited object has
    no access to `impl/src/limits.mjs`; it must mirror the ceiling. Undefined.
12. **Know which orchestrator it addresses.** baton2 has no REPL layer and baton has no
    arbitrary-harness seat path (§1). Undefined, and the first thing the design must settle.

## Proposed amendments

1. **§1: split the sentence naming "the baton2 protocol".** Name the two surfaces instead: the
   JavaScript line's seat bridge (`node swarm-native-bridge.mjs <command>`, loopback HTTP, bearer
   token, closed verb set — `impl/src/swarm-native-bridge.mjs:24-50`,
   `impl/src/swarm-native-access.mjs:89-94`) and the Bend2 line's coordinator CLI
   (`baton2:docs/bend2/architecture.md:25-30`). Pick one.
2. **New §1.1: state REPL reachability, not just existence.** Commits are kernel/embedded
   (`impl/src/application-semantics.mjs:1608-1624`); only `repl.cite` is ordinary/MCP (`:1625-1628`).
   §8 currently reads as if a seat commits cells at turn boundaries.
3. **§7: replace the fork triple with baton's three mechanisms** (§3.1): provider session fork with
   a turn cursor (`impl/src/mcp-northbound.mjs:624`, `impl/src/codex-appserver.mjs:902`), branch
   start with a workspace snapshot and a fresh conversation
   (`baton2:docs/bend2/branching-ensembles.md:46-58`), and resume of the same conversation
   (`baton2:docs/bend2/architecture.md:365-370`).
4. **§7: cite Fork-and-Flush as the branching method baton2 implements,** and state its inheritance
   precisely: workspace plus complete task inputs plus selected findings plus native configuration,
   with no log prefix (`baton2:bend2/src/coordinator/branching-model.bend:13`,
   `baton2:docs/bend2/branching-ensembles.md:3-7`, `:100-104`). The triple's log component
   contradicts the method the section proposes.
5. **§5 and §12: add the process-spawn effect as a prerequisite.** Base ships no OS process spawn
   and no JSON at the pin (`baton2:docs/bend2/examples/lang-host-interop.evidence.md:3-6`); baton2
   adds both as C bindings and hand-rolled JSON. A `bash` tool and a bridge client each need them.
6. **§7: drop or redefine "harness-state version vector".** What exists is a route version tuple
   carrying a vendor CLI version (`impl/src/route-tuple.mjs:1-5`,
   `impl/src/cli-adapters.mjs:602`, `:664`). Extension-set and schema-hash components have no
   counterpart, and the mechanism that would produce them is absent from the adapter contract
   (`impl/src/adapter-contract.mjs:65-126`).
7. **§8: replace the grant model with what exists plus a named orchestrator change.** Today's only
   grant is `claimGrant {boardRunId, board}` (`impl/src/application.mjs:7843-7849`); caveats,
   attenuation lineage, subtree revocation and persistability are a proposal over a mechanism that
   does not exist.
8. **§8: correct the citation claim and add the landed alternative.** `repl.cite` is one
   version-pinned read returning one binding row, and the run boundary is not enforced on the tool
   (`impl/src/mcp-northbound.mjs:3060-3062`). The bounded, landed alternative is a cited object
   rendered into the brief with untrusted framing (`impl/src/swarm-native-access.mjs:83-87`).
9. **§1 and §4: record wakes as landed.** The brief wake block
   (`impl/src/swarm-runtime.mjs:7059-7106`, `impl/src/limits.mjs:369`) and `autoWake`
   (`impl/src/swarm-native-bridge.mjs:93`, `:573-616`) are in code despite
   `docs/54-native-wake.md:3`. The seat's obligation becomes reading the wake block its brief
   carries, plus an optional `swarm.watch {afterSeq, timeoutMs}`
   (`impl/src/swarm-contract.mjs:275-279`).
10. **§4: replace "the orchestrator inbox" with the landed seat verbs.** Reads:
    `run.package.read`, `run.contributions.read`, `run.peers.read`
    (`impl/src/swarm-runtime.mjs:1260-1294`). Write: `swarm.update` with
    `swarm.contribution_recorded` (`impl/src/swarm-native-access.mjs:102`). Root-only:
    `swarm.capture`, `swarm.check` (`:103`). The `baton_run`, `baton_swarm`, `baton_waves`,
    `baton_knowledge` and `baton_wakes` families (`impl/MCP.md:152-160`) are orchestrator-side.
11. **§11: add "no seat-side context commit lane".** The REPL layer's write half is
    orchestrator authority, so a seat holds no durable object store of its own.
12. **§13: model-check against the bridge's stated security model**, which already fixes token
    scope to `{swarmId, participantId, runId}`, mints identity from the token table, bounds one
    JSON frame per direction by `wire.frame`, and makes refusals durable
    (`impl/src/swarm-native-bridge.mjs:4-44`).
13. **§15 milestone 4: reorder.** Commit-and-cite between seats cannot start before worker-scoped
    admission exists; the reachable half (cite, deref receipt, bounded render) can ship first.
