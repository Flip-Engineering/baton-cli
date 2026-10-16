# Knowledge: baton's knowledge layer, and how baton-cli should participate
Verdict: baton runs two knowledge stores — the orchestrator's Cairn graph and the Bend2 seat binaries' SQLite
store — and neither supports the sketch's §11 sentence as written; the seat's read path is built, tested, and called by nothing.

Roots: baton at `/Users/wahargis/Development/Experiments/baton` HEAD `1e050e420` (paths below are relative to
it); Bend2 at `…/baton-751-functional-20261015` HEAD `72fc39b45`, cited `bend2/…`; corpus claims cite
`docs/research/*` by section.

## 1. The graph: Cairn

**Kinds.** The closed node set is 19 names: `Run, Task, Artifact, Phase, Experiment, Finding, Decision,
Question, Hypothesis, Principle, Constraint, Literature, Research, RouteStat, Skill, Counterexample,
Representation, ScratchFact, Source` (`impl/src/coordination-ledger.mjs:191`). The phase-11 spec lists 17,
omitting `Question` and `Source` (`spec/phase11/coordination-knowledge.md:163-166`);
`docs/34-knowledge-horizons.md:13` states 19 and matches the code. Grounding is a separate closed set of four
— `verified`, `observed`, `derived`, `asserted` (`impl/src/coordination-ledger.mjs:195`) — and is hub-derived,
never taken from a model's confidence (`spec/phase11/coordination-knowledge.md:183-185`).

Admission rejects a `Decision` without evidence and a non-empty `informedBy` of live sources
(`impl/src/coordination-admission.mjs:6773-6777`) and a `verified` `Finding` without evidence (`:6778`);
requires every evidence reference to name a prior coordination sequence or an existing artifact id, a future
or missing sequence being `temporal_incoherence` (`:6751-6760`); requires `Supersedes` to join same-typed live
nodes without backdating, citing the current validity version, not closing over an open contradiction and not
cycling (`:6790-6796`); and requires `Contradicts` to carry one canonical pair identity, evidence, same-typed
live endpoints and no lifecycle fields at creation (`:6797-6801`). Lifecycles are bitemporal — observation,
event and valid time — with invalidated beliefs retained and supersession or contradiction resolution appended
under a compare-and-swap on the validity version (`spec/phase11/coordination-knowledge.md:176-179`).

**Relations.** Fourteen directed edge types are implemented: `Supports, Contradicts, Supersedes, Informed,
ProducedBy, Contains, DependsOn, Refines, ReadBy, VerifiedBy, DerivedFrom, Affects, Cites, ObservedIn`
(`impl/src/coordination-ledger.mjs:193`; same list at `spec/phase11/coordination-knowledge.md:172-174`).
`ReadBy` is written from every returned node to its reader (`spec/phase11/coordination-knowledge.md:194-195`)
and `VerifiedBy` from a promoted Finding to what verified it (`impl/src/coordination-admission.mjs:6857`).
Auto-link on admission is restricted by policy to `Supports`, `Refines` and `Cites`, per-type thresholds,
grounding `asserted`; `Contradicts` and `Supersedes` are never auto-minted
(`impl/src/coordination-store.mjs:2513-2519`).

**Scoping and ownership.** One coordination store per deployment holds one graph. Nodes carry `repoId`, `runId`
and `taskId`, but the read API takes no scope argument: `queryKnowledge` filters on observation boundary, valid
time, `types`, `grounding` and explicit `ids` (`impl/src/coordination-ledger.mjs:7307-7310`), and
`queryKnowledgeEdges` the same (`:7332-7334`). Scoping is therefore the store boundary; the `repoId` used by
promotion derivations, which refuse facts observed under another repository
(`impl/src/coordination-admission.mjs:6840`); and the `task`, `workflow` and `project` horizon projections
(`impl/src/coordinator.mjs:5971-5986`; `impl/src/application-semantics.mjs:1683-1687`). Writes go through the
hub's single writer with an actor field (`spec/phase11/coordination-knowledge.md:17`); promotion actors are
`orchestrator` and `operator:<id>` (`impl/src/coordination-internals.mjs:236`).

**Substrate and growth.** Truth is the append-only `events.jsonl`; the graph is a materialized view replayed
through `_apply` (`spec/phase11/coordination-knowledge.md:7-13`; `docs/34-knowledge-horizons.md:18-19`). Growth
is bounded only by the ledger — the node, edge, history and read maps grow by appended event, and a second
literal ceiling was removed because it refused operations the ledger had accepted
(`impl/src/coordination-store.mjs:148-152`) — and no pruning lane exists
(`docs/08-shared-memory-and-pm.md:165`). An evented read is growth too: it appends `knowledge.read` before
returning content.

## 2. The second store: the Bend2 seat binaries

The Bend2 line ships its own knowledge store inside the coordination SQLite database: `knowledge` with an
authored `kind` defaulting to `'finding'`, `knowledge_promotions` with source and destination kinds, and
`knowledge_relations` (`bend2/src/coordinator/knowledge.bend:16-19`). Kinds are authored strings, not a closed
set — the help says "Kinds and relations are authored strings"
(`bend2/src/coordinator/knowledge.bend:380`) — and the seat instruction names the intended kinds and relations:
"evidence, findings, hypotheses, experiments, decisions and principles … Use Supports, Contradicts, Produced,
Informed, DerivedFrom, TestedBy and Supersedes" (`bend2/src/coordinator/turn.bend:181`). Note `Produced` here
against Cairn's `ProducedBy`, with no validation of either.

Relations are free rows of `{id, author, source, relation, target}` over reference strings
(`bend2/src/coordinator/knowledge.bend:287-289`), and reads synthesize a `Cited` edge for every evidence
reference prefixed `message:`, `finding:`, `file:`, `http://`, `https://` or `external:` (`:180-186`). Scopes
are four-valued and resolved in SQL (`:77-91`): `worker` selects the session by id; `group` selects an
ensemble's owner; `universal` selects root sessions whose role is `principal-conductor` or `conductor`;
anything else, and `all`, filter nothing. A read requires the reader to be a registered session (`:107`).

## 3. Generation

**Automatic (Cairn).** Records are minted by the orchestrator from coordination events, not by seats.
Verification outcomes mint `Finding`, `Question` or `Counterexample` with grounding `verified` or `observed`,
evidence = the verification sequence plus artifact ids, actor `policy`, trigger `verified_task_outcome`
(`impl/src/coordinator.mjs:6542-6545`). A promotion batch derives candidates from a pinned prefix under scan
and batch ceilings (`impl/src/coordination-admission.mjs:6805-6868`): `task.created` → `Decision`
`coordination.spawn` (`:6834`), consequential driver records → `Decision` (`:6835`), policy-authored failure
records → `Counterexample` (`:6836`), and an observed scratch fact read by at least `minScratchReaders`
distinct completed-and-verified tasks → `Finding`, the authoring task excluded from satisfying the reader count
alone (`:6838-6859`). `Source` nodes are minted for provider observations
(`impl/src/coordination-ledger.mjs:2376`). Four source kinds mint candidate Findings for later admission:
`board.item_closed`, `package.admitted`, `scratch.cited_observed` and `verified_task_outcome`
(`impl/src/coordination-internals.mjs:1121-1128`).

**Seat-authored (Bend2), with hub-harvested evidence.** The seat holds the write verb: `baton knowledge record
--kind KIND --claim TEXT [--evidence TEXT] [--limits TEXT] [--links JSON]`
(`bend2/src/coordinator/knowledge.bend:379-380`; verb rows at `bend2/src/coordinator/commands.bend:708`,
`:748-754`, `:770-774`, `:797-805`, `:814-818`, `:860-866`; help at
`bend2/src/coordinator/agent-domain.bend:298-305`). Two disciplines attach. `--evidence report` is resolved by
the hub rather than asserted by the model: exactly one `report` message from the author to its recorded
coordinator with a sequence after the current assignment, with distinct refusals for unassigned, absent and
ambiguous cases and a refusal text naming the recovery action
(`bend2/src/coordinator/agent-native.bend:226-238`, applied `:245-252`). Recording also writes a notice to the
author's parent, body `{finding, author}` (`bend2/src/coordinator/knowledge.bend:251-256`). Generation is
encouraged by prompt text appended to every direct task prompt, naming the kinds and relation vocabulary and
ending "Preserve uncertainty and complete evidence" (`bend2/src/coordinator/turn.bend:180-188`).

**Obligation.** Neither line gates completion on generation: Bend2's obligation is prompt text plus the
evidence selector, and Cairn's is structural, since the orchestrator generates records whether or not a seat
contributes. The measured consequence is a campaign census of `knowledge.promoted` ×4 — all policy-actor
verification Findings — with zero elevations, zero `admitWorkflowFinding` uses and zero horizon reads in the
wild (`docs/reference/evidence/kg-activation-2026-07-31/kg-activation-decisions.md:5-8`), whose diagnosis is
that the graph accrues and nobody reads it (`…/kg-activation-decisions.md:18-34`).

## 4. Promotion and validation

Cairn has three promotion paths, and they are different operations.

1. **Derived batch** (`knowledge.promotion_batch`): prefix-pinned, scan-bounded, closed candidate classes,
   receipt digest-bound and replay-verified (`impl/src/coordination-admission.mjs:6805-6883`).
2. **The orchestrator-admit gate** (`knowledge.workflow_admitted`): admits one candidate Finding to the project
   horizon. Eligibility is a live `observed`-grounded Finding whose trigger is `board.item_closed`,
   `package.admitted` or `orientation.leaf_proposed`, not already admitted
   (`impl/src/coordination-admission.mjs:7019-7024`); it writes a `verified` Finding carrying the candidate's
   evidence plus `{coordinationSeq: candidate.observedSeq}` and a `DerivedFrom` edge (`:7025-7035`); authority
   is an active run-orchestrator lease plus the promotion-actor restriction, with a session gate preceding the
   replay path (`:7059-7110`). Surface: `knowledge.promote`, kernel profile, embedded and MCP
   (`impl/src/application-semantics.mjs:1632-1636`), envelope-gated at the MCP tool
   (`impl/src/mcp-northbound.mjs:2822-2835`; `impl/MCP.md:287-303`), never bridged (`impl/MCP.md:202`).
3. **Scratch correction** (`knowledge.scratch_corrected`): release, supersede or retract a closed Finding class
   from Scratch; a derived fact needs an independent oracle task with a different harness family and route
   tuple (`impl/src/coordination-admission.mjs:6898-6928`, `:6962-6989`).

Promotion history is recorded: each node carries a `promotion` object with kind and trigger
(`impl/src/coordination-admission.mjs:6827`), and Bend2 reads a finding's destinations back per finding
(`bend2/src/coordinator/knowledge.bend:35-36`). Bend2's promotion is narrower — only the registered destination
owner may promote (`:306-307`), the source must carry the finding by authorship or a prior promotion to that
endpoint (`:311-312`), the row is idempotent by identity (`:319-320`), and the destination owner receives a
notice with the full provenance triple (`:334-339`); the suite drives this across separate processes
(`bend2/test/knowledge.py:391`).

Usefulness: one instrument measures it and nothing consumes the measurement. The recall-assessment batch scans
one audited prefix, selects task-scoped receipts followed by exact mapped verification and a compatible
terminal state, and reports only `verified_pass_after_recall` or `verified_fail_after_recall`, always with
`causationClaimed:false` (`docs/08-shared-memory-and-pm.md:115-122`;
`impl/src/coordination-store.mjs:2546-2556`). The audit's separate `recallUtility` axis reports beside the
causal, temporal, structural, grounding, contradiction and contamination axes
(`impl/src/coordination-ledger.mjs:7622-7678`).

## 5. Consumption

**Read APIs and bounds.**

- **Bounded recall** (`knowledge.recall`): eleven policy fields — query bytes ≤ 64 KiB, terms ≤ 1024, candidates
  ≤ 100 000, candidate bytes ≤ 64 MiB, results ≤ 1000, graph depth ≤ 64, graph rows ≤ 1 000 000, snippet bytes
  ≤ 64 KiB, receipt and result bytes ≤ 16 MiB (`impl/src/coordination-ledger.mjs:205`, `:231-238`). Pull-only;
  appends `knowledge.read` before returning content, so an unlogged read returns nothing
  (`spec/phase11/coordination-knowledge.md:192-195`); returned prose is framed `UNTRUSTED_RECALLED_MEMORY` and
  `ReadBy` edges are created to every returned node (`impl/src/coordination-ledger.mjs:7543-7549`).
- **Graph queries**: `queryKnowledge` / `queryKnowledgeEdges` by time, type, grounding and ids
  (`impl/src/coordination-ledger.mjs:7307-7334`); `traceKnowledgeBounded` refuses when the live graph exceeds
  its state ceilings and returns an explicit unresolved frontier rather than a truncated path
  (`impl/src/coordination-store.mjs:2588-2617`).
- **Horizons**: `task`, `workflow`, `project`, cache-keyed to replay-derivable fences, non-evented, and required
  not to append to the read log (`docs/34-knowledge-horizons.md:56-64`;
  `impl/test/kg12-decisions-red.test.mjs:152-156`).
- **Ranked preview** (`recallPreview`): non-evented, LRU-cached on the KG project fence, ranked by term plus
  edge degree plus evidence count plus recency, contradiction parties first with a warning marker, read-time MAD
  confidence and staleness overlays, degrading to `briefingUnavailable` on a ceiling breach
  (`impl/src/coordination-store.mjs:2404-2510`;
  `docs/reference/evidence/repl-kg-wave-2026-07-22/kg34-decisions.md:425-444`).
- **Ambient slice**: bounded by count and bytes, expired-validity nodes dropped at serve time, each item wrapped
  `{provenance:'knowledge', untrusted:true}` with grounding and validity dates, `honestEmpty` reported
  (`impl/src/messages.mjs:740-800`); defaults 8 items and 2048 bytes (`impl/src/limits.mjs:277-278`).

**What a seat can reach.** A recruited seat in the baton JS line gets one Baton tool, the swarm bridge
(`impl/src/runtime-briefing.mjs:56-74`), and is told not to launch another Baton CLI or MCP server
(`impl/src/adapter.mjs:509-513`). Its closed verb set holds one knowledge write — `run.knowledge.seed`,
permission `contribute`, situation "pin a durable fact — typed, grounded, evidence-linked — that your peers
must be able to find" (`impl/src/swarm-contract.mjs:192-198`) — plus the read verb `evidence.search` and
`run.scratchpad.elevate` (`:193-222`). Every other knowledge tool is orchestrator- or descriptor-side
(`impl/MCP.md:158`, `:202`; `impl/src/application-semantics.mjs:1654-1657`, `:1676-1687`). The Bend2 seat
reaches the full verb set (`bend2/src/coordinator/commands.bend:748-754`, `:770-774`, `:797-805`, `:814-818`,
`:860-866`), and the Orchestra browser carries a 1119-line knowledge renderer (`bend2/ui/orchestra/knowledge.js:1`).

**What is actually read.** The census above is the strongest datum and it is negative. In source, both KG-3
serving paths exist with no production caller: `recallPreview` is defined at
`impl/src/coordination-store.mjs:2415` and called from nothing under `impl/src`; `serveKnowledge` is defined at
`impl/src/runtime-observation.mjs:2482` and delegated at `impl/src/coordinator.mjs:5358`, also with no caller
under `impl/src`. The brief seam that would carry a briefing is gated on a provider no file under `impl/src`
supplies: `providerBrief` returns the inner brief unchanged when `_knowledgeBriefingProvider` is null
(`impl/src/runtime-briefing.mjs:118-124`), the coordinator sets that field to
`opts.knowledgeBriefingProvider ?? null` (`impl/src/runtime-admission.mjs:460-463`), and `createDriver`
validates and forwards the option (`impl/src/index.mjs:1239-1240`, `:1657`) with tests as its only suppliers;
`brief.knowledge` renders when present (`impl/src/adapter.mjs:583-600`) and no code under `impl/src` sets it.
The one live knowledge call in a recorded real run is orchestrator-side: a canary seeding one node per member
run horizon, read back intact
(`docs/reference/evidence/dynamic-workflow-2026-08-03/run-dynamic-workflow.mjs:159-166`). No document under
`docs/` records a non-test run in which a seat authored knowledge.

## 6. Relationship to the sketch

**Against commit-and-cite and the workset.** The knowledge layer complements §8's commit-and-cite plane. §8
commits hand-off artifacts as cells into `worker:<seat>` and cites them `repl:<scope>:<name>@<version>`
(`docs/design/design-sketch.md:201-210`); a cell is a value the seat produced, a node is a claim with a
grounding, an evidence set and causal edges. Both are immutable, version-pinned and orchestrator-mediated, and
neither addresses the other: citations resolve to cell versions, not node ids. The corpus assigns them different
reach — "project-persistent objects ride the knowledge graph"
(`docs/research/context-networking.md:77`) — and the run-scoped-versus-deployment-scoped question names
"knowledge-graph promotion as the deployment-scoped channel" (`docs/research/addressing-and-authority.md:115`).
One conflict is real: §8's commits are deliberate acts, each rebind bumping a fence that invalidates fence-keyed
projection caches (`docs/design/design-sketch.md:222-224`), while Cairn's writes are orchestrator-derived,
prefix-pinned, batch-verified and gated by one manual admit
(`impl/src/coordination-admission.mjs:7009-7035`); a seat writing per turn would multiply fence bumps and
collapse the candidate/admit separation. §9's workset is harness-local standing state rendered into the dynamic
tail (`docs/design/design-sketch.md:231-239`) and is not graph input.

**Against the search-state posture.** The corpus records a posture in which the standing artifact is a typed,
scored population persisting outside any window, the step's context is a bounded read of the population's
frontier, and the population form adds selection pressure and exploration budgets "which make the store a
search state" (`docs/research/context-networking.md:83-92`), deriving the consequence that ranked reads of a
frontier replace budgeting arbitrary dereferences and commit-time loss acquires a selection-driven policy
(`:141`). The blackboard lineage lands in the same place: independent contributors reading and writing one
incrementally-built state under an arbiter, and "the blackboard's scheduler control is what baton's admission
replaces" (`docs/research/addressing-and-authority.md:82`, `:110`). Cairn is the right substrate and is not yet
that posture. Present: a typed record set with evidence and causal edges; a bounded, cached, ranked read with
contradiction-first ordering (`impl/src/coordination-store.mjs:2404-2510`); read-time confidence and staleness
overlays, never stored (`docs/34-knowledge-horizons.md:124-128`); a narrow win/loss table hydrated only from
hub-reverified outcomes (`docs/08-shared-memory-and-pm.md:78-81`). Absent: any score outcomes move — the ranking
weights are deployment-owned constants
(`docs/reference/evidence/repl-kg-wave-2026-07-22/kg34-decisions.md:436-444`) — any population operator, and any
exploration budget. Bend2's search is lexical scoring with cycle-terminating traversal
(`bend2/src/coordinator/knowledge.bend:191-234`): a ranked read, not a population.

**What the harness should emit, and when.** At settlement: the report and its evidence references, which is what
both lines harvest (`bend2/src/coordinator/agent-native.bend:226-238`;
`impl/src/coordination-admission.mjs:6751-6760`); a receipt for any knowledge read, carrying node id, grounding,
validity version and the read record it corresponds to, since §12's deref receipt covers cell reads and not
graph reads (`docs/design/design-sketch.md:282-287`; `spec/phase11/coordination-knowledge.md:192-195`); at most
one candidate hand-off artifact per boundary as a cell, per §8; and no node and no edge authored at autonomy,
because grounding is hub-derived (`spec/phase11/coordination-knowledge.md:183-185`) and the only authorship
paths that survive review are hub-harvested (`bend2/src/coordinator/agent-native.bend:226-238`) or gate-bound
(`impl/src/coordination-admission.mjs:7059-7110`). Per turn, nothing.

**Obligations against pollution.** Never write `Contradicts` or `Supersedes` from a seat
(`impl/src/coordination-store.mjs:2513-2519`); never write a claim without a prior-sequence or artifact evidence
reference (`impl/src/coordination-admission.mjs:6751-6760`); never write per turn, because growth is unbounded
and pruned by nothing (`impl/src/coordination-store.mjs:148-152`); frame recalled content as untrusted where it
enters the prompt, with its grounding visible, since editable context is a named injection channel
(`docs/research/context-networking.md:102`); and write only the seat's own scope, which Bend2 enforces by making
the promotion source carry the finding (`bend2/src/coordinator/knowledge.bend:311-312`).

## 7. Gaps

**Harness-side.**

1. **A seat-side knowledge read with a bound and a receipt.** Neither line gives a seat the Cairn read: the JS
   seat verb set has no knowledge read (`impl/src/swarm-contract.mjs:192-222`) and Bend2's read verbs address a
   different store. §11 asserts the standing store is the orchestrator's layer while §5 gives the seat `bash`,
   `read`, `edit` and the inbox and no path to it (`docs/design/design-sketch.md:110-111`, `:260-263`).
2. **The delivery channel, chosen explicitly.** A tail read costs no tool-catalog change, schema or prefix
   invalidation; a tool costs all three, and §5 adds nothing until a measured gap argues for it
   (`docs/design/design-sketch.md:129-130`) — and the measured evidence is zero reads in the wild
   (`…/kg-activation-decisions.md:5-8`).
3. **The bound as a number** (serve defaults 8 items and 2048 bytes, `impl/src/limits.mjs:277-278`; recall capped
   at the deployment policy, `impl/src/coordination-ledger.mjs:231-238`), which is §8's deref-bound question
   applied to knowledge and unanswered (`docs/design/design-sketch.md:330-331`).
4. **An evidence obligation if the seat ever writes a record**, hub-derived as Bend2's selector is, plus a
   settlement-time hook: nothing ties task completion to a knowledge-relevant artifact, since §8's commits are
   hand-off artifacts for other seats (`docs/design/design-sketch.md:201-210`).
5. **The no-write rule stated positively**: the seat emits reports and receipts, record minting is the
   orchestrator's derivation, and a seat that never calls a knowledge verb still participates.

**Orchestrator-side.**

1. **The serving paths are built and unwired** (`impl/src/coordination-store.mjs:2415`;
   `impl/src/runtime-observation.mjs:2482`; `impl/src/runtime-admission.mjs:460-463`), which the activation epic
   dates: "the machinery is shipped and suite-green, but campaign-dormant" (`…/kg-activation-decisions.md:5-6`).
2. **A seat-facing knowledge read verb** beside `evidence.search` (`impl/src/swarm-contract.mjs:193-215`), and a
   **promotion ritual that happens**: the candidacy queue and ritual counts exist as projections
   (`impl/src/coordination-store.mjs:2571-2577`) and the recorded elevation count is zero
   (`…/kg-activation-decisions.md:6-8`).
3. **A growth and retention answer** (`impl/src/coordination-store.mjs:148-152`), and a **usefulness signal that
   can change something**: assessment measures and cannot rank (`docs/08-shared-memory-and-pm.md:115-122`).
4. **Search-state operators**, if the corpus posture is to be honored rather than recorded
   (`docs/research/context-networking.md:83-92`, `:141`).
5. **The promotion gate's owner when no task suite exists** — §16's open question
   (`docs/design/design-sketch.md:326`), which Cairn answers for itself with the run lease and the
   promotion-actor set (`impl/src/coordination-admission.mjs:7059-7110`).

## Uncertainty and unverified items

- The Bend2 law file has drifted from the module it claims to bind: the schema law states a `knowledge` table
  without the `kind` column and a promotions table without the kind fields
  (`bend2/src/coordinator/knowledge-laws.bend:18-19` against `bend2/src/coordinator/knowledge.bend:16-19`); it
  calls `promotion_admitted` with two arguments where the module declares three
  (`bend2/src/coordinator/knowledge-laws.bend:98-101` against `bend2/src/coordinator/knowledge.bend:306`); and
  it references an `evidence_ok` function absent from the module. Whether the entry compile still checks these
  statements was not verified.
- A deployment outside this repository may supply `knowledgeBriefingProvider`, and `recordContamination` appears
  in the coordinator mutator allowlist (`impl/src/runtime-admission.mjs:68`) with no definition under `impl/`;
  `bend2/…/knowledge_v1.bend` and `knowledge-eval.py` are branch-only. All three were left unverified.
- Project-manager's live scale figures are quoted from baton's digest (`docs/08-shared-memory-and-pm.md:19`).

## Proposed amendments

Ranked by effect on the harness's behaviour. Each names the section, the wording, and the missing mechanism.

1. **§11, third bullet — replace the one-line assertion.** Say: the standing store is the orchestrator's Cairn
   graph, repository-scoped over an append-only coordination ledger; its records are minted by orchestrator
   derivation from settled task outcomes, settled board items, admitted packages and cited observed scratch;
   they reach project truth only through one admit gate under a run lease; the seat holds no write authority
   over the graph and reaches it through one bounded, provenance-framed read; there is no harness-local memory
   and no harness-local knowledge store. Cite `spec/phase11/coordination-knowledge.md:159-213`,
   `impl/src/coordination-admission.mjs:7009-7110`.
2. **§8 — add the seat's knowledge read as a bounded, non-evented delivery.** At dispatch the orchestrator may
   attach a bounded knowledge slice to the provider-facing brief: item and byte caps deployment-owned, every
   item framed untrusted with its grounding and validity dates, contradiction-joined nodes ranked first with a
   warning marker, an honest empty marker for an empty graph, an unavailable marker rather than a blocked
   dispatch on a ceiling breach, and no entry into the admitted brief, so `briefDigest` and continuation
   matching are unaffected. Cite `impl/src/messages.mjs:740-800`, `impl/src/adapter.mjs:583-600`,
   `docs/reference/evidence/repl-kg-wave-2026-07-22/kg34-decisions.md:200-235`.
3. **§12 — extend the default emission set.** Beside the per-deref receipt: for every knowledge record the seat
   consumes, the node id, grounding, validity version served and the orchestrator's read record id; for every
   settlement, the evidence references the orchestrator may harvest. Cite
   `spec/phase11/coordination-knowledge.md:192-195`, `docs/design/design-sketch.md:282-287`.
4. **§8 — add the knowledge promotion rule beside the grant rules.** Knowledge promotion is neither the
   statistical gate nor a branch-artifact review: it is the orchestrator's admit gate, restricted to a live
   observed-grounding candidate from a closed trigger set, bound to an active run lease and a promotion actor,
   with the admitted Finding carrying a `DerivedFrom` edge to its candidate. Cite
   `impl/src/coordination-admission.mjs:7019-7035`, `:7059-7110`.
5. **§9 — state the boundary against the graph in one sentence.** The workset is harness-local standing state
   and is never an input to a knowledge record; the graph's input is the settled task's evidence. Cite
   `docs/design/design-sketch.md:231-239`, `impl/src/coordination-admission.mjs:6751-6760`.
6. **§5 — choose the channel for knowledge access explicitly.** Under "nothing further is added until a measured
   gap argues for it" (`docs/design/design-sketch.md:129-130`), state that the seat's knowledge read rides the
   dynamic tail rather than the tool catalog, that its write path is the ordinary report, and that a dedicated
   verb waits on measurement of the tail read.
7. **§11 — add the pollution obligations as a fourth bullet.** Never write `Contradicts` or `Supersedes`; never
   write a claim without a prior-sequence or artifact evidence reference; never write per turn; never mark
   recalled content as instruction. Cite `impl/src/coordination-store.mjs:2513-2519`,
   `impl/src/coordination-admission.mjs:6751-6760`, `docs/research/context-networking.md:102`.
8. **§14 — add the search-state posture as a fourth bet with its falsification condition.** The corpus records
   the posture (`docs/research/context-networking.md:83-92`) and derives the consequence for navigation reads
   (`:141`). The bet: a graph read ranked by a score that outcomes move, over a bounded frontier, beats a
   fixed-weight ranked read at equal budget — falsified if the fixed-weight read matches it, which is today's
   state, since the weights are constants (`docs/08-shared-memory-and-pm.md:115-122`).
9. **§16 — rewrite the promotion-gate question to name the three that are open for knowledge.** Who authors a
   seat-side record and with what evidence; whether a seat's read is evented or served from cache; the growth
   boundary for a graph meant to be permanent and pruned by nothing (`docs/08-shared-memory-and-pm.md:165`); the
   existing gate-owner question is answered by the run lease (`impl/src/coordination-admission.mjs:7059-7110`).
10. **§2 — add the read record to the log's item vocabulary**, so one read has one identity rather than a second
    invention. Cite `spec/phase11/coordination-knowledge.md:192-195`, `docs/design/design-sketch.md:282-287`.
