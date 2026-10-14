# Pi: code-analysis deep-dive for baton-cli design

Pi (originally `pi-mono` by Mario Zechner, now `earendil-works/pi`) is a TypeScript monorepo whose packages compose a minimal coding agent harness out of a provider seam, a stateful agent loop, an event-tree session format, a retained-mode TUI, and — newest — a durable-execution harness. This report is grounded in a code read of the repository at shallow-clone commit `b06c1f2cf1dea6af8748ddeee18c23587d2cb7c6` (HEAD of `main` via the `badlogic/pi-mono` redirect, 2026-10-14), with the 2025-11-30 writeup and current docs as secondary sources. Claims cite repo-relative source paths; where the writeup or docs have drifted from code, the drift is stated in a corrections register (section 12).

For baton-cli, the load-bearing finding is that Pi now contains two architectures for the same problem: the coding-agent's single-process event-tree session, and `pi-durable`'s committed task graph over pluggable storage. The second is the closer match for an orchestrator that must resume seats across process boundaries; the first remains the best reference for a minimal tool surface and a documented session format.

## 1. Repository status

- Repository: https://github.com/earendil-works/pi (badlogic/pi-mono redirects here), MIT. Packages: `agent`, `ai`, `chord`, `codemode`, `coding-agent`, `durable`, `env`, `evals`, `mcp`, `telemetry`, `tui` (verified from the clone).
- Engines: `node >=22.19.0` in `packages/coding-agent/package.json` and `packages/agent/package.json`.
- The foundational writeup is Mario Zechner's post of 2025-11-30: https://mariozechner.at/posts/2025-11-30-pi-coding-agent/. It predates several features (compaction, MCP, codemode, tool-result streaming, the durable harness); it is cited as historical evidence only.

## 2. Package boundaries

| Package | Owns (verified from source tree) |
|---|---|
| `packages/ai` | Provider adapters, stream events, tool-call types, transcript replay helpers, model catalog (`models.generated.ts`), auth/credential resolution, `EventStream` primitive |
| `packages/agent` | `agent-loop.ts` (the loop), `agent.ts` (stateful `Agent` class), `proxy.ts` (transport), queue types |
| `packages/tui` | Retained-mode component framework: `tui.ts`, `tui-main-screen.ts` (scrollback renderer), `tui-alt-screen.ts`, editor/autocomplete/markdown components |
| `packages/coding-agent` | The `pi` CLI: sessions, built-in tools, extension runtime, compaction, JSON/print/RPC/SDK modes |
| `packages/durable` | Durable harness: session kernel (`session/`), task scheduler, generation/tool/compaction tasks, inbox, storage backends (memory/JSONL/SQLite/Cloudflare) |
| `packages/chord` | Distributed object layer: contracts, hosts, observable replicated JSON state, delta encoding (its README: "objects that live in several processes and can be hot reloaded") |
| `packages/codemode` | QuickJS-WASM sandbox running model-written scripts that call tools (`quickjs-wasi` import in `packages/codemode/src/cloudflare.ts`) |
| `packages/mcp` | MCP server connections wrapped as agent tools |
| `packages/env` | Execution-environment abstractions (serves `pi-durable`'s per-call environments) |
| `packages/evals`, `packages/telemetry` | Support packages (not analyzed) |

Boundary concept: each layer knows only the layer below it and nothing sideways — `pi-ai` has no agent code (the writeup's claim that the loop lived at `packages/ai/src/agent/agent-loop.ts` is stale; the loop now lives in `packages/agent/src/agent-loop.ts`), and `pi-agent-core` has no filesystem or terminal code. Everything that touches files, sessions, or screens lives in the two application packages.

## 3. Provider layer: one adapter seam over four wire APIs

Pattern: a narrow adapter seam that normalizes four upstream wire APIs (OpenAI Completions, OpenAI Responses, Anthropic Messages, Google Generative AI) plus a long tail of branded endpoints into one event stream; provider quirks are absorbed inside `packages/ai/src/providers/*.ts` and `packages/ai/src/api/*.ts` (the `src/api/` directory holds ~30 endpoint implementations including `anthropic-messages.ts`, `openai-completions.ts`, `bedrock-converse-stream.ts`, `mistral-conversations.ts`).

Verified properties:

- Stream events are a closed union with `text_delta`, `thinking_delta`, `toolcall_start/delta/end` (`packages/ai/src/types.ts`); the assistant-level `StopReason` is `"pending" | "stop" | "length" | "toolUse" | "error" | "aborted" | "deferred"` (`packages/ai/src/types.ts:474`). Aborts surface as partial results, per the writeup.
- `sessionId` is a stream option forwarded for provider-side session/cache affinity (`packages/ai/src/types.ts`, `SimpleStreamOptions`).
- The model registry is generated from the OpenRouter and models.dev catalogs into `packages/ai/src/models.generated.ts` (`openrouter.models.ts` import at the head of that file); custom/self-hosted models are plain `Model` records.
- Transcript replay lives in `packages/ai/src/utils/transcript.ts`: `normalizeContext` materializes the initial system message, `getCurrentTools` folds `toolsRemoved`/`toolsAdded` across system messages in order, `getCurrentSystemMessage` rebuilds the current prompt (sections patched by name) from any message array.
- The abort/partial-result and split tool-result (`content` for the model, `details` for the UI) designs are in `packages/ai/src/types.ts` (`ToolResultMessage`, `AgentToolResult`-equivalents) and are exercised by a large per-provider test suite (`packages/ai/test/` has ~30+ provider-specific test files such as `abort.test.ts`, `anthropic-eager-tool-input-e2e.test.ts`).

## 4. Agent loop: the turn as the unit of consistency

Pattern: an event-sourced loop whose unit of work is the turn — one assistant response plus its complete tool-result batch — with all control decisions expressed as awaited hook calls between events. Source: `packages/agent/src/agent-loop.ts` (949 lines) and `packages/agent/src/agent.ts` (613 lines).

Control flow, as implemented (`runLoop` in `agent-loop.ts`):

1. Outer loop over runs; inner loop over turns. Each turn: poll steering (`getSteeringMessages`), run `prepareNextTurn` (compaction/loadout hook), emit `turn_start`, inject pending/prepared messages, run `prepareRequest`, stream the assistant response, execute tool calls, run `finishTurn`, emit `turn_end`.
2. Error/aborted responses are hard exits: `finishTurn` runs, then `turn_end` and `agent_end` fire and the loop returns (explicit code path at `agent-loop.ts` for `stopReason === "error" || "aborted"`).
3. `stopReason === "length"` (output token limit) never executes tool calls: `failToolCallsFromTruncatedMessage` fails every call with an error result telling the model to re-issue with complete arguments, on the reasoning that streamed tool arguments are salvaged by a best-effort JSON parser and may be silently incomplete (`agent-loop.ts`).
4. `finishTurn` returning `{ action: "end" }` stops after `turn_end` without polling queues; `{ action: "continue" }` guarantees one more request, satisfied by ordinary scheduling when possible, else one context-only turn (`agent-loop.ts`, `explicitContinuation`).
5. Follow-up messages are polled only when the agent would otherwise stop; steering is polled at loop start (messages typed while waiting) and after every turn (`agent-loop.ts`).

Tool-call representation and persistence order (`executeToolCalls`, `agent-loop.ts`):

- Tool calls are content blocks on the assistant message (`message.content.filter(c => c.type === "toolCall")`); tool results are `toolResult` messages pushed into the transcript.
- Parallel mode (default): preflight is sequential — for each call, `prepareToolCall` (argument validation + `beforeToolCall` hook) runs one at a time — then executions run concurrently via pushed thunks and `Promise.all`. `tool_execution_end` is emitted per tool at its own completion time; the persisted `toolResult` messages are emitted afterward in assistant source order (the `orderedFinalizedCalls` loop).
- Sequential mode: everything one at a time, result messages emitted immediately per call.
- A per-tool `executionMode: "sequential"` forces the entire batch sequential (`hasSequentialToolCall`).
- Concurrency is unbounded: no cap on the number of concurrent tool executions in a batch.
- Batch termination: `shouldTerminateToolBatch` requires every finalized result to set `terminate: true` (mixed batches continue).

The `Agent` class (`agent.ts`) wraps the loop and adds: state with `streamingMessage`/`pendingToolCalls` maintained by `processEvents`; awaited event subscribers in registration order; queues (`steer`/`followUp` with `one-at-a-time`/`all` modes); `agent_end` listeners counted toward run settlement (`waitForIdle` resolves after awaited `agent_end` subscribers, `agent.ts:560` comment); and a run lifecycle (`runWithLifecycle`) that synthesizes a failure assistant message on loop throw (`handleRunFailure`). Default `toolExecution` is `"parallel"` (`agent.ts:253`).

## 5. Built-in tools: a minimal loadout with policy seams

Default tool names are exactly `["read", "bash", "edit", "write"]` (`DEFAULT_TOOL_NAMES`, `packages/coding-agent/src/core/settings-manager.ts:85`); the registry also ships `grep`, `find`, `ls`, and `powershell` (`packages/coding-agent/src/core/tools/index.ts`, `allToolNames`), and read-only presets `createReadOnlyTools`.

Verified specifics per tool:

- `read` (`tools/read.ts`): text files truncated to `DEFAULT_MAX_LINES = 2000` lines or `DEFAULT_MAX_BYTES = 50KB`, whichever first (`tools/truncate.ts:11-12`); images (jpg, png, gif, webp, bmp) processed and attached; `offset`/`limit` pagination; a `structuredContent` image block for programmatic callers.
- `edit` (`tools/edit.ts`, `tools/edit-diff.ts`): the schema is now `edits[]` — an array of `{oldText, newText}` replacements matched against the original file, with uniqueness and non-overlap requirements. Matching tries exact first, then a fuzzy pass (`fuzzyFindText`, `normalizeForFuzzyMatch`: NFKC normalization, smart-quote/dash folding, trailing-whitespace strip); BOM is stripped before matching and line endings are detected, normalized to LF for the edit, and restored. This is a significant drift from the writeup's single `oldText`/`newText` schema.
- `write` (`tools/write.ts`): creates parent directories (`mkdir: recursive`).
- `bash` (`tools/bash.ts`): still synchronous (the tool resolves when the child exits; no background mode), but streams progress — an `OutputAccumulator` emits throttled `onUpdate` events at `BASH_UPDATE_THROTTLE_MS = 100` (`tools/renderers/bash.ts:19`) — and returns a `structuredContent` (`output` up to 1 MB, `truncated`, `full_output_path`, `exit_code`, `wall_time_seconds`). A nonzero exit produces an `isError` result whose structured content still carries the exit code. Execution is behind a pluggable `BashOperations` interface (remote delegation, e.g. SSH, is a supported option), with `killProcessTree` cleanup and a max-timeout guard.
- File-mutation serialization: `withFileMutationQueue` (`tools/file-mutation-queue.ts`) chains per-realpath promise queues so concurrent edit/write calls to the same file serialize while different files run in parallel; `edit` and `write` both use it, and `edit` deliberately keeps the queue locked across abort checks so an in-flight filesystem operation cannot release it mid-write.

The design point: correctness constraints (uniqueness, non-overlap, same-file serialization) are enforced in the tools, while execution policy (approval, blocking, rewriting) lives entirely in hooks — the harness itself ships no permission logic.

## 6. Session format: the event-tree session

Pattern: an append-only JSONL file whose entries form a tree via `id`/`parentId`; a single `leafId` pointer selects the active branch; forking is writing a child of an earlier node, and nothing is ever deleted. Source: `packages/coding-agent/src/core/session-manager.ts` (1900+ lines).

As implemented:

- `CURRENT_SESSION_VERSION = 3` (`session-manager.ts:41`). Entry types (`SessionEntry` union, `session-manager.ts:183`): `message`, `thinking_level_change`, `model_change`, `usage`, `compaction`, `branch_summary`, `custom`, `custom_message`, `label`, `session_info`, `context_edit` — matching the docs, plus the code-level detail that `context_edit` stores `replacement: { content } | null` and only ever replaces content, never metadata.
- Persistence is append-only with two exceptions: `_persist` writes the whole file once (`flushed` flag, `openSync(..., "wx")` exclusive create) and then `appendFileSync`s each new entry; full rewrites happen only for version migration, header repair of an empty explicit file, or `resetLeaf`-style tree operations. Files materialize lazily: `_hasConversation()` delays creation until a user or assistant message exists, so setup-only runs leave no file behind (tracked in the code as issue #10000).
- Loading (`loadEntriesFromFile`) streams the file with a byte buffer, skips malformed lines silently, validates the header, and repairs a missing trailing newline.
- Context reconstruction: `buildSessionPath` walks leaf→root by `parentId`; `buildContextEntries` applies the latest compaction on the path (keep from `firstKeptEntryId`, drop pre-compaction system messages in favor of the compaction's checkpoint); `buildSessionProjection` then applies the latest `context_edit` per target; `buildSessionContext` extracts current model/thinking from `model_change`/`thinking_level_change` entries and assistant-message metadata along the path.
- Branching verbs: `branchWithSummary(branchFromId, ...)` moves the leaf and appends a `branch_summary` entry whose `fromId` records the abandoned leaf; `resetLeaf()` allows a second root. `getBranch(fromId?)` is the walk primitive extensions use for branch-sensitive state.
- The `AgentSession` (`agent-session.ts`) is the glue: it subscribes to the agent's event stream and persists every finalized message on `message_end` (`_handleAgentEvent` → `sessionManager.appendMessage`), wraps `agent.prepareRequest` to rebuild the canonical context from the session projection before every request (`_installAgentRequestProjection`), wraps `finishTurn` to run the `turn_end` extension boundary and honor continuation requests (`_installAgentBoundaryHooks`), and wraps `prepareNextTurnWithContext` to run compaction checks and prompt/tool-loadout deltas between turns (`_installAgentNextTurnRefresh`). The system prompt is assembled as named sections (`preamble`, `tools`, `rules`, `docs`, `project_context`, `skills`, `cwd`, …) in `system-prompt.ts`; the base preamble is one sentence ("You are an expert coding assistant operating inside pi…", `system-prompt.ts:156`).
- The prompt and tool loadout are transcript-owned: `declareToolChanges` (`agent-loop.ts`) diffs the executable loadout against the transcript's declared tools before each request and appends a system message carrying only `toolsAdded`/`toolsRemoved` (merged into a pending system message when one exists).
- Project context files: `AGENTS.override.md`, `AGENTS.md`, `AGENTS.MD`, `CLAUDE.md`, `CLAUDE.MD` candidates (`resource-loader.ts:185`).
- Session runtime (`agent-session-runtime.ts`): `switchSession`, `newSession` (with `parentSession` header), `fork` (validates the entry ID), `importFromJsonl`.
- A cache warmer (`cache-warmer.ts`) replays the current request with a one-token output cap while the agent is idle, to refresh provider prompt caches; extensions can veto via `cache_warming_decision`.

## 7. Compaction: cut points at turn boundaries

Implementation: `packages/coding-agent/src/core/compaction/compaction.ts`, `branch-summarization.ts`, `utils.ts`.

- Trigger: `shouldCompact` = `contextTokens > contextWindow - reserveTokens` with defaults `reserveTokens: 16384`, `keepRecentTokens: 20000` (`compaction.ts:128-129`), checked in `prepareNextTurn` (via `_compactBeforeNextAssistantResponse`, `agent-session.ts:777`) and before user prompts.
- Cut rule as code: `findValidCutPoints` accepts entries whose projected messages satisfy `isCutPointMessage` — roles `user`, `assistant`, `bashExecution`, `custom`, `branchSummary`, `compactionSummary` — and rejects `toolResult` outright (`compaction.ts:351`), so a tool result can never be separated from its call. Split user-message spans cut mid-span at an assistant boundary.
- The `CompactionEntry` carries a complete system checkpoint captured via `getCurrentSystemMessage(projection.messages)` (`compaction.ts:256`), so pre-compaction prompt/tool state folds into one message.
- Serialization for the summary call truncates tool results at `TOOL_RESULT_MAX_CHARS = 2000` (`utils.ts:94`); cumulative `readFiles`/`modifiedFiles` are carried from previous pi-generated compactions.

## 8. Extension model: a microkernel plugin seam

Pattern: the CLI ships a microkernel (sessions, loop, tools, UI) where every policy — approval, context transformation, prompt shaping, model routing — is an in-process TypeScript extension loaded via jiti (`packages/coding-agent/src/core/extensions/jiti-loader.ts`, `loader.ts`, `runner.ts`), registered through one `ExtensionAPI` (`packages/coding-agent/src/core/extensions/types.ts`, 2000+ lines of contracts).

Verified surface:

- Events include `before_agent_start` (prompt sections/tools mutation, forced prompt), `message_end` (message replacement), `tool_call` (mutate/block), `tool_result` (composed), `provider_stream_event` (raw parsed stream data, read-only), `context`/`context_with_system`, `turn_end`/`agent_before_settle` (append entries, request one continuation), `user_bash`, `project_trust`, `session_before_fork` (`agent-session-runtime.ts:155`).
- Tool exposure union is exactly `"direct" | "model-only" | "codemode" | "deferred" | "hidden"` (`types.ts:516`), with `prepareLoadout(loadout)` letting an orchestrating tool adjust declared descriptions and hide declarations while staying callable, and `reachesTools(input)` declaring reachability.
- Nested tool calls (`packages/coding-agent/src/core/nested-tool-calls.ts`) run the full hook pipeline, emit tool events with `parentToolCallId`, never add transcript entries, and persist a bounded `nestedCalls` record with caps `maxCalls: 256`, `maxArgumentBytesPerCall: 8KiB`, `maxArgumentBytesTotal: 32KiB` (`nested-tool-calls.ts:27-29`); nested usage rolls up to the caller.
- MCP-style annotations (`readOnlyHint`, `destructiveHint`, `openWorldHint`, `types.ts:530`) exist as unverified hints a permission extension may consult.
- Built-in extensions are factory functions under `packages/coding-agent/src/extensions/` (`codemode/`, `tool-search/`, `mcp/`, `llama/`), loaded as `builtin:<name>` resources with a replaceability rule (`resource-loader.ts:110-146`).

## 9. pi-durable: a durable-execution kernel around the same transcript

`@earendil-works/pi-durable` (experimental flag in its README) rebuilds the harness as a task graph over committed storage. This is the architecture most relevant to baton-cli's orchestrator. Key sources: `packages/durable/src/session/session.ts` (1081 lines), `packages/durable/src/harness/{scheduler,generation,tool,compaction,inbox,submissions,context,view}.ts`, `packages/durable/src/types.ts`, `packages/durable/src/entries.ts`.

- The session kernel is a single serialized mutation line: every commit, preparation, storage settlement, and adoption runs while the line is held; only committed state is observable; the first storage error fails the whole Session (`SessionImpl` docs, `session/session.ts:100-112`).
- Transcripts are immutable typed entries over Chord documents: `pi.user`, `pi.assistant`, `pi.system`, `pi.tool-result`, `pi.reset`, `pi.compaction` (`entries.ts`), with built-in documents `pi.agent`, `pi.live`, `pi.inbox`, `pi.provider`, `pi.usage` (`agent.ts:44`, `live.ts:112`, `inbox.ts:22`, `provider.ts:13`, `usage.ts:15`).
- Context is selected by head markers: a reset or compaction entry carries a `head: EntryId`; the model-visible range is the newest head marker plus all entries after it (`context.ts`, `selectActive`), and `orderToolResults` re-sorts results to follow their calls and synthesizes a `missing_result` error result for unmatched calls (`context.ts:290-340`).
- Every task is a durable state machine: statuses `pending | running | waiting | completing | terminal` with a checkpoint carried through restarts (`types.ts:500-533`). `GenerationTask` (`generation.ts:118`) phases: `prepare` (render sections, plan positional system entries, check compaction threshold), `request` (stream), `tools` (wait on the round's tool tasks, `policy: "allSettled"`), with compaction as a child task that either blocks the request or runs in the background (`backgroundTokens` below the threshold, `types.ts:505`).
- Tool calls are durable tasks (`ToolTask`, `tool.ts`): phase `call` resolves/validates/hooks the call, then commits the intent — final arguments plus `replay: "safe" | "unsafe"` — before `execute` runs; on restart, phase `execute` reruns the call only when both the stored intent and the current tool definition say `safe`, otherwise settles with an `interrupted` error result ("may have partially run"). Aborts distinguish `aborted`/`interrupted`/`abandoned` by abort reason (`tool.ts:291-305`).
- Parallelism is scheduling, not `Promise.all`: `startToolRound` creates one `pi.tool` task per call in one commit (each an independent durable task the generation waits on); in sequential mode only the first task is created and the rest stay `pending` slots started as prior ones settle (`generation.ts:570-625`). Default `toolExecution` is `"parallel"` (`agent.ts:69`).
- Tool execution API (`ToolExecutionApi`, `types.ts:200-260`) gives a call: `output()` streaming with committed progress at 100 ms default intervals (`agent.ts:35-36`), `retainedOutput()`, `details()`, `commit()`, `createTask()`, `waitForTask()`, `conversation()`, and `executeTool()` for nested calls — each nested call its own task owned by the caller, with a key-based reattach protocol so a replay-safe rerun reuses finished nested calls.
- Subagents are library code over ownership: `ConversationOwnership = { kind: "ownerless" } | { kind: "task"; taskId }` (`types.ts:299`); the ownership index (`scanConversations({ ownerTaskId })`) makes a crash-retry of a subagent tool reuse the same child; abort cascades bottom-up (owned work first, then the owner's handler); `background: true` tasks are abort/idle boundaries (`types.ts:113-132`).
- Submissions (`submissions.ts`): `whenBusy: "steer" | "follow-up" | "reject"` with `ConversationBusy` thrown for reject (`submissions.ts:200`); request-ID dedup returns the existing submission (`submissions.ts:179-185`); display-only writes are appended immediately even mid-run.
- Provider session identity: a UUIDv7 per conversation in `pi.provider`, generated once and reused across reopen/retry/reset/compaction (`provider.ts:18,31-34`), forwarded to pi-ai's `sessionId` stream option.
- Storage backends: SQLite (`storage/sqlite/` with real transactions) and a JSONL backend whose commit protocol is a write-ahead scheme — sidecar appends per document/task, then a commit marker line appended to `main.jsonl` with a strictly increasing `seq`; recovery replays markers and rejects out-of-order sequences, and reclamation replaces sidecars via temp-file rename (`storage/jsonl/storage.ts:280-320,510-545`).
- UIs consume committed state only: `viewState()` is a Chord replicated state (snapshot + deltas) over the conversation's entries and documents (`view.ts:118`, using `replicatedState` from `@earendil-works/chord`), and `watchEvents` derives coding-agent-style events from commits.

## 10. TUI: retained-mode differential rendering

`packages/tui/src/tui.ts` defines `Component` as `render(width): string[]` plus optional input handlers and `invalidate()`; `tui-main-screen.ts` renders into the terminal's main screen and scrollback, finding the first changed line and re-rendering from there, with full re-render on width change or when changes fall above the viewport; both screen renderers wrap updates in synchronized-output escapes (`CSI ?2026h/l`, `tui-main-screen.ts:281`, `tui-alt-screen.ts:72`). Correction to the writeup: an alt-screen implementation now exists alongside the scrollback renderer.

## 11. What baton-cli should copy (pattern level)

1. **Event-tree session**: append-only entries with parent pointers and a leaf selector gives resume, fork, and post-processing with no delete path; `session-manager.ts` is a working reference for a Bend2-native implementation, including the lazy-materialization detail (no file until a real turn exists).
2. **Turn as the unit of consistency**: cut points, resume points, and compaction checkpoints all coincide with turn boundaries, and the invariant "a tool result never separates from its call" is enforced in two independent places (`findValidCutPoints` and durable `orderToolResults`).
3. **Durable tool tasks with replay policy**: commit call intent (final args + replay class) before execution; on restart, rerun only replay-safe tools and hand the model an `interrupted` result otherwise. This is the only design surveyed that gives mid-flight tool calls a defined crash semantics.
4. **Ownership-indexed subagents**: children created in the same commit as the spawn call, keyed by owner task, with bottom-up abort and background boundaries — directly transferable to an orchestrator that spawns seats.
5. **Head markers over snapshots**: durable context selection (newest head marker + suffix) makes compaction and reset a single committed entry rather than a rewrite; cheaper to resume than the coding-agent's per-path replay.
6. **Hooks as the policy seam**: `beforeToolCall`/`afterToolCall`/`finishTurn`/`prepareRequest`/`prepareNextTurn` cover approval, result rewriting, run control, context rebuild, and between-turn policy; the shipped tools contain no policy logic.
7. **Per-file mutation queues** for parallel file edits, and **split tool results** (`content`/`details`/`structuredContent`) to keep UI state out of model context.

## 12. Corrections register (docs/writeup vs code at b06c1f2)

1. The agent loop lives at `packages/agent/src/agent-loop.ts`; the writeup's path `packages/ai/src/agent/agent-loop.ts` no longer exists.
2. `edit` takes `edits[]` (multi-replacement per call) with a fuzzy-matching fallback, BOM stripping, and CRLF preservation (`tools/edit.ts`, `tools/edit-diff.ts`); the writeup's single `oldText`/`newText` schema and "must match exactly" are outdated (the prompt text still claims exact match while the implementation fuzzy-matches — an internal inconsistency in pi itself).
3. `read` truncates at 2000 lines or 50KB and additionally supports bmp (`tools/read.ts`, `tools/truncate.ts`); the writeup mentions only the line cap and four formats.
4. `bash` streams throttled progress updates and returns structured content with exit code and full-output path (`tools/bash.ts`); the writeup's "runs synchronously, no streaming" is half-true — completion is still synchronous, but progress is streamed.
5. A `powershell` tool exists beyond the writeup's four-tool set (`tools/index.ts`).
6. The TUI has an alt-screen renderer in addition to the scrollback renderer (`tui-alt-screen.ts`); the writeup describes only the scrollback approach.
7. Session files materialize only after the first user or assistant message (`session-manager.ts`, `_hasConversation`, issue #10000) — undocumented.
8. On `stopReason: "length"`, pi fails every pending tool call instead of executing it (`failToolCallsFromTruncatedMessage`) — documented nowhere in the writeup or coding-agent docs.
9. pi-durable's replay rule requires both the stored intent and the current tool definition to be `safe` (`tool.ts:170-173`); the README describes only the declaration side.
10. pi-durable's sequential rounds create one tool task at a time (`generation.ts`, `pending` slots); the README describes sequential execution without the task-level mechanics.
11. pi-durable uses `head` markers on entries for compaction/reset context selection (`context.ts`), a generalization of the coding-agent's `firstKeptEntryId` field the durable README does not spell out.
12. Stop reasons include `"deferred"` (`ai/src/types.ts:474`), related to virtual-model routing; unexplained in docs.

## 13. What fits poorly for a Bend2-native harness with async streaming tools

1. **Batch-scoped tool concurrency**: agent-core parallelism is `Promise.all` within one assistant message's batch, with results re-ordered into source order for persistence (`agent-loop.ts`). A harness whose tools stream asynchronously across turns needs per-call streams as session entries, in completion order; pi's event ordering is turn-scoped by construction.
2. **Awaited-listener settlement**: `Agent.waitForIdle` includes awaited `agent_end` subscribers (`agent.ts`), and assistant `message_end` is the persistence barrier. These are correct for a synchronous single-process loop but couple run liveness to consumer speed; pi-durable's "only committed state is observable" decouples it and is the better model for an orchestrator that watches seats remotely.
3. **Single-process JSONL persistence** (coding-agent): correct for a CLI, but crash safety requires the durable kernel's committed-storage design; pi itself demonstrates the migration path (JSONL → committed markers/tasks).
4. **Per-conversation, single-model compaction**: thresholds key on one `contextWindow` (`compaction.ts:267`); an orchestrator fanning out seats needs per-seat compaction plus an orchestrator-context policy, which neither pi architecture provides.
5. **TypeScript in-process extensions**: the jiti loader and shared-OS-permission model (`extensions/jiti-loader.ts`, `security.md`) presuppose a JS runtime; the transferable parts are the exposure taxonomy and nested-call accounting, not the mechanism.
6. **No orchestrator inbox**: steering/follow-up queues exist per agent (`agent.ts`) and per conversation (`pi.inbox`), but nothing speaks an external tasking/message/receipt protocol; baton-cli's baton2 protocol layer has no counterpart here.

## 14. Core architectural concepts

1. **Event-tree session (append-only log with fork-by-prefix).** Sessions are immutable entries in a tree; a leaf pointer selects the active branch; resume is re-walking, fork is appending a child of an earlier node (`session-manager.ts`, `durable/src/session/`). Nothing is ever mutated except content projections (`context_edit`) and version migrations.
2. **Turn as the unit of consistency.** One assistant response plus its complete tool-result batch is the atom for events (`turn_start`/`turn_end`), persistence, compaction cut points, and durable run phases (`agent-loop.ts`, `compaction.ts:351`, `generation.ts` phases). Design consequence: every boundary the harness or orchestrator can act on is a turn boundary.
3. **Transcript-owned prompt and tool state.** The system prompt and tool loadout are replayed from system-message entries (`sections` patches, `toolsAdded`/`toolsRemoved`; `ai/src/utils/transcript.ts`, `agent-loop.ts#declareToolChanges`, durable `planSystemEntries`). There is no separate prompt store; provider prompt caches stay warm because unchanged state is not re-sent.
4. **Policy at hooks, not features.** The kernel ships tools without approval logic, a loop without step limits, and a session without privacy rules; `beforeToolCall`, `tool_call`, `finishTurn`, `prepareRequest`, and the extension events are the only control surfaces (`agent.ts`, `extensions/types.ts`). Features like plan mode or sub-agents are deliberately absent and re-expressible as hooks or tools.
5. **Durable execution kernel.** pi-durable commits every effect before it is visible, represents work as resumable tasks with checkpoints and ownership edges, and treats replay policy as an explicit contract between stored intent and current code (`session/session.ts`, `harness/tool.ts`, `harness/scheduler.ts`). Observability is derived from commits (replicated state + event derivation), never from live process state.
6. **One stream primitive everywhere.** Provider streams, agent loops, session JSONL, JSON mode, RPC, and durable event watches are all ordered event streams with a completion predicate (`ai/src/utils/event-stream.ts`, session files, `json-event.ts`, `rpc.md`), so every consumer — TUI, RPC client, SDK, orchestrator — reads the same shape of transcript.

## Sources

Primary (code, shallow clone `b06c1f2cf1dea6af8748ddeee18c23587d2cb7c6` of https://github.com/earendil-works/pi; paths repo-relative as cited above):

- `packages/agent/src/agent-loop.ts`, `packages/agent/src/agent.ts`, `packages/agent/src/types.ts`
- `packages/ai/src/types.ts`, `packages/ai/src/utils/transcript.ts`, `packages/ai/src/utils/event-stream.ts`, `packages/ai/src/models.generated.ts`
- `packages/coding-agent/src/core/session-manager.ts`, `agent-session.ts`, `agent-session-runtime.ts`, `sdk.ts`, `system-prompt.ts`, `settings-manager.ts`, `resource-loader.ts`, `cache-warmer.ts`, `messages.ts`, `nested-tool-calls.ts`
- `packages/coding-agent/src/core/tools/{index,bash,read,edit,edit-diff,write,file-mutation-queue,truncate,output-accumulator}.ts`
- `packages/coding-agent/src/core/compaction/{compaction,branch-summarization,utils}.ts`
- `packages/coding-agent/src/core/extensions/{types,jiti-loader,loader,runner}.ts`
- `packages/coding-agent/src/extensions/{codemode,tool-search,mcp}/`
- `packages/durable/src/session/session.ts`, `packages/durable/src/harness/{tool,generation,scheduler,compaction,context,inbox,submissions,provider,agent,view,events,live,usage}.ts`, `packages/durable/src/types.ts`, `packages/durable/src/entries.ts`, `packages/durable/src/storage/{jsonl,sqlite}/`
- `packages/tui/src/{tui,tui-main-screen,tui-alt-screen}.ts`
- `packages/chord/README.md`

Secondary (docs and writeup):

- https://mariozechner.at/posts/2025-11-30-pi-coding-agent/ — foundational writeup (2025-11-30; historical, superseded in the areas listed in section 12)
- https://github.com/earendil-works/pi/blob/main/packages/agent/README.md — pi-agent-core docs
- https://github.com/earendil-works/pi/blob/main/packages/durable/README.md — pi-durable docs (experimental)
- https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/session-format.md — session format
- https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/compaction.md — compaction reference
- https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md — extensions
- https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/how-pi-works.md — architecture overview
- https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/{sessions,sdk,rpc,security,skills}.md — sessions, SDK, RPC, security, skills
- https://github.com/earendil-works/pi/blob/main/packages/coding-agent/README.md — CLI overview, Node requirement
- https://github.com/badlogic/pi-terminal-bench — Terminal-Bench runner (writeup benchmark context)
- https://lucumr.pocoo.org/2025/11/21/agents-are-hard/ — rationale for direct provider-API integration
