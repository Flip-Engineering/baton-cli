# Unreal Agent: durability-first asynchronous tool execution

Unreal Agent is an open-source agent harness from Unreal Labs: a Go library (`harness/`) plus executables (`cmd/unreal-agent-runner` for headless runs, `cmd/unreal-agent-tui` for interactive use, and a Harbor benchmark agent in `benchmarks/harbor/`). It is MIT-licensed, and the repository is 25 days old at the analyzed commit. The vendor blog ([unreallabs.ai/blog/unreal-agent/](https://unreallabs.ai/blog/unreal-agent/), 2026-09-22) claims up to 40% cost savings versus Codex at equal benchmark pass rates, which it attributes to a completely asynchronous tool-calling model that removes waits, polls, and heartbeats from the model's token budget.

## 1. What the project is and claims to be

- Vendor claim (blog): an async-first harness that lets the agent issue tool calls without ever blocking on them, lets user steering arrive mid-flight, and wakes a turn for each tool result as it lands; the cost story is cached-prefix preservation plus "more tool work per model turn".
- Code reality: the architecture in `README.md` matches the implementation. The component table names seven parts (session inbox, coordinator, session store, context builder, LLM adapter, tool registry/translators, operation manager); each maps to a package under `harness/` with the responsibility the table states.
- Maturity: created 2026-09-21, four releases (v0.1.0 through v0.3.1, latest 2026-10-06), 2,202 stars, 12 open issues at analysis time. This is young but not a stub: the coordinator is exercised by integration, recovery, and fuzz tests, and the session format ships golden-file tests (`harness/sessionstore/localfile/testdata/`).
- Distribution: Homebrew tap (`unreallabsai/tap/unreal-agent`), `go install`, and Docker images (`cmd/unreal-agent-runner/README.md`).

## 2. Repository map, as measured

- HEAD `a5f3fd13032737142916523ae4344c392292f9d5` (2026-10-06, "Revise README with new install command"), shallow-cloned to `/tmp/baton-cli-research/unreal-agent`. All repo-relative paths below resolve at this commit; the blog post and the session-file fixtures are the other primary sources.
- Measured scale: ~55k lines of Go across `harness/` and `cmd/` (`third_party/` and codegen inputs excluded), 138 `*_test.go` files, 7 fuzz-test files.
- Non-test/test line counts by package, counted with `wc -l` at HEAD:
  - `harness/llm` 3,183 / 6,310; `harness/primitives` 2,749 / 7,234; `harness/operation` 2,232 / 4,378; `harness/sessionstore` 1,461 / 3,952; `harness/coordinator` 1,052 / 7,792; `harness/tool` 869 / 1,689; `harness/contextbuilder` 419 / 1,569; `harness/inbox` 214 / 438; `harness/settings` 116 / 228; `cmd/` 3,779 / 4,909.
- Test lines outnumber source lines roughly 2:1 overall. The durability contract rests on the two smallest packages (`inbox`, `contextbuilder` — 419 lines carrying staging, token checkpoints, and the full compaction rebuild). `harness/llm` is largest because it carries provider wire types generated from vendor OpenAPI specs (`internal/anthropicapi/generate.py`, `internal/openaiapi/generate.py`) with fixture-based SSE replay tests rather than hand-written transports (`harness/llm/messagesapi/testdata/`).

## 3. The harness loop: one single-writer event loop over an idempotent inbox

The core loop is `Coordinator.Run` (`harness/coordinator/loop.go:89`). It is a serial `select` over five event sources: inbox inputs, operation updates, a heartbeat timer, a tool-call grace timer, and completed model responses. Nothing mutates agent state outside this loop; tool translators run synchronously on it and "must not perform I/O or suspend the loop" (`README.md`, Glossary). The LLM request itself runs in a separate goroutine (`loop.go:407`), and only the fully normalized response re-enters the loop — a late, canceled, or superseded response is dropped by turn-ID comparison (`loop.go:171`).

Three properties distinguish this loop shape:

1. **Input idempotency.** Every input carries a caller-supplied globally unique ID stable across redeliveries (`README.md` Glossary; `harness/inbox/inbox.go:24`). The inbox deduplicates in memory per session (`inbox.go` "owns input deduplication for one session"); the runner derives message IDs from a client-supplied `message_id` field or falls back to a UUID (`cmd/internal/agentrunner/run.go:392-399`). Once accepted, an input is persisted to the session store before any processing (`handleInboxInput`, `loop.go:440`), so crash recovery replays it exactly once.
2. **Steering without waiting.** External inputs commit and increment `availableInputs` immediately (`addItemToLocalState`, `loop.go:598`); pending undelivered inputs trigger the next model turn the moment the current one drains (`processEvents`, `loop.go:215`). A steering message never queues behind a tool call.
3. **Batched delivery.** Newly arrived inputs and operation updates are drained in batches — up to `slurpMaxItems = 100` events per pass with a 1 ms idle cap (`loop.go:21-25`) — so results landing together enter the context in the same turn, which keeps the provider prefix stable between turns.

Stop semantics are control inputs in the same inbox: `StopHard` unwinds the session; `StopWhenIdle` exits only when no inputs and no operations are pending (`isIdle`, `loop.go:281`). The headless runner submits its prompt and then a `StopWhenIdle` control (`run.go:404`), so a one-shot run ends exactly when the task stops generating work. `UpdateSettings` control messages change model, compaction threshold, max output tokens, and reasoning effort mid-session, and invalidate the token checkpoints when the model changes (`builder.go:76-99`).

## 4. Tools and durable operations

The static tool surface is three tools: `Bash`, `ViewImage`, and `SkillUse` (`harness/tool/registry.go:17-21`). There are no file-edit primitives, no web tools, and no MCP client at HEAD; everything else is expected to run through Bash inside the workspace. Skills are markdown files with YAML frontmatter discovered from `.harness/skills/*/SKILL.md` (`DiscoverSkills`, `registry.go:192`); their names, descriptions, and paths are injected into the preamble as an XML list (`harness/contextbuilder/skills.go`). `SkillUse` is only enabled when skills are discovered (`cmd/unreal-agent-tui/run.go:248-251`).

A tool call becomes work in two stages. The translator validates arguments and submits one or more *operations* — serializable, versioned work values with status, state, and idempotency fields (`harness/operation/operation.go:21-47`) — and returns a `CallStatus` whose `WaitingFor` names the operation IDs. The operation manager (actor runtime, `harness/operation/local_manager.go`) executes them against *primitives* and streams back `Operation` state updates over a channel the coordinator selects on. Versioned, serializable operations make the dispatcher at-most-once across restarts; `README.md` sketches a proxy operations manager forwarding serialized operations into a remote sandbox, and the `RemoteJobHandler` interface (`harness/operation/remote_job.go:23-27`) with plan-type/version negotiation is the typed seam for that, though no remote job implementation ships at HEAD.

The primitive set (`harness/primitives/`) is where real I/O lives: `process` (streaming stdout/stderr with file-backed capture), `file` (file creation with platform-specific fsync), `compute` (off-thread CPU-heavy callbacks with panic and `runtime.Goexit` recovery), `remote` (HTTP with SSE streaming, retry/backoff, and idle timeouts, `remote.go:26`), and `timer`. Shell output is bounded — default `DefaultMaxOutputLength = 40_000` characters (`harness/operation/output.go:9`), overridable per call up to a hard `MaxOutputLength` cap (`harness/operation/shell.go:93`) — and overflow spills to capture files under the session's operations directory; the model receives the literal path ("Stdout capture: ..." at `harness/tool/bash/bash.go:69-73`) and must reopen it with Bash. This is file-spillover budgeting: the model-visible projection is capped, and the full body stays out of the context until demanded.

## 5. The async tool-call contract: running placeholder, then final result

The convention the whole architecture rests on: when a tool call is scheduled, the context builder immediately stages a tool result marked *running* with fixed placeholder text — "Tool call is still running. Its result arrives in a later turn: continue with independent work, or end your turn to wait for it." (`harness/contextbuilder/builder.go:16`). When the operation finishes, `AddToolResult` either replaces the running placeholder in place — if it is still in the uncommitted staged suffix — or appends a second result item for the same call ID (`builder.go:122-146`). The vendor blog's reference [2] names this explicitly: two tool-call result items (one in-progress, one final) in one context, a pattern they report as underspecified in the Responses API and rejected by some non-OpenAI providers. The replacement path keeps the common case to one item; the append path exists because a committed prefix is immutable.

Related control flow:

- Ending a turn with calls still running sets no timer and does nothing: the coordinator waits for operation updates (`isWaitingForOnlyToolCalls`, `loop.go:286`). As a backstop, a heartbeat control input is injected after `ToolHeartbeatInterval` (10 minutes by default in both executables, `cmd/internal/agentrunner/run.go:163`, `cmd/unreal-agent-tui/run.go:262`), rendered as an ordinary user message with the elapsed wait and running calls (`postHeartbeat`, `loop.go:310`).
- Two one-second grace windows (`toolCallRunGracePeriod`, `toolCallCompletionGracePeriod`, `loop.go:29-30`) delay the next model call briefly after scheduling calls or after a call completes with siblings still pending, to coalesce results that land nearly together into one turn.
- The preamble (`harness/contextbuilder/prompts/preamble.md`) teaches the model this contract directly: "Tool calls are asynchronous: each starts the moment you issue it... Ending a turn with no tool calls while calls are running means you sleep until one finishes; ending a turn with nothing running ends the session."
- An unavailable tool (call resolved to no translator after tool-set changes) gets an immediate error result rather than an operation (`toolCallRequiresTranslator`, `loop.go:566`; `harness/coordinator/unavailable_tool_test.go`).

There is no concurrency classification. Any number of tool calls from one response run concurrently by default; safety is delegated to the operation layer and, per the blog, to environment-level sandboxing rather than in-harness approvals.

## 6. Session persistence: an append-only, forking, crash-recoverable log

Sessions roundtrip through JSONL files named `<session-id>.session.jsonl` in `${XDG_STATE_HOME:-$HOME/.local/state}/unreal-agent/sessions/` (`harness/sessionstore/localfile/store.go:22`). Format details, verified in `codec.go` and the store:

- A header record (`type: "session"`, `formatVersion = 2`) followed by item records and operation records (`codec.go:14-27`). An unsupported version fails resume explicitly (`README.md` invariants; `testdata/legacy-session.session.jsonl` covers the upgrade path).
- Item kinds: `fork`, `input`, `turn`, `model_response`, `tool_call_status` (`harness/sessionstore/sessionstore.go:23-29`). Each item has a contiguous sequence number and recorded-at timestamp; the store validates both on append and load.
- Tool-call status and the operations it waits for are persisted atomically in one record (`itemRecord.Operations`), which closes the "translation succeeded, dispatch crashed?" replay window.
- Appends commit through a temporary file plus `fsync` and directory sync (`persistTemporary`, `syncDirectory`, `store.go:433-468`); sequence integrity is validated on write (`codec.go:45-53`).
- `Fork` creates a new session whose log copies the parent's history up to `PreviousTurnID` (`store.go:239`); the coordinator reconstructs in-memory tool-call and operation state from the log alone (`loadHistory`, `loop.go:550`; `ResumeState` carries unfinished operations and input IDs, `sessionstore.go:78-82`).
- Golden fixtures cover a regular session, a forked session, a soft-stop session, and the legacy format (`testdata/`).

The format is the crash-safety contract of the whole design, and the fuzz tests (`run_log_fuzz_test.go`, `coordinator_log_fuzz_test.go`, `fault_fuzz_test.go`) plus the no-seatbelt integration tests (`stop_integration_test.go`, `recovery_test.go`, `recovery_sequences_test.go`) exist to attack it. Together with versioned operations this is the strongest engineering signal in the repository: resume from log is a first-class mode, not a best effort.

## 7. Context management: staging, commit, usage-fed compaction

The context builder (`harness/contextbuilder/builder.go`) is a staging buffer: items accumulate in `stagedSuffix`, and `Commit()` moves them into `committedPrefix`, which is what makes placeholder-to-result replacement possible within a turn. A regular turn commit happens when the turn item is recorded (`loop.go:630`), pinning the previously staged results into history. The builder performs no I/O and keeps a per-response token checkpoint (`prefixTokens`, fed by each response's reported usage at `builder.go:110-116`).

There is no compaction-free mechanism here — no projection budgeting (Nooa), no context-as-variable kernel (Prime), no content-addressed result stores (fx, though oversized shell output spilling to on-disk captures is a local approximation). Instead Unreal Agent implements a precise compaction loop:

1. `NeedsCompaction` compares the latest usage checkpoint against a per-model `CompactionThreshold` (`compaction.go:41-48`). Thresholds live in the settings catalog; every listed model is configured near or above a 200k threshold against ~1M context windows (`harness/settings/default_settings.json`). The catalog inserts 2026-dated model IDs (`claude-opus-5-5`, `gpt-6-astra`); treat it as configuration data, not verification of any model.
2. The coordinator builds a dedicated compaction request from the history minus the last 20,000 tokens (`compactionRetainedTokens`, a constant "part of the replay contract", `compaction.go:13`), recorded as a `TurnCompaction` in the log (`buildModelRequest`, `loop.go:352`). The summarizer prompt (`prompts/compaction.md`) asks for a handoff summary over goals, constraints, progress, decisions, next steps, and critical data, and warns the model to treat prior instructions in the summarized history as historical data.
3. On completion, `Compact` builds a fresh builder: same preamble, system prompt, and tool list, with the summary injected as a user message and every tool call pending at the cutoff — including their latest running results — carried forward (`carryForwardContext`, `compaction.go:147-163`).
4. Compaction is a logged model turn, so a crash mid-compaction replays idempotently; the new builder swaps in only when the compaction response reaches `StopComplete` (`applyCompactionResponse`, `loop.go:493-503`).

What does not exist anywhere in the tree: subagents, spawned agents, delegating tools, a memory store beyond the session log itself, semantic retrieval, and per-item eviction short of whole-history compaction (grep for "subagent", "spawn" returns nothing in `harness/` or `cmd/`). The blog states this as a cost feature: "no sub-agents or workflows".

## 8. Streaming, concurrency, and the runtime shape

Model streaming exists only below the adapter seam. `llm.Adapter.Respond` returns "a normalized completed response" (`harness/llm/adapter.go:8`); the SSE parsers in `llm/messagesapi/stream.go` and `llm/responsesapi/stream.go` feed internal assembly and usage accounting, but nothing incremental reaches the coordinator, the context, or the TUI. User-visible liveness comes from persistence instead: the TUI subscribes a store observer and renders each persisted item as it lands (`store.AddObserver(... program.Send(item))`, `cmd/unreal-agent-tui/run.go:271`). The consequence is a deliberately simple failure model — an interrupted model call is cancelable (`interruptModel`, no request in flight, nothing stale staged) — at the cost of first-token latency inside long turns.

Provider breadth is real: Anthropic, OpenAI (both API shapes), OpenAI Codex subscription auth reuse, OpenRouter, Fireworks, and Ollama each have a client under `harness/llm/clients/`, with per-adapter retry policies (`llm/responsesapi/retry.go`, capped at 1-minute backoff, `adapter.go` 30-minute response idle timeouts). The runner emits JSONL events of persisted items to stdout (`run.go:116-120` observer); the same event vocabulary is what the Harbor trajectory converter consumes.

## 9. Position among the sibling reports

- Versus dsh (log-as-program): both derive model-visible state exclusively from an append-only log, and both make the log the replay contract. dsh composes the harness as interchangeable plugins and keeps the loop swappable; Unreal Agent fixes one coordinator with one loop shape and spends its abstraction budget on durability inputs instead — idempotent input IDs, atomic status-plus-operations records, fuzz-tested recovery. Unreal Agent's log is closer to an event-sourced runtime journal (it records operation state transitions, not just conversation); dsh's is closer to a session transcript with plugin-derived projections.
- Versus fx (budgeted-variable, safety-classified concurrency): fx classifies tool calls into read-only/subagent/host groups and runs a leading prefix concurrently until the first writer; Unreal Agent has no classification — every call is asynchronous and concurrent, with per-call output caps and file spillover doing the budgeting work fx does with result stores and handle paging. fx journals `tool_intent` before effects; Unreal persists the tool-call status together with its operations at translation time, a comparable intent-before-dispatch discipline placed one layer lower.
- Versus Prime (RLM kernel, context-as-variable): nothing comparable exists. The model never manipulates its own context programmatically; compaction is initiated by the harness from usage telemetry, not by the model. The only bounded-ingress nod is the 40k shell-output cap plus spillover captures.
- Versus Nooa (pass-by-reference, model-compaction via `collapse`): also absent by design. The closest relative is harness-side carry-forward of pending tool calls across compaction.

| Mechanism | Nooa | Prime | fx | dsh | Unreal Agent |
| --- | --- | --- | --- | --- | --- |
| Model manipulates its context programmatically | Yes (`collapse`, dynamic blocks) | Yes (kernel variables) | Partial (handle paging tools) | No | No |
| History reduction | Per-block eviction | Harness-side | Per-session rebuild | Log-derived projection | Whole-history summarize turn |
| Tool concurrency default | Model-authored within cells | Within REPL cells | Safety-classified prefix groups | Plugin-defined | Unlimited asynchronous calls, unclassified |
| Result-overrun handling | Preview fields with caps | Char-capped kernel output | Content-addressed result store | Plugin-specific | Length cap plus on-disk capture files |
| Crash model | Snapshot objects | Kernel snapshot | Effect journal with intents | Append-only event log | Idempotent inputs, versioned operations, log replay |

What is genuinely new in Unreal Agent relative to these siblings:

1. Tool-flex asynchronous execution as the default for every tool call, taught to the model through the preamble itself, with in-place placeholder-to-result replacement in the staging window (the two-item contract where replacement is impossible).
2. Input idempotency as the unit of steering: caller-supplied IDs, a dedup inbox, persisted-before-processing, so user and control messages survive crashes and redeliveries exactly once.
3. Compaction as a first-class, replayable turn type with a fixed 20k-token retained-tail contract and pending-tool-call carry-forward.
4. Versioned serializable operations with an at-most-once actor runtime, ready to be proxied into a remote sandbox — the cloud-execution seam is already in the type system (`RemoteJobHandler`).

## 10. Benchmark evidence

The vendor blog reports Harbor-based runs with GPT-6 Astra at xhigh reasoning (numbers below are vendor-reported; Harbor job IDs are linked in the blog):

| Benchmark | Unreal Agent | Codex baseline | Pi baseline |
| --- | --- | --- | --- |
| Terminal-Bench 4.0 | 57.9%, $1,428 total | 57.9%, $2,350 | 55.0%, $1,827 |
| SWE-Atlas Codebase QnA | 65.8%, $936 | 63.3%, $1,303 | 64.0%, $1,033 |
| DeepSWE 1.1 | 72.4%, $1,367 | 69.0%, $1,633 | 69.6%, $1,584 |
| ALE-CLI | 30.0% full pass, $217 | 29.0%, $292 | 29.0%, $262 |

The blog attributes the savings to fewer turns and fewer input tokens (1.73M input tokens per trial versus Pi's 2.83M on Terminal-Bench) and calls pass-rate deltas "benchmark variance". No arXiv paper, no independent replication, and no third-party leaderboard entry were found. What the repository itself substantiates: a complete Harbor agent (`benchmarks/harbor/`) that installs the runner into task environments, emits ATIF v1.7 trajectories (`trajectory.py:296`), and a smoke task (`tests/task/`) exercising Bash output, exit codes, and image viewing. Nothing in-repo regenerates the reported tables.

## 11. Verified in code versus claimed only

Verified against code at HEAD: the event-loop shape (§3), inbox idempotency (§3), the running-placeholder contract and its replacement rule (§5), compaction mechanics including the 20k-tail constant and carry-forward (§7), the absence of subagents (§7), the session format, atomic append, fork, and resume (§6), the three-tool surface plus skills (§4), output caps and spillover (§4), heartbeat defaults (§5), the completed-response-only adapter surface (§8), and the Harbor/ATIF integration (§10).

Blog-only or vendor-only: the cost-savings percentages and per-benchmark numbers (§10); the "up to 40% versus Codex, up to 20% versus Pi" headline; the attribution of savings to cache preservation and call batching; the provider-acceptance behavior for two-item tool results (blog note [2]), documented as vendor-tested but not reproducible from the repository.

## 12. Failure modes and limits

- Compaction is whole-history summarization with a lossy prompt; nothing structural protects long-lived facts. The 20,000-token retained tail is a constant baked into the replay contract (`compaction.go:12-13`), and thresholds are per-model catalog data.
- `NeedsCompaction` fires only when usage from the most recent response crosses the threshold; a single turn containing a large tool-burst can overshoot before compaction has any admission point.
- Token accounting uses provider-reported input-plus-output tokens as a proxy for prefix size (`builder.go:112`); provider reporting differences shift the trigger point.
- An acknowledged bug marks the fork path: "FIXME: Forks leave inherited calls without results and retain pending-input accounting" (`loop.go:593-596`).
- Session files are append-only JSONL with no rotation, on-disk compaction, or size bound; long sessions grow unboundedly on disk even as the context compacts.
- The two-item result contract is provider-dependent: the vendor reports rejections on some non-OpenAI providers (blog note [2]), which places part of the core async pattern's portability outside the harness's control.
- Security has no in-harness model: no permission checks, approvals, or allowlists exist in the tool path; the blog explicitly positions determinism-style sandboxing and approval-gated proxies outside the harness. Adopting it means owning that responsibility.
- `LocalOperationManager` treats unregistered operation types as unsupported (`operation.ErrUnsupported`), so portability of a session across executor swaps limits itself to the shared operation vocabulary.

## 13. Open questions

- Is the 20k-token retained tail tuned to any particular cache-segment boundary, or chosen as a conservative constant? No comment or test derives it.
- Does the placeholder-to-result replacement path dominate in practice, or do most results append a second item? The grace windows suggest replacement is meant to be common; no in-repo telemetry exists.
- How do the Harbor benchmark trials configure steering and idle-stop, and do the reported turn counts come from a configuration equivalent to the shipped defaults?
- What fraction of the claimed 40% saving comes from prompt-cache preservation rather than fewer turns? The blog names both factors but does not decompose them.
- No remote job implementation ships against `RemoteJobHandler`; is the cloud runner surface planned to consume it at HEAD-plus?
- When a tool result arrives after a compaction swap, does `AddToolResult` land correctly against the carried-forward pending call? `compaction_test.go` covers rebuilds; the post-swap completion recurrence is not pinned by any test named in the tree.

## Sources

- Repository, HEAD `a5f3fd13032737142916523ae4344c392292f9d5` (2026-10-06): https://github.com/unreallabsai/unreal-agent (shallow clone; repo-relative paths resolve at this commit)
- Vendor blog announcing the harness with benchmark tables: https://unreallabs.ai/blog/unreal-agent/ (2026-09-22)
- Session store fixtures and recovery tests read directly from the clone: `harness/sessionstore/localfile/testdata/`, `harness/coordinator/*_test.go`
- Aggregator corroboration (secondary, lower weight): https://ai-tldr.dev/releases/unreallabs-unreal-agent/, https://huuush.com/en/blog/development-automation/unreal-agent-harness-cut-agent-costs-39-percent
- No arXiv publications found for the project or the org as of 2026-10-16.