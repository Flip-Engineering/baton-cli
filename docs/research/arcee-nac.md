# Arcee NAC: orchestrator, threads, and episodes as persistent state

Repo: https://github.com/arcee-ai/nac, shallow clone at `/tmp/baton-cli-research/nac`, HEAD
`e02ab92868de84ab2bb8edf03cfca77e2cd4f4d5` (dev branch, 2026-10-15, "fix(dev): scope monitor mode to
process launches (#379)"). Version 0.1.4 (`version.txt`; CHANGELOG says the product releases as one
version, internal crate versions are not public). Rust workspace, Apache-2.0, seven crates
(`nac-core`, `nac-server` with a React web client, `nac-process`, `nac-managed`, `nac-contracts`,
`nac-credential-store`, `nac-catalog-gen`), 1,810 tracked files. All path citations below are
repo-relative at that HEAD.

## 1. What NAC is, and what the name is

The [blog post](https://arcee.ai/blog/nac) ("Introducing NAC, an Open-Source Harness for Long-Running
Agent Work", Arcee AI Team — Brett Larsen, Lucas Atkins, Varun Singh, 2026-08-13) positions nac as a
harness the company built for its own long-running work: experiments, training-run supervision,
infrastructure, prototyping. The GitHub description: "Give AI agents ambitious work without losing
the plot" (repo metadata read via the github device, 2026-10-16; 283 stars, topics include
agent-harness, long-running-agents, multi-agent-systems, mcp).

The name is not expanded anywhere in the primary sources. The README, the blog, the root `AGENTS.md`,
the CHANGELOG, and the docs consistently write "nac"/"NAC" as an unanalyzed name. Third-party pages
offer expansions, but the one circulating (an "N = orchestrator, A = threads, C = episodes" reading
on an AI-generated wiki and an aggregator echoing it) is not present in the blog it cites, and its
letter-to-term mapping does not even match the words it claims to expand. Treated here as: expansion
unknown, name only.

Claimed architecture (README.md:21, blog): a thread-and-episode design inspired by Random Labs'
[Slate report](https://randomlabs.ai/blog/slate) (March 2026), with additional credit to
[nanocode](https://github.com/1rgs/nanocode) and [pi](https://github.com/badlogic/pi-mono) — the same
pi covered in [pi.md](pi.md). The blog's own framing is that harnesses are becoming "inference
runtimes": systems that own context construction, inference scheduling, effect execution, state
preservation, capability enforcement, and synchronization semantics, rather than thin model-tool
loops. Its mapping: "worker invocation = inference operation, thread = persistent program state,
episode = committed workstream update, source thread = data dependency, dispatch batch = dynamic
execution graph."

## 2. The core loop, verified in code

The orchestrator/worker split is enforced structurally, not just prompted:

- The orchestrator session gets exactly eight tools — `thread`, `threads`, `thread_read`,
  `thread_delete`, `workset_define`, `workset_read`, `workset_list` (the eighth slot is the dispatch
  shape; the tool set is fixed in `crates/nac-core/src/tools/mod.rs:136-180` and the orchestrator
  prompt enumerates the same set, `crates/nac-core/src/agent/prompts/nac_orchestrator.md`). It has no
  `read`, `edit`, `write`, or `exec_command`: the prompt's "You cannot read, write, or edit files
  directly" is backed by the tool registry, not by instruction alone.
- `thread(name, action, threads?, skills?, timeout?)` dispatches a worker as a genuinely fresh OS
  process: `run_worker` builds `Command::new(executable).arg("__worker")` with session/thread/
  dispatch ids, store path, and workspace cwd (`crates/nac-core/src/tools/thread/worker.rs:238`),
  matching the blog's "fresh process and model context" claim.
- The fresh worker's entire model context is: the worker system prompt (`prompts/nac_worker.md`), the
  requested action, the target thread's retained episodes, the latest retained episode of each named
  source thread ("thread weaving"), and any preloaded skills as system messages
  (`crates/nac-core/src/worker.rs:33-64`, `crates/nac-core/src/store/threads.rs:86`
  `load_worker_context`). There is no summarization pass — the worker's *final response, whatever it
  is, becomes the next retained episode*, committed to SQLite with `EpisodeStatus::Ok/Error`
  (`store/threads.rs:17-32`). Episodes are model-written handoffs; the prompt dictates the shape but
  nothing structural is extracted.
- The worker's execution context is then discarded — the code never reloads a worker transcript; only
  episodes persist. This is the load-bearing move: state passes between dispatches by value, in
  episode form.
- Batching and the DAG. One orchestrator turn may emit multiple `thread` calls;
  `crates/nac-core/src/agent/dag.rs` partitions the turn's tool calls (thread dispatches, other tool
  calls, parse errors), validates acyclicity and duplicate targets, and executes thread dispatches in
  topological waves on a tokio `JoinSet`; independent dispatches run concurrently, same-batch source
  threads are dependency edges, and a prior-batch source thread only supplies context. Non-thread
  tool calls run concurrently in a separate `JoinSet` alongside all waves (`dag.rs:265-337`). A
  thread already running is rejected rather than queued (`dag.rs:367-387`).
- Default thread timeout 3,600 s, minimum 1,800 s (`tools/thread/mod.rs:17`, dispatch tool doc at
  `tools/thread/mod.rs:99`, orchestrator prompt). The orchestrator waits for the whole batch before
  planning again — a synchronization point per planning step, per the blog.
- Failure is explicitly non-transactional: if a worker mutates the environment and dies before
  emitting its final response, the mutations remain with no episode. Failed dispatches get
  error-status episodes; dependent same-batch dispatches whose sources failed are skipped (blog;
  error episode path in `store/threads.rs`).
- Steering while a run is active is queued, not injected: instructions land in a `thread_steering`
  table with status `queued` and are claimed at the next model-call boundary
  (`crates/nac-core/src/store/steering.rs:41-118`), matching the blog's "queues it for the
  orchestrator's next model call." The queue takes a `dispatch_id`, so steering is addressed
  per-thread as well as at the orchestrator level.

## 3. Session behaviors: one binary, three topologies

`docs/usage/session-behaviors.md` documents three immutable per-session behaviors; the shipped web UI
defaults to direct-only, with orchestration restored via `NAC_ORCHESTRATION=1`:

- `orchestrator` — the thread/episode topology above. Remains the default when a legacy database row
  or API client omits the behavior field.
- `direct` — a persistent single-session coding agent: 15 tools (`DIRECT_TOOL_NAMES`: read/write/
  edit/glob/grep/exec_command/write_stdin/read_command_output/list_executions, the three goal tools,
  and subagent/subagent_status/subagent_cancel), durable goals, traditional child sessions.
- `direct-with-orchestrator` — direct plus six native controls (`orchestrator_launch/status/steer/
  read/wait/cancel`, `ORCHESTRATOR_CONTROL_TOOL_NAMES`, 21 total) for launching separate managed
  orchestrator sessions. At most four managed orchestrators per parent; children cannot launch
  orchestrators; behavior cannot be switched after creation (`docs/usage/managed-orchestrators.md`);
  completion is delivered to the parent through a durable, exactly-once inbox queue
  (`store/session_inbox.rs`).

Traditional subagents (direct mode) are durable child sessions: fresh context per launch or
continuation by child id, max four concurrent, no recursion, shared workspace with
revision-conflict reconciliation instead of overwrite (`prompts/nac_direct_child.md`,
`docs/usage/session-behaviors.md`). The worker and direct prompts both mandate native discovery tools
over shell equivalents and a revision-checked `read`/`edit`/`write` protocol where a
`stale_revision` error forces re-reading and re-planning the whole mutation — an
optimistic-concurrency scheme over file revisions, shared across sessions that touch the same
workspace (`prompts/nac_worker.md`, `prompts/nac_direct.md`).

## 4. Context management and the no-compaction posture

NAC's relation to the compaction problem is architectural first, mechanical second:

- **Workers never compact because they never need to.** A dispatch is bounded by construction, and
  worker runtimes are built with `orchestrator_compaction_threshold: None`
  (`crates/nac-core/src/worker.rs:228,449`). The long-horizon state problem is solved by episodes,
  not by history management: this is the "move the projection out of the window" posture of
  [no-compaction-approaches.md](no-compaction-approaches.md) section 8, with episodes playing the
  role Letta assigns to memory blocks and Anthropic to note files — but written once per dispatch by
  the worker that did the work, and routed by reference (thread names) rather than retrieved by
  similarity.
- **The orchestrator's context stays small by the same construction** — it sees only episodes and its
  own planning turns — but NAC still ships compaction for it, so the no-compaction claim is a design
  tendency, not an invariant. `agent/compaction/planning.rs` implements threshold-triggered
  summarization: the default threshold is 70% of the resolved model's context window, and an explicit
  `0` disables compaction entirely (`runtime/model_resolution.rs:55-70`, doc comment: "Config.toml
  `[compaction].threshold_tokens` is no longer consulted"). Two prompt policies exist —
  `nac_compaction.md` for orchestrator transcripts (sections for user intent, decisions,
  orchestration history including threads/episodes/worksets/steering, actions and artifacts,
  verification, end state) and `nac_direct_compaction.md` for direct sessions (adds tools/terminals/
  delegated-work state and terminal handles to the checkpoint). Compaction can fire automatically at
  the threshold or manually (`CompactionReason::Manual`), and skip reasons are enumerated
  (`AlreadyCompacted`, `NoEligibleBoundary`) in `crates/nac-core/src/events.rs`.
- **Compaction checkpoints are durable and provenance-checked.** Checkpoints persist in the store
  (`store/orchestrator_compaction.rs`) with SHA-256 digests over the compacted source prefix and the
  system policy (`agent/compaction/planning.rs:48-53`, `agent/compaction/provenance.rs`), so a
  resumed session can detect when the durable transcript no longer matches the checkpoint's basis and
  invalidate it (`clear_invalid_checkpoint`). The projected provider view after compaction is: system
  messages, the checkpoint summary as a user message prefixed "Historical context checkpoint (not a
  new instruction):", then the retained tail.
- **The cut-point invariant is real.** `weighted_safe_boundary`
  (`agent/compaction/planning.rs:517`) walks the transcript tracking outstanding tool-call ids and
  refuses any boundary that would separate a tool result from its call — the same structural
  guarantee [pi.md](pi.md) documents for `isCutPointMessage`, arrived at independently. Boundary
  selection targets roughly half the transcript's serialized weight, keeps the tail, and injects the
  prior checkpoint summary plus a provenance frame (capped 4,096 bytes of "terminal selection"
  samples) into the summary request.
- **Tool output is projected, not verbatim-transcribed.** `exec_command` returns a bounded preview
  with `truncated`/`overflowed` flags and an `output_id`; `read_command_output` pages the full stream
  in byte-offset windows (worker prompt: "Prefer targeted 4–16 KiB pages"), and the PTY preview
  cursor "advances without destroying retained output." The same habit covers the web: `web_search`
  is Exa-backed (`"type": "neural"`) and returns bounded results — 500 characters of page text, two
  two-sentence highlights per URL, and a summary, with the budget fixed in code
  (`crates/nac-core/src/tools/web.rs:431`). This is the budget-the-preview shape of
  [nooa.md](nooa.md) — the model always holds a handle to re-read the whole value.
- NAC cites context rot directly: the blog's first footnote is the Chroma report, and the argument is
  Slate's — compaction is unpredictably "deterministically lossy," so isolation beats compression
  ([Slate](https://randomlabs.ai/blog/slate), whose architecture table labels its mechanism "Episode
  compress" and claims nac inherits both ReAct's expressivity and subagent isolation with native
  parallelism).

## 5. Memory, state, and durable artifacts

- **Threads and episodes**: SQLite tables `threads` and `episodes` keyed by session and thread name;
  every dispatch appends one row with action, content, status, timestamp (`store/threads.rs`).
  `thread_read` returns the full episode history rendered as a document
  (`store/render.rs`/`render_thread_document`); `threads` lists names with episode counts and
  timestamps.
- **Worksets**: a declarative durable plan object — id, goal, status, summary, verification recipe,
  ordered items with scope/role/depends_on/acceptance/notes (`prompts/nac_orchestrator.md`,
  `store/worksets.rs`). This is the same move as Anthropic's initializer-agent feature list
  (documented in no-compaction-approaches.md §2) promoted to a runtime schema rather than a markdown
  convention. The orchestrator prompt explicitly forbids extra markdown notes files, channeling
  durable state into worksets and episodes instead.
- **Durable goals** (direct mode): `create_goal`/`get_goal`/`update_goal` with optional token
  budgets, run settlement, and user-owned pause/resume; an active goal continues across ordinary
  completed turns, and the agent is prompted never to claim a status change the tool did not confirm
  (`crates/nac-core/src/goals.rs`, `store/session_goals.rs`, `docs/usage/direct-goals.md`).
- **Skills**: a registry workers receive only by orchestrator preload at dispatch time — workers
  cannot activate skills mid-run (`worker.rs:53-64` `build_preloaded_skill_messages`). Project
  skills resolve against the nearest `.git` ancestor (`docs/usage/skills.md`).
- There is no separate memory service, no vector store, no sleep-time consolidation pass. Standing
  knowledge lives in the episode history and worksets; "memory" is the store plus the orchestrator's
  judgment about which episodes to route. The orchestrator prompt casts it as communication bridge:
  when one thread's episode surfaces a finding relevant to another, the orchestrator re-dispatches
  with the discovering thread as source.

## 6. Persistence, concurrency, and streaming

- **Store**: embedded SQLite in WAL mode; one serving `nac-web` process owns one canonical store
  path for its lifetime, enforced by a crash-safe OS file lock acquired before migration or listener
  binding (`docs/architecture/0004-persistence-ownership.md`). All mutations go through a
  `StoreCoordinator` on a dedicated persistence thread with typed closed commands, a bounded queue
  (128 waiting + 1 executing, overload fails fast), global FIFO ordering, and no arbitrary-SQL escape
  hatch. The ADR cites a managed incident (ALL-106: SQLite short reads, a transcript-append gap,
  probe starvation with four orchestrators running) as its motivation.
- **Transcript durability**: an append-only transcript log with recovery on resume —
  `restore_messages_merging_log_tail`, dangling-tail normalization, cancellation markers that
  preserve pending tool calls (`agent/mod.rs:1201-1660`). Crash-window contracts have a dedicated
  test lane (`make test-durability`, README).
- **Session lifecycle**: sessions snapshot their run state, token usages, backend and sandbox/SSH
  configuration into durable records (`sessions/snapshot.rs`, `runtime/builders.rs`); resume reads
  the snapshot rather than re-resolving configuration (`runtime/resume.rs:493`); session forks keep
  durable lineage links (`store/session_forks.rs:19-107`).
- **Streaming**: provider responses stream over SSE for both chat-completions and Responses backends
  (`model/chat_stream.rs`, `model/responses_stream.rs`, `model/sse.rs`), with a fold that rebuilds a
  canonical response from chunks so the durable transcript matches what a non-streaming provider
  would have sent.
- **Execution surfaces**: local, SSH, and sandboxed backends (`docs/usage/sandbox.md`,
  `nac-process` crate, `agent/sandbox/`), plus a managed-host deployment mode (`nac-managed`,
  `docs/managed/`) with bootstrap, telemetry, and a deterministic 1/2/4-orchestrator load and fault
  scenario (`docs/managed/deterministic-load.md`).
- **MCP**: nac exposes an outgoing MCP server (rmcp 3.5) that lets an outer agent — the blog's
  "meta-orchestrator" pattern, likened to Thinking Machines' fast/slow interaction loop — dispatch,
  monitor, and steer nac jobs. The MCP surface deliberately exposes no file or shell tools; the same
  protocol-independent operations back the six native orchestrator-control tools
  (`crates/nac-core/src/mcp/`, blog).

## 7. Capability enforcement and permissions

Permission enforcement is a dedicated subsystem, not a prompt rule. The direct prompt states the
model-facing contract: "NAC authorizes prepared tool operations immediately before execution... a
headless run fails closed when approval is required... a permission-denied tool result means the
operation did not execute: do not describe its side effects as completed" (`prompts/nac_direct.md`).
The implementation lives in `crates/nac-core/src/permissions/` as an eleven-file module: a broker,
shell-command classification with a shell parser, hard and opaque policy layers, resource binding
and projection, and approval modes (`permissions/broker.rs`, `command_classification.rs`,
`hard_policy.rs`, `shell_parser.rs`). Terminal input is deliberately constrained: model-driven
terminal input is unavailable because "a terminal program can reinterpret later input as an
unauthorized shell command," and a human-owned PTY accepts agent input only after the user explicitly
chooses "Give agent" on that process id — invocation-only approval that cannot create a reusable
grant (`prompts/nac_direct.md`). Permission grants persist per session, and child sessions carry
their own remembered grants.

## 8. Model support

Multi-provider by design, with Arcee's own stack as the recommended path. `BackendKind`
(`model/types.rs:6-24`): `deepseek-chat`, `fireworks-chat`, `together-chat`, `openai-responses`,
`openai-chat-completions`, `chatgpt-codex-responses` (ChatGPT OAuth login), `anthropic-messages`,
`arcee-auth` (device-code login to Arcee's Open Model API), `arcee-api`. Provider discovery doubles
as key validation — the models-listing request fails on a bad key (`model/providers.rs`). A
per-session optional **light model** setting is stored with the session for "weight-classified
dispatch" in orchestrator runtimes and is inherited by managed orchestrators (`light_model.rs:1-27`,
`docs/usage/managed-orchestrators.md`) — a cheaper model class for some worker role, though
direct-session light-model execution is explicitly deferred pending an internal ticket (ALL-36,
noted in the `light_model.rs` doc comment). Worker model and credential selectors are passed to the
worker subprocess as arguments; native credentials are stripped from the worker's environment
(`tools/thread/worker.rs:244-260`).

## 9. Evidence posture: verified in code vs. claimed elsewhere

Verified in code at HEAD: the eight-tool orchestrator boundary; worker dispatch as a fresh
`__worker` subprocess; worker context assembled from retained + source episodes only;
final-response-as-episode commit with status; DAG waves and thread mutual exclusion; the steering
queue table; the compaction threshold default, cut-point invariant, and persisted provenance digests;
the SQLite WAL single-owner store with bounded coordinator; the three behavior/tool-name sets; the
nine backends; the Exa search projection; the revision-checked file-mutation protocol.

Blog-only or unverifiable from the repo: the "sessions extending over days" claim (illustrated with a
launch-video timelapse, not a log) and the design's effectiveness — the blog is a design narrative
with no ablations, no benchmark tables, and no task-level numbers. No benchmark evidence of any kind
was found in the repo or blog; the repo's test suites are engineering-regression tests (E2E browser,
crash-window durability, the deterministic managed-load scenario), not agent-quality benchmarks.
Slate's architecture table is Random Labs' self-assessment, and nac publishes no independent
measurements of the claims it inherits.

## 10. Failure modes and limits

- **Episode quality is the whole system.** A weak episode poisons the thread's entire downstream
  history; the orchestrator prompt acknowledges this ("Avoid dispatches that leave behind weak
  episodes") but nothing in the runtime measures or enforces episode quality. The blog's failure
  analysis of competing designs applies to nac's own seam.
- **Non-transactional worker failure**: environment mutations without a committed episode leave
  persistent history behind the true state; recovery depends on the next worker rediscovering reality
  (blog states this plainly; the compaction prompts instruct treating environment state as
  "observations" and noting when later changes "may have invalidated earlier verification").
- **The orchestrator's dependency on worker honesty**: it cannot verify worker claims directly (it
  has no environment tools), and the compaction prompt's insistence on distinguishing "worker
  reports" from "independently verified" evidence shows the authors see this as a live risk.
- **Batch-granularity synchronization**: the orchestrator waits for the full batch before replanning;
  a long thread delays steering and replanning for the whole batch, and per-thread steering reaches a
  worker only if the runtime claims it mid-dispatch.
- **Compaction still exists**, including for orchestrator transcripts, so NAC does not eliminate the
  lossy boundary the no-compaction survey tracks — it relocates most of the pressure to episode
  boundaries and keeps compaction as the fallback at a 70%-of-window threshold.
- **Orchestration is opt-in and partially hidden**: the shipped UI defaults to `direct` and hides the
  thread topology behind `NAC_ORCHESTRATION=1` (`docs/usage/session-behaviors.md`); light-model
  dispatch is deferred in direct sessions.
- **Unbounded episode growth**: `thread_delete` exists, but no compaction or consolidation of episode
  histories was found; a thread reused across a multi-day session accumulates every episode it ever
  produced, and each new worker receives all of them.

## 11. Relation to the sibling reports

- Against [nooa.md](nooa.md): the sharpest contrast in the set. NOOA keeps whole values live in one
  process and budgets the projection; NAC makes process death the unit of design — every worker's
  whole context dies per dispatch, and durability is the model-written episode. NOOA never serializes
  mid-session; NAC serializes at every dispatch boundary by definition. The two agree on one
  mechanism: bounded tool-output previews with handles for re-reading the full value.
- Against [fx.md](fx.md) and [deepseek-harness.md](deepseek-harness.md): those budget tool results at
  the boundary inside one continuing context; NAC's equivalent boundary is the episode itself, and
  the "searchable record" role is filled by thread names plus the orchestrator's routing judgment
  rather than a retrieval index. dsh's "model-visible means logged" invariant has a nac analogue at
  the store layer (the transcript log), but nac's central claim is precisely that the log is not the
  model's context.
- Against [pi.md](pi.md): NAC credits pi as an inspiration, and the compaction cut-point invariant is
  the concrete shared idea; but pi compacts one growing transcript, while NAC's workers never
  accumulate one.
- Against [prime-agent.md](prime-agent.md): both are fresh-context architectures — Prime's RLM
  harness re-invokes fresh sessions carrying external state; NAC's workers are fresh processes
  carrying episodes. NAC's distinguishing bet is that the persistent unit should be a *routed, named
  workstream* (thread) rather than a programmatically searchable space, and that the orchestrator
  should be tool-less for environment mutation — Slate's "judgment stays in tokens, invariants live
  in the runtime" carried to the capability layer.
- [no-compaction-harnesses.md](no-compaction-harnesses.md) should classify NAC under
  fresh-session/thread-dispatch harnesses with compaction retained as a fallback for its long-lived
  orchestrator and direct transcripts.

## 12. Open questions

- No public evaluation exists for NAC itself; whether episode-based handoffs beat a well-run
  single-context harness on comparable tasks is unmeasured anywhere — the blog and Slate both argue
  the design, and nobody has measured it.
- Episode authoring: the final response becomes the episode with no separate summarization pass, so
  nothing published covers how episode quality degrades under worker failure, near-completion
  timeouts (the 1,800 s floor implies long dispatches are expected), or steering mid-dispatch.
- The light model's "weight-classified dispatch" role is stored and plumbed but its consumer is
  deferred (ALL-36, code-comment documentation only), and whether the orchestrator ever routes older
  non-latest source episodes is unstated — `load_worker_context` takes only each source's latest.
- The "NAC" name expansion: unverified as of this writing; any expansion found in future primary
  sources (a talk, the docs site) should supersede this report's "name only" finding.

## Sources

- Repo: https://github.com/arcee-ai/nac (HEAD `e02ab92868de84ab2bb8edf03cfca77e2cd4f4d5`, cloned
  2026-10-16). Key files, all under `crates/nac-core/src`: `tools/mod.rs`; `agent/dag.rs`;
  `agent/compaction/planning.rs`; `agent/compaction/provenance.rs`; `agent/prompts/` (all six
  `nac_*.md` files); `store/threads.rs`; `store/steering.rs`; `store/session_forks.rs`;
  `store/worksets.rs`; `tools/thread/worker.rs`; `worker.rs`; `light_model.rs`; `model/types.rs`;
  `model/providers.rs`; `tools/web.rs`; `permissions/`; `runtime/model_resolution.rs`;
  `sessions/snapshot.rs`; plus `README.md`, `AGENTS.md`, `CHANGELOG.md`, `version.txt`.
- Arcee AI Team (Brett Larsen, Lucas Atkins, Varun Singh): [Introducing NAC, an Open-Source Harness
  for Long-Running Agent Work](https://arcee.ai/blog/nac), 2026-08-13.
- Random Labs: [Slate: moving beyond ReAct and RLM](https://randomlabs.ai/blog/slate), March 2026
  (thread-and-episode architecture, thread weaving, architecture comparison table).
- NAC docs (in-repo): `docs/usage/session-behaviors.md`; `docs/usage/managed-orchestrators.md`;
  `docs/usage/direct-goals.md`; `docs/usage/skills.md`; `docs/usage/sandbox.md`;
  `docs/architecture/0004-persistence-ownership.md`; `docs/managed/deterministic-load.md`.
- Sibling context: [no-compaction-approaches.md](no-compaction-approaches.md), [nooa.md](nooa.md),
  [fx.md](fx.md), [deepseek-harness.md](deepseek-harness.md), [pi.md](pi.md),
  [prime-agent.md](prime-agent.md), [no-compaction-harnesses.md](no-compaction-harnesses.md).
- GitHub repo metadata (description, stars, topics) read via the github device, 2026-10-16.
