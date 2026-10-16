# Deref and consistency: operational semantics for cross-session context reads

This report covers the second family of missing primitives from the networked-context program: the operational semantics of dereferencing another session's context through the orchestrator. The substrate is baton's REPL layer — content-addressed cells, named versioned bindings with a per-scope CAS, a citation grammar that pins versions, grants for cross-session reads minted server-side, and the wake plane — with seat contexts committed as versioned cells at turn boundaries and receivers dereferencing through orchestrator-mediated reads ([context-networking.md](context-networking.md) §2-3). Three questions follow from that substrate: what one dereference may cost the reader (read budgeting), what a reader is entitled to when the owner session is in one of four states (passivation consistency), and whether any form of shared live context is consistent with the corpus and baton's recorded non-goals. A final section defines the measurement design that would settle the deref-versus-re-derivation question. Sibling evidence is drawn from [nooa.md](nooa.md), [prime-agent.md](prime-agent.md), [fx.md](fx.md), [pi.md](pi.md), [deepseek-harness.md](deepseek-harness.md), [arcee-nac.md](arcee-nac.md), [unreal-agent.md](unreal-agent.md), and [benchmarks.md](benchmarks.md); baton doc and code citations resolve against the tree read for [context-networking.md](context-networking.md) (HEAD `1e050e42`, 2026-09-22).

## 1. Read budgeting

### 1.1 What the analyzed harnesses budget, and where

Every surveyed harness bounds what enters a model context from outside it, at four different layers:

- **NOOA budgets the projection, not the value.** `TruncationConfig` bounds previews at method invocation (`prefill_format`: `max_string=2000`, `max_length=25`, `max_depth=4`) and event-field rendering every turn (`event_format`: `max_string=10_000`); raw cell capture is bounded separately (stdout 50,000 characters, head/tail split). Author-curated context blocks are unlimited at write time and evicted whole at assembly against `max_context_tokens`, defaulting to half the usable window (`(context_window - reserve) // 2`, `runtime/actor.py:3005-3013`) ([nooa.md](nooa.md) §3.2, §3.6). Token accounting needs no tokenizer: counts are characters multiplied by a provider-calibrated ratio (prompt tokens over total characters from the last response), corrected per model by an EMA tracker ([nooa.md](nooa.md) §3.6).
- **fx budgets bytes at the tool boundary with handle paging.** Model-visible tool results cap at 64 KiB (`default_max_tool_result_bytes`); outputs above 16 KiB spill to content-addressed handles with a 4 KiB preview, and `read_tool_result` pages a stored output at 8 KiB default, 64 KiB max ([fx.md](fx.md) §3). The compactor's budgets scale by a measured correction ratio: `request_token_calibration` pairs the last provider-counted input tokens with the estimate that produced them ([fx.md](fx.md) §9).
- **pi truncates at the compaction boundary.** Serialization for the summary call truncates tool results at `TOOL_RESULT_MAX_CHARS = 2000` (`compaction/utils.ts:94`); live reads truncate files at 2,000 lines or 50 KiB ([pi.md](pi.md) §5, §7).
- **dsh budgets the program runtime.** The Node PTC runtime's shipped defaults are `maxOutputBytes` 64 MiB serialized output, `maxOldGenerationSizeMb` 512, `maxMessageBytes` 128 MiB, `maxPendingCalls` 128 (`ptc-runtime-node/src/config.ts:30-40`); the host additionally bounds frames, queued writes, pending calls, and outstanding argument bytes on the inherited control channel ([deepseek-harness.md](deepseek-harness.md) §4.1).
- **Prime budgets on both sides of the kernel.** Kernel-serialized execution results cap at 1,048,576 characters (`rlm/repl.py:51-56`); the host applies a per-execution cap of 65,536 characters overridable per request ([prime-agent.md](prime-agent.md) §3).
- **baton budgets views.** Bounded projections each carry explicit byte/item limits with typed shed markers: `view.repl.bytes`, `MAX_REPL_BINDING_ITEMS = 512` with never-silent shedding, `view.wake_replay.items = 4096` ([context-networking.md](context-networking.md) §3.2).

The pattern across the corpus: the budget applies to the projection a consumer sees, the full value stays addressable behind a handle, and every enforced limit reports what it shed. baton already has this shape for its own views; a cross-session dereference adds the question of who pays.

### 1.2 Prior art on budgeted retrieval

- **API quota design.** Rate limiting in network APIs is built from token buckets and two-rate/three-rate markers specified in RFC 2697 and RFC 2698 (Heinanen and Guerin): a standing allocation is consumed per request and refills at a declared rate, and exceeding the bucket is a typed refusal carrying the retry condition, carried through to practice in provider rate-limit policies ([Stripe rate limits](https://docs.stripe.com/rate-limits) documents fixed-window limits per principal with declared behavior on excess). A per-dereference budget is a token bucket of context bytes keyed by the reading seat, with a typed shed marker on truncation — the shape RFC 2698 specifies for network traffic and baton's frame limits already realize for views.
- **Information foraging.** Pirolli and Card (1999) model information seeking as cost-benefit trade-offs between acquisition cost (time to access a patch of information) and information value, with "information scent" as the local cue for whether a patch is worth reading ([Pirolli & Card, *Information Foraging*, Psychological Review 106(4), 1999](https://doi.org/10.1037/0033-295X.106.4.643)). A dereference budget is the mechanization of the same trade for a model consumer: the preview is the scent, the budget-bounded read is the patch, and the decision to page further belongs to the reader.
- **Attention budgets.** Anthropic's context-engineering framing treats context as a finite resource with an attention budget and names just-in-time retrieval — holding lightweight identifiers and loading content on demand — as the posture for large data ([Anthropic, effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents); recorded in [no-compaction-approaches.md](no-compaction-approaches.md) §2). The measured support is the Chroma context-rot finding that performance degrades with input length even on simple tasks ([no-compaction-approaches.md](no-compaction-approaches.md) §6).
- **RAG top-k as a de-facto read budget.** Retrieval-augmented generation retrieves a fixed k documents and renders their snippets into the prompt (Lewis et al., [arXiv:2005.11401](https://arxiv.org/abs/2005.11401)); the SWE-agent ablation shows the budget's effect directly — summarized search at 18.0% against pager-style iterative search at 12.0% on the same model ([benchmarks.md](benchmarks.md), SWE-agent section). Top-k is the precedent that a dereference operator should be ranked and budgeted as one operation, matching context-networking's observation that population-operator framing turns dereferences into ranked reads of a frontier ([context-networking.md](context-networking.md) §5.2).

### 1.3 What a per-dereference read budget needs

Four decisions, each with a corpus-grounded default:

1. **Unit.** Bytes are the enforceable unit at the orchestrator: fx, dsh, and Prime all enforce character/byte caps mechanically, while token-denominated budgets everywhere sit next to a chars-to-tokens estimate (NOOA's provider-calibrated ratio; fx's `request_token_calibration`; pi-durable's token floor). A dereference budget should be declared in bytes and converted to an estimated token figure at the enforcement point using the seat's calibration ratio, so the budget is enforceable and the cost model stays provider-relative.
2. **Calibration.** Provider-counted counts are available only after a request returns; both NOOA and fx correct estimates against the last provider-counted count with an EMA-style ratio. A dereference served before the reader's next model call cannot use the reader's provider count; the orchestrator can bound bytes exactly and estimate tokens only. This is a residual uncertainty, not a solved design: no corpus system calibrates a projection issued between calls.
3. **Enforcement point.** Projection time. Every harness in the survey enforces at the moment the projection is rendered — NOOA at preview rendering, fx at the tool-result boundary, Prime at kernel serialization and host ingress, baton at view projection with shed markers. For dereference this means the orchestrator slices the cited cell (or its declared projection) under the budget before the bytes move; the seat never receives an unbounded body.
4. **Accounting.** Three keys are needed together: per-seat (the reader's standing budget, the token-bucket key); per-citation (each `repl.cite`/deref resolution charges itself, so a seat holding twenty citations pays for the ones it dereferences); per-scope (an aggregate cap per `(runId, scope)` so fan-out over a shared binding cannot multiply cost linearly in readers). Prime's subtree accounting — child usage folded into the spawning parent's transcript row ([prime-agent.md](prime-agent.md) §5) — is the corpus precedent for making attribution visible in the artifact the budget is charged against.

## 2. Passivation consistency

### 2.1 The four reader states and the entitlement question

A reader dereferences a citation of seat A's context. The question is what the read is entitled to in four states of A:

- **(a) A is mid-turn.** A's committed context is the binding version at its last turn boundary; its in-turn state is unwritten.
- **(b) A is passivated.** Committed state is durable; A's process may be parked or stopped.
- **(c) A is crashed.** Committed state through the last admitted cell is durable; a turn in flight may be partially journaled.
- **(d) A rebinds and restarts.** The citation pins one version in A's binding history; A's new versions land after it.

For (b) and (d) baton's existing semantics already answer: cells are immutable and settled-only, citations resolve the exact recorded version from history, and version pinning holds across rebind ([context-networking.md](context-networking.md) §2.2, §4.1). The named residual is (a): a dereference issued while the owner is inside a turn, before its next commit ([context-networking.md](context-networking.md) §3.3, item 4).

### 2.2 MVCC and snapshot isolation as the read semantics

The 1978 answer to reading while a writer works is Reed's version-based synchronization: represent a modifiable object as a sequence of immutable versions, let a reader pin the version that existed when it began, and let writers append without blocking readers (D. P. Reed, *Naming and Synchronization in a Decentralized Computer System*, MIT-LCS-TR-205, [bitsavers scan](http://www.bitsavers.org/pdf/mit/lcs/tr/MIT-LCS-TR-205.pdf)). Berenson et al. formalized the same read rule as snapshot isolation — each transaction reads a snapshot of the committed state taken at its start (Berenson et al., *A Critique of ANSI SQL Isolation Levels*, SIGMOD 1995, [arXiv:cs/0701157](https://arxiv.org/abs/cs/0701157); [MSR TR-95-51](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/tr-95-51.pdf)).

Mapping to baton: the binding history is the version sequence, the citation grammar is the snapshot pin, and the dereference of a cited version is a snapshot read. The MVCC answer to state (a) is therefore defined by construction: a mid-turn read is served from the last committed version, which is exactly the version any citation records. The substrate already implements this for cited versions; the design question below is only whether an implicit read of the seat's live context (read without a version) receives the same rule. pi-durable states the in-corpus precedent explicitly: its session kernel holds a single serialized mutation line, and "only committed state is observable" — reads cannot observe in-flight mutations ([pi.md](pi.md) §9).

### 2.3 Actor supervision and hibernation as passivation discipline

Erlang/OTP supplies the vocabulary for (b) and (c). Armstrong's thesis defines supervision trees and restart strategies (`one_for_one` restarts only the crashed child; siblings are undisturbed) and the let-it-crash discipline: state survives as data the supervisor can restore, and the process is expendable (J. Armstrong, *Making reliable distributed systems in the presence of software errors*, KTH 2003, [erlang.org/download/armstrong_thesis_2003.pdf](https://erlang.org/download/armstrong_thesis_2003.pdf)). Hibernation defines the parked state itself: `erlang:hibernate/3` compacts the process to a minimal heap and resumes on the next message, with no observable state change for peers ([erlang:hibernate, ERTS reference](https://www.erlang.org/doc/apps/erts/erlang.html)).

Prime is the closest in-set realization: the daemon supervises one worker per session with backoff restarts, adopts sessions after restart from persisted worker descriptors, passivates idle workers with a graceful stop, and keeps non-resident children roster-visible through a separate append-only spawn ledger ([prime-agent.md](prime-agent.md) §4, §7). Reading a passivated Prime child goes through bounded projections — `agent_observe` status and transcript previews, windowed reads over the `{session_id}.jsonl` store — and results travel as persisted `agent_message` entries, which is what makes a queued message survive recipient passivation. The lesson for baton's deref plane: a passivated seat needs a descriptor-level name (baton has this — the binding history and manifest principal), and a crashed seat needs the durable record to define what is readable.

### 2.4 Durable execution as the crash-consistency reference

For state (c), the durable-execution engines define the standard. Temporal rebuilds workflow state by replaying deterministic code against an append-only event history; a crashed worker replays from the beginning and resumes at the first event past the recorded history ([Temporal, event history](https://docs.temporal.io/encyclopedia/event-history)). Azure Durable Functions checkpoint the same way: an append-only history table in the task hub, with control queues waking orchestrators ([Azure Durable Task, programming model overview](https://learn.microsoft.com/en-us/azure/durable-task/common/programming-model-overview)). Within the sibling corpus, Unreal Agent is the direct implementation: caller-supplied idempotent input IDs persisted before processing, versioned serializable operations committed atomically with the tool-call status that waits on them, and resume reconstructing in-memory state from the log alone, fuzz-tested ([unreal-agent.md](unreal-agent.md) §3, §6). Arcee NAC adds the exactly-once inbox for completions across managed orchestrators and marks its own worker failures non-transactional — environment mutations without a committed episode leave history behind the true state ([arcee-nac.md](arcee-nac.md) §2, §10).

The mapping: baton's deref plane inherits its crash answer from cell admission, which is already durable-before-resolvable — only settled, durably admitted cells resolve, and a missing artifact goes through resolve-time revalidation settling the cell `attention` ([context-networking.md](context-networking.md) §2.4). A reader of a crashed seat therefore sees the last admitted version line plus typed signals; the read path needs no replay machinery because the write path committed version-by-version at turn boundaries.

### 2.5 The mid-turn read design question

Three candidate answers for state (a):

1. **Serve last-committed (the MVCC answer).** The dereference returns the version at A's last turn boundary, marked with its version. Reads never block or wait on writes; the rule is uniform with the citation grammar; pi-durable's committed-only observability supports it. Cost: a reader may act on a stale mid-turn snapshot — acceptable if the deref result carries the version so the reader can detect the gap.
2. **Reject.** A typed refusal while the owner holds an open turn. No staleness. Cost: it couples the reader's turn to the owner's phase, which the wake plane exists to decouple; the corpus has no precedent for phase-coupled reads.
3. **Queue to the turn boundary.** The read resolves at A's next commit, delivered through the wake plane. The reader gets fresh state. Cost: the dereference becomes asynchronous with unbounded latency, and the wake plane's contract ("a coordination row wakes at most once and never carries a request body") fits result delivery, not read latency.

The baton substrate's recorded instincts point at option 1: turn boundaries are the commit points (docs/35 turn checkpoints), citations already pin versions, and the wake plane handles the asynchronous case separately — a seat wanting fresher state subscribes to the wake stream and re-cites after the owner commits. Option 1 with version marking in the deref receipt is the design consistent with all three planes.

## 3. The shared-live-context question

### 3.1 Why distributed shared memory failed as a transparency layer

The classic literature gives the failure record. Li and Hudak's shared virtual memory gave loosely coupled machines a single shared address space at page granularity, and the measured cost was coherence traffic: strict page-granularity consistency drove page ping-ponging and made false sharing — two processors writing independent variables on one page — the dominant cost (K. Li and P. Hudak, *Memory Coherence in Shared Virtual Memory Systems*, ACM TOCS 1989, [PDF](http://css.csail.mit.edu/6.824/2014/papers/li-dsm.pdf)). Eggers and Katz characterized sharing and its coherency cost in multiprocessor caches, isolating false sharing as the dominant cost when access granularity exceeds write granularity (Eggers and Katz, ISCA 1988, [record](https://homes.cs.washington.edu/~eggers/Research/coherency.html)). TreadMarks recovered viability by weakening the guarantee — lazy release consistency propagates writes only at a matching acquire, and a multiple-writer protocol admits concurrent writers at the price of diffs and per-writer states (Keleher et al., *TreadMarks: Distributed Shared Memory on Standard Workstations and Operating Systems*, USENIX Winter 1994, [PDF](https://cseweb.ucsd.edu/classes/sp11/cse223b/papers/keleher94.pdf)). The trade the literature records: transparent sharing of mutable state costs either coherence traffic at transparent granularity or consistency guarantees relaxed until they are no longer transparent.

The agent-context analogue is exact. A seat's context is the "page"; an owner's within-turn writes happen at arbitrary granularity; a reader's dereference is a page fetch. A false-sharing-like pathology appears as cache invalidation: every owner commit bumps the scope fence and invalidates fence-keyed projection caches, so frequent commits with frequent readers pay coherence in the reader's KV cache ([context-networking.md](context-networking.md) §4.3, §6). Shared live context with transparent read semantics inherits the traffic cost; weakening to eventual consistency inherits the TreadMarks trade of losing the transparency that motivated the design.

### 3.2 What OT and CRDTs achieve, and for what object

Operational transformation and CRDTs are the solved cases for convergent shared documents. Ellis and Gibbs introduced transformation of concurrent operations in GROVE, letting concurrent edits converge without blocking user input (Ellis and Gibbs, *Concurrency Control in Groupware Systems*, SIGMOD 1989, [PDF](https://grouplab.cpsc.ucalgary.ca/grouplab/uploads/Publications/Publications/1994-Concurrency.Report94-534-03.pdf)); Google Wave's OT whitepaper specifies the server-serialized composition form ([Operational Transformation whitepaper, Wave Protocol](https://www.waveprotocol.org/whitepapers/operational-transform-whitepaper)). CRDTs guarantee strong eventual convergence for replicas updated concurrently without coordination (Shapiro et al., *Conflict-Free Replicated Data Types*, SSS 2011, [HAL inria-00555588](https://inria.hal.science/inria-00555588); arXiv companion: [arXiv:1805.06358](https://arxiv.org/abs/1805.06358)). These results apply to objects with convergent edit semantics — text, counters, sets. A model context is a different object: it is read as a whole at each model call, its edits are whole-turn rewrites of a mutable transcript, and two seats editing one live context have no defined join for their differences. The corpus contains no published system that makes two model-owned contexts one addressable object ([context-networking.md](context-networking.md) §3.3, item 5).

### 3.3 Why every analyzed harness refuses shared live context

The refusals are recorded decisions in each system:

- **baton**: the design rules name the non-goals directly — "No arbitrary-code kernel (permanent). No mutable objects. No cross-run bindings … No worker-authority shared writes" (docs/33 §6); cells are immutable with settled-only resolution (docs/33 §3.3).
- **NOOA**: deref resolves into the same agent's own state; pass-by-reference is intra-process by construction, and persistence serializes at exactly the durability boundary ([nooa.md](nooa.md) §3.4, §4).
- **CLM**: each context file "remains synchronized with its respective LLM server" — one file per server, no cross-file dereference ([context-networking.md](context-networking.md) §3.2).
- **Prime**: results travel as durable message entries because live kernel state is best-effort per-variable ([prime-agent.md](prime-agent.md) §3, §4).
- **fx** excludes child conversations from listing and external resume — session stores are single-owner ([fx.md](fx.md) §8); **pi**'s conversations carry a single ownership kind ([pi.md](pi.md) §9); **NAC** routes all cross-thread reads through the orchestrator and gives workers no cross-thread tools ([arcee-nac.md](arcee-nac.md) §2).

The agreement is structural: every system keeps the durable artifact single-writer and immutable (or message-borne), and mediation replaces sharing.

### 3.4 The three candidate alternatives

1. **Shared derived artifacts.** A converged summary computed from several seats' committed cells is itself committed as a new cell in a shared scope, by the orchestrator or a dedicated seat. This is consistent with the non-goals: objects remain immutable, writes to the shared scope carry orchestrator authority, and readers cite the derived version. Cost: the derived artifact is lossy at commit time (the corpus's standing lossy-boundary finding) and its freshness is bounded by its recomputation cadence; the sleep-time-compute literature measures the economics of exactly this trade — accuracy maintained at a fraction of test-time compute when queries are predictable from the context ([no-compaction-approaches.md](no-compaction-approaches.md) §3).
2. **Append-only shared ledger.** Each seat appends immutable entries (its committed cells and citations of them); no seat mutates another's entries. This is the knowledge-graph pattern: baton already routes project-persistent objects across runs through the knowledge graph (docs/34, cited in docs/33 §6), and NOOA's memory graph and Zep/Graphiti's temporal knowledge graph are the same shape one layer up. It is consistent with every recorded non-goal — entries are immutable, scopes stay single-writer, the ledger is a new named namespace. Cost: addressing needs a run-scoped grant (missing mechanism 2 of [context-networking.md](context-networking.md) §3.3), and readers pay per-entry deref budgets.
3. **Orchestrator-arbitrated commit.** The blackboard pattern: knowledge sources post to one shared structure and a scheduler decides which source may act next (Erman et al., *The Hearsay-II Speech-Understanding System*, ACM Computing Surveys 1980; H. P. Nii, *Blackboard Systems*, AI Magazine 1986, [part 1](https://ojs.aaai.org/aimagazine/index.php/aimagazine/article/view/548)). In baton the orchestrator already holds this role — it promotes one seat's committed version to `shared` by rebind, and grants for board claims are minted server-side. Consistency with the non-goals: yes, because the arbitration point is where single-writer authority is enforced. Cost: the arbitrator is a serialization point, and its policy (who may post, when) is unmeasured in the corpus.

Verdict: the shared live context of the strong H2 reading has no implementation and no advocates in the corpus, and its cost model — coherence traffic in reader caches, convergence semantics undefined for whole-transcript objects — is the one the DSM literature already measured as hostile. Alternatives 1 and 3 are consistent with baton's recorded non-goals and compose; alternative 2 is consistent and is the lowest-cost addressing extension, since it adds a namespace and grants over objects that are already immutable and versioned. All three keep the read model of section 2 unchanged: a reader cites a version, never a mutable object.

## 4. Measurement design

### 4.1 Task classes

Deref beats re-derivation when the target state is expensive to recompute and cheap to read: (a) long-horizon shared artifacts (a test plan, a design index, an environment inventory) recomputed per seat would duplicate cost that deref pays once at read; (b) cross-seat handoff where seat B's task starts from A's final state and A's context is large relative to the committed delta; (c) fan-out where one committed artifact is read by many seats. Deref loses where re-derivation is cheap and fresh: small targets, high mutation rates between B's deref and B's use, or tasks where B's model must re-derive the reasoning behind A's state for correctness — a summary or a table of committed facts dereferences well, a decision trail re-derives better. The RLM paper's ablation is the cautionary anchor: the recursive, networked half added value only on information-dense inputs, and the REPL-variable half carried most of the value ([context-networking.md](context-networking.md) §5.2).

### 4.2 Metrics

- **Tokens**: total input/output tokens per seat and per task, split into inline-baseline tokens and deref-received tokens, against a re-derivation baseline running the same model (the same-model, single-attempt pairing discipline of [benchmarks.md](benchmarks.md)).
- **Wall clock**: per-task and per-deref, with the owner's commit cadence recorded as a parameter (benchmarks.md's limits-as-recorded-parameters rule).
- **Correctness of the dependent task**: task-level resolution under the benchmark's own grader, and replay-exactness of the dereference itself — B's dereference must return the exact bytes A committed (binding digest match), the criterion already named in the H1 settling evidence ([context-networking.md](context-networking.md) §5.1).
- **Cache behavior**: prefix-cache hit rate across owner commits, since every rebind bumps the scope fence and invalidates fence-keyed projections — the unmeasured interaction named in [context-networking.md](context-networking.md) §6. The cache-accounting definition to adopt is CLM's prefix-reuse FLOPs measure, with deref results appended at the reader's tail ([context-networking.md](context-networking.md) §4.3).

### 4.3 Failure injection

Four injections, each with a defined expected outcome drawn from named baton semantics:

1. **Lost artifact**: drop a cited cell's artifact after admission; expect resolve-time revalidation and live re-evaluation settling the cell `attention` (retryable) — docs/33 §3.3 items 8-9.
2. **Stale version**: owner rebinds between B's deref and B's use; expect B to continue on its pinned version, with the version gap visible in the receipt.
3. **Revoked grant**: revoke a deref grant mid-task; expect a typed refusal on the next dereference, with no partial delivery (the grant model follows `mintMemberBoardGrant`).
4. **Mid-turn deref**: dereference while the owner holds an open turn; expect the last-committed version with the version marked, per section 2.5's option 1.

### 4.4 What a minimal two-seat experiment must log

Publishable evidence requires per-trial logs that a third party can reanalyze — the Terminal-Bench ATIF trajectory requirement as the template ([benchmarks.md](benchmarks.md)). Minimum fields:

- task identity, model, seat configs, and all budget parameters (read budget unit and values, commit cadence, grant scope) recorded as configuration, not defaults ([benchmarks.md](benchmarks.md), concept 5);
- per-deref receipts: cited `(scope, name)@version`, resolved cell id, digest match, bytes delivered, shed marker and dropped byte count if truncated, and the deref latency;
- per-seat token counts split as in 4.2, with provider-counted and estimated tokens kept separate (NOOA/fx calibration leaves the gap as a measured quantity);
- cache events per reader turn: prefix hit/miss boundaries relative to the last owner commit;
- failure-injection outcomes as typed events with the expected outcome code, so an injection trial is pass/fail on the named semantics rather than on task success;
- the session logs themselves as append-only trajectory events sufficient for post-hoc judging ([benchmarks.md](benchmarks.md), concept 4).

The settling criteria carry over from the H2 verdict: navigation beats re-derivation on cost at matched accuracy for a measurable task class, stale-citation behavior is benign, and grant enforcement survives adversarial content in committed cells ([context-networking.md](context-networking.md) §5.2).

## 5. Open questions

- What deref budget defaults are defensible before measurement? No corpus system budgets a cross-session read; fx's 64 KiB and NOOA's 10,000-character event bound are the nearest anchors, and both sit inside one session's trust boundary.
- Can the orchestrator estimate tokens for a between-calls projection, or must the budget be byte-denominated with token estimates exposed post-hoc? No corpus system calibrates a projection issued between model calls.
- Does the mid-turn read need a distinct answer in the sub-case where the owner commits at high frequency (cache-invalidating churn) versus low frequency (staleness)? The tradeoff surface is unmeasured.
- Is a ranked dereference (population-frontier reads over the committed store, [context-networking.md](context-networking.md) §3.4) a different budget problem from a raw dereference, and does the top-k evidence transfer?
- Whether shared derived artifacts need a committed recomputation schedule or can be computed lazily at deref time from the ledger is undecided; lazy computation moves the lossy boundary to read time, changing which failures are typed.

## Sources

Sibling reports: [context-networking.md](context-networking.md), [nooa.md](nooa.md), [prime-agent.md](prime-agent.md), [fx.md](fx.md), [pi.md](pi.md), [deepseek-harness.md](deepseek-harness.md), [arcee-nac.md](arcee-nac.md), [unreal-agent.md](unreal-agent.md), [no-compaction-approaches.md](no-compaction-approaches.md), [benchmarks.md](benchmarks.md). Harness code citations are repo-relative paths as recorded in those reports.

baton (working tree at HEAD `1e050e420a99d775d3d2f943453c23535a701fd9`, 2026-09-22): docs/33-shared-objects-repl-layer.md (§3.3 settled-only resolution and §93.5/attention read semantics; §6 non-goals); docs/32-reflexive-orchestration.md §3.3 (ContextPackage); docs/34 (knowledge horizons); docs/35 (turn checkpoints); impl/src/limits.mjs, application.mjs, coordination-store.mjs (`mintMemberBoardGrant`), coordination-admission.mjs, coordination-internals.mjs (scope-fence projection caches) — as cited in [context-networking.md](context-networking.md) §2-3.

Concurrency and durability prior art (all read 2026-10-16):

- D. P. Reed, *Naming and Synchronization in a Decentralized Computer System*, MIT-LCS-TR-205, 1978 — http://www.bitsavers.org/pdf/mit/lcs/tr/MIT-LCS-TR-205.pdf
- H. Berenson et al., *A Critique of ANSI SQL Isolation Levels*, SIGMOD 1995 — https://arxiv.org/abs/cs/0701157 (https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/tr-95-51.pdf)
- J. Armstrong, *Making reliable distributed systems in the presence of software errors*, KTH 2003 — https://erlang.org/download/armstrong_thesis_2003.pdf
- `erlang:hibernate/3`, ERTS reference — https://www.erlang.org/doc/apps/erts/erlang.html
- Temporal, *Event History* — https://docs.temporal.io/encyclopedia/event-history
- Azure Durable Task Framework, programming model overview — https://learn.microsoft.com/en-us/azure/durable-task/common/programming-model-overview
- K. Li and P. Hudak, *Memory Coherence in Shared Virtual Memory Systems*, ACM TOCS 1989 — http://css.csail.mit.edu/6.824/2014/papers/li-dsm.pdf
- S. Eggers and R. Katz, *A Characterization of Sharing in Parallel Programs and Its Application to Coherency Protocol Evaluation*, ISCA 1988 — https://homes.cs.washington.edu/~eggers/Research/coherency.html
- P. Keleher, A. Cox, S. Dwarkadas, W. Zwaenepoel, *TreadMarks: Distributed Shared Memory on Standard Workstations and Operating Systems*, USENIX Winter 1994 — https://cseweb.ucsd.edu/classes/sp11/cse223b/papers/keleher94.pdf
- C. Ellis and S. Gibbs, *Concurrency Control in Groupware Systems*, SIGMOD 1989 — https://grouplab.cpsc.ucalgary.ca/grouplab/uploads/Publications/Publications/1994-Concurrency.Report94-534-03.pdf
- *Operational Transformation whitepaper*, Wave Protocol (Wang, Mah, Lassen) — https://www.waveprotocol.org/whitepapers/operational-transform-whitepaper
- M. Shapiro, N. Preguiça, C. Baquero, M. Zawirski, *Conflict-Free Replicated Data Types*, SSS 2011 — https://inria.hal.science/inria-00555588 (arXiv companion: https://arxiv.org/abs/1805.06358)
- L. Erman, F. Hayes-Roth, V. Lesser, D. Raj Reddy, *The Hearsay-II Speech-Understanding System*, ACM Computing Surveys 12(2), 1980; H. P. Nii, *Blackboard Systems*, AI Magazine 1986 — https://ojs.aaai.org/aimagazine/index.php/aimagazine/article/view/548

Budgeting and retrieval prior art:

- P. Pirolli and S. Card, *Information Foraging*, Psychological Review 106(4), 1999 — https://doi.org/10.1037/0033-295X.106.4.643
- P. Lewis et al., *Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks*, NeurIPS 2020 — https://arxiv.org/abs/2005.11401
- Anthropic, *Effective context engineering for AI agents* (2025-09-29) — https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- Stripe, *Rate limits* — https://docs.stripe.com/rate-limits
- G. Heinanen and R. Guerin, *A Two Rate Three Color Marker*, RFC 2698 (and *A Single Rate Three Color Marker*, RFC 2697) — https://www.rfc-editor.org/rfc/rfc2698
