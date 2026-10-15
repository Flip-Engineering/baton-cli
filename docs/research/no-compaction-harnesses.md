# Shipping harnesses without compaction (late 2026)

This report surveys harnesses that shipped, as of October 2026, operating without context compaction, or carrying compaction only as a dormant or last-resort stage. It is the shipped-implementation companion to [nooa.md](nooa.md), whose projection-budgeting architecture (bounded previews, values live in the process, three dormant compaction paths) is the anchor example. Per-harness concept-level treatment lives in [no-compaction-approaches.md](no-compaction-approaches.md); minimal-loop harnesses are covered by [minimal-harness-survey.md](minimal-harness-survey.md), which is why Codex CLI, Gemini CLI, OpenHands, goose, and Open Interpreter are not re-surveyed here. Open Interpreter's 2026 restart is a Codex fork ([survey, §Open Interpreter](minimal-harness-survey.md)); it documents no no-compaction mode, so it is excluded under this report's inclusion rule.

Method: open-source harnesses were shallow-cloned to `/tmp/baton-cli-research/<name>` and cited by repo-relative paths at the recorded HEAD; closed products are cited from engineering blogs and official documentation only. All defaults and figures below were verified against those primary sources; anything that could not be verified is listed in the open-questions section.

| Harness | Source type | Mechanism that replaces compaction |
| --- | --- | --- |
| Letta (letta-code, MemGPT lineage) | code + docs | memory blocks, MemFS v2, archival/recall retrieval, sleep-time consolidation |
| LangChain deepagents | code | filesystem as workspace, bounded tool-result ingress with re-openable offload, subagent isolation |
| Anthropic memory tool + context editing | official docs | client-side file memory; selective server-side clearing of tool results |
| Manus | blog (closed) | file system as ultimate context, restorable compression, recitation, session branching |
| Amp (Sourcegraph) | official site | handoff to fresh focused threads; thread referencing; edit/restore |
| Magentic-One / Microsoft Agent Framework | paper + docs | task and progress ledgers as bounded state documents |
| Mastra | docs + SDK | bounded window + semantic recall + working memory; observational memory when history must shrink |

## 1. Letta (letta-code, MemGPT lineage)

The `letta-ai/letta` repository at HEAD `5bcdd177d70fa2b31a754cfcd801e77b2e1ab16a` is documentation-only; its README states the current source lives in [letta-ai/letta-code](https://github.com/letta-ai/letta-code) and that the retired Letta V1 API server is preserved on the `archive` branch ([README](https://github.com/letta-ai/letta/README.md)). This report reads both: `letta-code` at HEAD `cc4654acc3b424a68c385bce0fe0c00edaad5d7e` (2026-10-14, v0.34.15) and the archive branch at HEAD `56ba9c25552605eec89de8ed3dc6394b625c1993`. The MemGPT-lineage memory paging lives in the archive; the shipping coding-agent harness lives in `letta-code`.

### 1.1 Memory paging: core, archival, recall

- **Core memory** is a set of typed blocks: "A Block represents a reserved section of the LLM's context window" (`letta/schemas/block.py:67`, archive). Blocks render into the prompt inside an XML-like `<memory_blocks>` wrapper carrying label, description, `chars_current`, and `chars_limit` ([memory blocks docs](https://docs.letta.com/v1-sdk/memory/memory-blocks)). Blocks are always visible (no retrieval step), agent-editable via memory tools, shareable across agents, and optionally `read_only`.
- **The memory tools** are the paging surface (`letta/functions/function_sets/base.py`, archive): `conversation_search` (:87) over recall memory; `archival_memory_insert` (:164) and `archival_memory_search` (:194) over a searchable passage store; `core_memory_append` (:246) and `core_memory_replace` (:263) over blocks; and the newer block-editing verbs `memory_replace` (:311), `memory_insert` (:391), and `memory_rethink` (:488) — precise edit, line insert, and full rewrite of one block.
- **Recall memory** is the conversation store, paged back in on demand via `conversation_search`; **archival memory** is a passage store (`ArchivalMemorySearchResult`, `letta/schemas/memory.py:861-884`, archive).
- `letta-code` ships default blocks `persona` and `human` (`src/agent/memory.ts:16`), seeds a root `MEMORY` block that indexes a **MemFS v2** repository on agent creation (`src/agent/memory-filesystem.ts:176-192`), and backs that repository with git: `src/agent/memory-git.ts` (57 KB) plus `src/agent/memory-worktree.ts`, which records memory edits as commits and merges reflection branches via worktrees. Dedicated **recall subagents** (`src/agent/prompts/recall_subagent.md`, `recall_subagent_local.md`) search conversation history and return findings, keeping raw transcript pages out of the main agent's context.

### 1.2 How context is assembled and when compaction triggers

The server-side loop (archive) keeps the system prompt (memory blocks included) plus an in-context message buffer (`agent_state.message_ids`; `get_in_context_messages`, `letta/services/agent_manager.py:1413`). Compaction machinery exists in `letta/services/summarizer/`:

- Modes `STATIC_MESSAGE_BUFFER` and `PARTIAL_EVICT_MESSAGE_BUFFER` (`summarizer/enums.py:8-10`); the legacy `Summarizer` defaults to `message_buffer_limit=10`, `message_buffer_min=3`, and a 0.30 partial-evict fraction (`summarizer.py:47-49,62-64`).
- The current sliding-window summarizer evicts roughly 30% of messages, grows the eviction fraction by 0.10 until the projected token count meets the goal, and requires the cutoff to land on an assistant message (`summarizer/summarizer_sliding_window.py:139-194`). A pending approval message is protected from eviction together with its preceding assistant message (:133-135) — a cut-point guarantee in the same family as pi's (`compaction.ts:351` in [pi.md](pi.md)). Complete summarization is the explicit fallback (`summarizer_all.py`).
- The trigger threshold is model-specific: GPT-5-family models compact proactively at 90% of the context window — "this aligns GPT-5 behavior with the codex harness' proactive 90% compaction policy" — while all other models trigger at 100% (`summarizer/thresholds.py:27-41`). The compact call is `compact_messages` (`summarizer/compact.py:135`), invoked from the agent loop at `letta/agents/letta_agent_v3.py:2109`, with a dedicated `context_window_overflow_in_system_prompt` stop reason when the prompt alone exceeds the window (`letta/schemas/letta_stop_reason.py:22`).
- `letta-code` creates agents with `compaction_settings: { model: DEFAULT_SUMMARIZATION_MODEL }` defaulting to `"letta/auto"` (`src/agent/create-agent-request.ts:214-217`) and renders compaction events with `include_compaction_messages: true` (`src/agent/message.ts:334`).
- In local mode, `letta-code` embeds the pi-mono provider runtime (`pi-stream-adapter` under `src/backend/dev/`) and its own compaction port in `src/backend/local/compaction.ts`: default mode `sliding_window` at 0.3 eviction (:43-44), summary prompts capped at 500 words ("all") or 300 words ("sliding window") (:22-23), tool returns truncated to 2,000 characters in the summary input (:25), and a 1M-context fallback model configuration for the Fable model family (:26-29).

### 1.3 Sleep-time agents and file eviction

Sleep-time agents pair a primary agent with a background consolidation agent: the group carries `sleeptime_agent_frequency`, `turns_counter`, and `min/max_message_buffer_length` (`letta/orm/group.py:26-31`, archive), so the background agent wakes every N turns, reads the shared message buffer, and rewrites memory blocks while the primary agent keeps no memory-editing tools ([docs](https://docs.letta.com/configuration/memory); [Sleep-time compute](https://www.letta.com/blog/sleep-time-compute/)). Attached files are bounded the same way context is: enforcing `max_files_open` closes least-recently-used open files with `is_open=False, visible_content=None` (`letta/services/files_agents_manager.py:44-45,717-719`, archive) — file content in context is an LRU-bounded window over durable storage.

### 1.4 Failure modes

The compaction paths are summaries: sliding-window eviction compresses verbatim history into a word-limited summary, and recall/archival retrieval returns excerpts, not full turns. Long-horizon fidelity therefore depends on the model writing durable state into blocks and MemFS before anything is evicted; the approval-protection rule is the only structural guarantee against mid-interaction loss. The MemFS git backing is the strongest piece: memory edits are versioned and restorable.

## 2. LangChain deepagents

Cloned at HEAD `825acb3ca03bd103e4df6013b122eca8475d1982` (2026-10-14). deepagents is a middleware harness over LangChain's `create_agent()` and LangGraph; the architecture map is `libs/ARCHITECTURE.md`.

### 2.1 The stack

`create_deep_agent()` (`deepagents/graph.py:893-956`) assembles: `FilesystemMiddleware`, `SubAgentMiddleware` (the only two middleware in `_REQUIRED_MIDDLEWARE`, graph.py:247-250, removable only by error), `SummarizationMiddleware`, `PatchToolCallsMiddleware`, harness-profile middleware, optional `SkillsMiddleware`, prompt-caching middleware (Anthropic, Bedrock, Fireworks), optional `MemoryMiddleware`, optional `HumanInTheLoopMiddleware`, and `UnsupportedContentMiddleware`, running under `recursion_limit: 9_999` (:1008). Planning is opt-in at HEAD: the changelog records that `create_deep_agent` no longer includes `TodoListMiddleware` (the `write_todos` tool) by default (issue [#4929](https://github.com/langchain-ai/deepagents/issues/4929)), and the built-in Codex harness profile re-adds it because the Codex prompt references `write_todos` (`profiles/harness/_openai_codex.py:19,72-78`).

### 2.2 Context small by construction

- **Workspace in backend, not in messages.** Files live in a backend (`deepagents/backends/`): `StateBackend` stores them in graph state (`FilesystemState` with a `DeltaChannel` reducer snapshotting every ~50 steps, `middleware/filesystem.py:1297-1301`; `graph.py:74-77`), while `FilesystemBackend` maps them to disk. Tool calls touch paths; file bodies never round-trip through the transcript.
- **Bounded ingress with restorable pointers.** A tool result over `tool_token_limit_before_evict` (default 20,000 tokens, `filesystem.py:1897`) is written to `{artifacts_root}/large_tool_results/{tool_call_id}` and replaced by a preview stub carrying the path; a `HumanMessage` over 50,000 tokens is evicted the same way (:1898). The grep tool's description documents that offloaded results "live under the artifacts root (`/large_tool_results/` by default); grep that directory to search them" (:1565). Tools whose outputs self-truncate (ls, glob, grep) plus `read_file`, `write_file`, and `edit_file` are excluded from eviction (:1727-1756).
- **Paged reads.** `read_file` defaults to 100 lines with `offset`/`limit` (:1077-1078); truncation uses a 4-chars-per-token estimate (:1090-1092) and never drops undisplayed source lines — a cut inside one over-long line is handled explicitly (:1095-1129).
- **Binary offload.** Inline media and binary `read_file` blocks are content-addressed by SHA-256 into the backend (`middleware/_blob_offload.py:31-41`); messages carry blob references, payloads hydrate on demand, and a missing blob degrades to the notice "[Binary content from an earlier read_file call is no longer available. Re-read the file if you still need it.]" (:34).
- **Subagent isolation.** The `task` tool launches subagents with fresh contexts (`middleware/subagents.py`); the parent receives one `ToolMessage` whose content is the subagent's final assistant message, and state merges exclude `messages`, `todos`, `structured_response`, `skills_metadata`, and private keys (:404-435). A `mode: "fork"` subagent instead inherits the parent's full history with a preamble marking the delegation as already-happened (:362-377) and cannot recurse (:79-81). Each subagent runs its own stack, including its own summarization middleware (graph.py:722-730).

### 2.3 Compaction as an enhanced last resort

`SummarizationMiddleware` (`middleware/summarization.py:1811-1900`) wraps LangChain's middleware with four additions. Defaults are fraction-based when the model profile exposes `max_input_tokens` — trigger 0.85, keep 0.10 — and otherwise fixed at trigger 170,000 tokens / keep 6 messages, with tool-argument pre-truncation at 20/20 messages (:263-300). The additions: (1) evicted history is appended verbatim to `/conversation_history/{session_id}.md` on the backend and the summary embeds that path, so `read_file` can re-open the full original — "LangChain drops evicted messages with no recovery path"; (2) large `write_file`/`edit_file` arguments in older messages are clipped below the compaction trigger, "often reclaiming enough context to skip summarizing"; (3) a provider `ContextOverflowError` triggers summarize-and-retry instead of propagating; (4) summarization is non-mutating — tracked in a private `_summarization_event` state field applied via `wrap_model_call`, leaving `state["messages"]` intact for replay (:1842-1847). A separate `SummarizationToolMiddleware` exposes `compact_conversation` as a model-callable tool (:1993).

### 2.4 Cache behavior

Prompt-caching middleware is appended after the core stack and before `MemoryMiddleware`, with an explicit ordering comment: profile middleware sits before memory "so that memory updates (which change the system prompt) don't invalidate the Anthropic prompt cache prefix" (graph.py:929-949). The `DeltaChannel` checkpoint design bounds checkpoint growth at O(N) rather than O(N²) (graph.py:74-77). No published long-horizon benchmark attributable to the project was found.

## 3. Anthropic: memory tool, context editing, and Claude Code

Official documentation, no clone. The API-level pairing is a memory tool that gives Claude durable externalized state and a context-editing strategy that clears old tool results once that state exists.

### 3.1 Memory tool

[`memory_20250818`](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool) is an Anthropic-provided tool executed entirely client-side: Claude issues `view`, `create`, `str_replace`, `insert`, `delete`, and `rename` commands against a `/memories` directory; the application maps that prefix onto its own storage and must validate every path (path-traversal protection is documented as a hard requirement). `view` supports `view_range` paging. The documentation ships a "MEMORY PROTOCOL" system-prompt pattern whose premise is explicit: "ASSUME INTERRUPTION: Your context window might be reset at any moment, so you risk losing any progress that is not recorded in your memory directory." Best practices include capping memory-file sizes and paging long files via `view_range`.

### 3.2 Context editing (`clear_tool_uses_20250919`)

The [context editing page](https://platform.claude.com/docs/en/build-with-claude/context-editing) specifies two server-side strategies under the `context-management-2025-06-27` beta, applied before the prompt reaches Claude while "your client application maintains the full, unmodified conversation history":

| Option | Default | Behavior |
| --- | --- | --- |
| `trigger` | 100,000 input tokens | when the prompt exceeds it, clearing begins; may also count `tool_uses` |
| `keep` | 3 tool uses | most recent tool use/result pairs retained |
| `clear_at_least` | None | minimum tokens to clear per activation; if unreachable, the edit is skipped to protect the prompt cache |
| `exclude_tools` | None | tool names whose results are never cleared |
| `clear_tool_inputs` | false | tool calls stay visible; only results are replaced by placeholder text |

Clearing is oldest-first and chronological. Preserved: the conversation structure, all tool calls (unless `clear_tool_inputs` is set), the `keep` window, excluded tools, and — per the preserved-thinking note — server-side context management "never invalidates thinking blocks" on Claude Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. Lost: everything else in cleared tool results; the API replaces each with placeholder text and reports the edit in `context_management.applied_edits` (`cleared_tool_uses`, `cleared_input_tokens`). Cache behavior is documented as a tradeoff: tool-result clearing invalidates the cached prefix at the clear point, so `clear_at_least` exists to make each invalidation worthwhile. `clear_thinking_20251015` separately manages thinking blocks (default keep-all on current model classes, last-turn-only on older ones; must be listed first when strategies combine). The combination with memory is the no-compaction path: "When your conversation context approaches the configured clearing threshold, Claude receives an automatic warning to preserve important information" so it can write tool results into memory files before they are cleared. Anthropic's published numbers: on an internal agentic-search evaluation, memory tool plus context editing improved performance 39% over baseline and context editing alone 29%; in a 100-turn web-search evaluation, context editing completed workflows that otherwise failed on context exhaustion while reducing token consumption by 84% ([announcement](https://claude.com/resources/articles/context-management), 2025-09-29). Methodology beyond those sentences is unpublished.

### 3.3 Where compaction sits and what Claude Code adds

Anthropic's own documentation now positions server-side compaction (`compact-2026-09-04` beta; on-demand and token-threshold forms with keep-recent-turns and background modes) as "the primary strategy for managing context in long-running conversations", with context editing as the fine-grained alternative ([compaction overview](https://platform.claude.com/docs/en/build-with-claude/compaction)). Claude Code's cross-session memory is the CLAUDE.md/AGENTS.md hierarchy plus auto memory: Claude-written notes loaded at every session start, capped at the first 200 lines or 25 KB, per-repository and shared across worktrees, with per-subagent auto memory available, and `.claude/rules/` files that load on demand only when path-matched files are touched ([memory docs](https://code.claude.com/docs/en/memory)) — context carried by files by construction rather than by history.

## 4. Manus (closed product)

All claims verified against the engineering blog and product posts; no source code is available. [Context Engineering for AI Agents](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus) (2025-07-18, Yichao "Peak" Ji) is the primary architecture statement:

- **KV-cache first.** The stated single most important production metric is the KV-cache hit rate; Manus reports an average input-to-output token ratio around 100:1 and cites a 10x price gap between cached and uncached input on Claude Sonnet ($0.30 vs $3.00 per MTok). Practices: keep the prompt prefix stable (no per-second timestamps), make context append-only, serialize deterministically (JSON key order), mark cache breakpoints explicitly where providers require them, and route requests consistently across self-hosted workers (vLLM prefix caching with session IDs).
- **Mask, don't remove.** Tool availability is governed by a context-aware state machine that masks token logits during decoding rather than adding or removing tool definitions mid-run, because a definition change invalidates the cache from the first changed token onward and leaves prior tool references dangling. Prefill-based enforcement (auto / required / specified modes, Hermes format) plus consistent tool-name prefixes (`browser_`, `shell_`) let one prefix mask select a whole tool group without stateful logits processors.
- **File system as ultimate context.** "Unlimited in size, persistent by nature, and directly operable by the agent itself"; compression is designed to be restorable: a web page's content can be dropped as long as the URL is preserved, a document's contents can be omitted as long as its path remains available in the sandbox.
- **Recitation.** Manus rewrites `todo.md` step-by-step — the average task runs about 50 tool calls — pushing the current plan into the end of the context each turn to hold the goal inside the recent attention span; the post frames this as deliberate attention management against long-context drift.
- **Errors stay in.** Failed actions and their observations remain in context so the model updates its prior away from repeating them; the post names error recovery as underweighted by benchmarks. Structured variation in serialization counters few-shot mimicry drift on repetitive work.

Later, [Branch](https://manus.im/blog/manus-branch) (2026-07-09) shipped session branching: a branch from any message opens a parallel session inheriting the full history, instructions, and files up to that point; the original session stays untouched, branches can themselves branch, and a "Branched from" breadcrumb ties each branch to its origin — tree-shaped session management in which one accumulated context is reused across parallel deliverables without compression. A research paper named "context folding" (arXiv:2510.11967) is frequently associated with Manus in secondary coverage; it is a ByteDance Seed / CMU / Stanford work, not a Manus feature (see open questions).

## 5. Amp (Sourcegraph)

Amp is closed-source; evidence is its official site. On 2025-10-23 Amp [removed compaction](https://ampcode.com/news/handoff) — "Handoff (No More Compaction)" — deleting `/compact` and the editor Compact buttons, with two stated reasons: compaction is lossy (the summarizer decides what survives), and it "encourages long, meandering threads, in which you just compact once you run out of context window, stacking summary on top of summary."

The replacement mechanisms, from the [context-management guide](https://ampcode.com/guides/context-management) (archived November 2025, page updated 2026-07-27):

- **Handoff**: the operator states a goal ("`/handoff execute phase one of the created plan`"); a second model analyzes the current thread and drafts a prompt for a new thread, together with a list of relevant files extracted from messages, tool calls, and files. The draft lands in the new thread's prompt editor for review and editing before sending. Agent-initiated handoff exists as [ask-to-handoff](https://ampcode.com/news/ask-to-handoff).
- **Thread referencing**: `@@` (CLI) or thread URLs/IDs let the agent pull from other threads via a `read_thread` tool, in which a second model extracts only the information relevant to the current prompt — cross-thread retrieval instead of one unbounded history.
- **Edit and restore**: editing an earlier message truncates the thread at that message and re-runs; restoring rewinds to an earlier point. Both are tree operations on the thread, not compression operations.
- **Bounded ingestion**: `@`-mentioned files are truncated to 500 lines and 2 KB per line before entering context.
- The guide's position statement is linked as [200k Tokens Is Plenty](https://ampcode.com/200k-tokens-is-plenty): keep threads small and focused rather than expanding the window.

Failure modes: the harness provides no automatic long-horizon continuity — handoff quality depends on the extraction model and on the operator reviewing the draft, and verbatim history of a handed-off thread remains in the old thread rather than being carried forward.

## 6. Magentic-One and Microsoft Agent Framework (magentic orchestration)

Magentic-One ([MSR article](https://www.microsoft.com/en-us/research/articles/magentic-one-a-generalist-multi-agent-system-for-solving-complex-tasks/), 2024-11-04; [technical report](https://arxiv.org/abs/2411.04468)) is a lead-Orchestrator architecture whose context discipline is structural rather than summarizing. The Orchestrator runs two loops: an outer loop maintaining a *task ledger* — facts, educated guesses, and the current plan — and an inner loop maintaining a *progress ledger* recording current progress and the next subtask assignment. Each round the Orchestrator self-reflects in the progress ledger, assigns one specialized agent (WebSurfer over the browser accessibility tree with set-of-marks prompting, FileSurfer, Coder, ComputerTerminal), receives that agent's report, and updates the ledger; when progress stalls (stall count greater than 2), the outer loop updates the task ledger and re-plans. Working state lives in two ledger documents updated in place, while worker transcripts stay inside each worker's own context.

Evidence: statistically competitive with the published SOTA of October 2024 on GAIA, AssistantBench, and WebArena (WebArena self-reported), evaluated with AutoGenBench for repetition and isolation. Open-source on AutoGen; the pattern ships as magentic orchestration in Semantic Kernel / Microsoft Agent Framework with `StandardMagenticManager` (structured outputs), `MagenticBuilder`, plan-review approval, and stall-driven human intervention events ([MS Learn](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-orchestration/magentic), updated 2025-07-21) — marked experimental in the Agent Framework and documented as inspired-by rather than a direct port. Failure modes: ledger quality bounds plan quality (a stale facts section propagates into re-plans); the pattern targets task-scoped orchestration with bounded rounds (`MaximumInvocationCount`), not open-ended multi-hour sessions; and how the Orchestrator's own message history grows across rounds alongside the ledgers is not specified in the shipped documentation.

## 7. Mastra (TypeScript agent framework)

Mastra's memory module (`@mastra/memory`, [docs](https://mastra.ai/docs/memory/working-memory)) ships a layered alternative to summarization, with the caveat that its long-conversation option is itself a summarization-form mechanism:

- **Bounded window with cache-aware removal.** `lastMessages` defaults to 10 and slides on every request — the docs state plainly that "once a thread grows past the limit, the oldest message leaves context on each turn, which changes the start of the prompt and invalidates the provider prompt cache" ([message history](https://mastra.ai/docs/memory/message-history)). The token-budget alternative `messageHistory: { maxTokens, atMaxRemoveTokens }` (default removal chunk 25% of the budget) removes history in chunks "to keep the prompt prefix stable across several turns"; system messages, current input, and agent responses are never trimmed, linked tool calls and results are removed together, and trimmed messages stay in storage behind a per-thread boundary. Semantic recall retrieves older messages by embedding search instead of extending the window.
- **Working memory** is a bounded scratchpad injected into every turn: a Markdown template (replace semantics — the agent provides the full content on each update) or a JSON schema (merge semantics — deep-merged field updates, `null` deletes, arrays replaced), scoped per resource (across threads) or per thread. With `@mastra/pg`, resource-scoped merges run inside row-locked transactions, and `memory.mergeWorkingMemory()` exposes the same merge to application code.
- **Observational memory** (added in `@mastra/memory@1.1.0`, [docs](https://mastra.ai/docs/memory/observational-memory)) is the long-conversation mechanism: background Observer and Reflector agents watch the stored history; when message tokens exceed a threshold (default 30,000, estimated locally with `tokenx`), the Observer writes observations — dense notes with attachment placeholders — and older messages are replaced as observations activate, while the observation log itself appends, which the docs list as the prompt-caching benefit ("observations append over time rather than being retrieved at runtime each turn"). Extractors persist structured values (current task, suggested response, thread title, custom Zod schemas); early activation on idle or provider change protects expiring prompt caches; retries default to 8 with a `failurePolicy` of `abort` or `continue`, and the docs warn that under a sustained provider outage with `continue`, "unobserved messages stay pending and keep accruing in the main agent's context" until the context limit becomes the failure.

The default path (window + recall + working memory) never summarizes; observational memory does, in observation form, while keeping the live prefix append-only.

## 8. Cross-reference with NOOA's projection budgeting

[Nooa.md](nooa.md)'s central pattern is: budget the projection, not the value — bounded previews per surface (§3.2), values live in the Python process, serialization happens only at the durability boundary (§3.4), and three compaction paths stay dormant by keeping transcripts far below thresholds (§3.6). The shipped harnesses above reach the same trigger-dormancy by externalizing what NOOA keeps in-process:

- **Letta memory blocks ≈ NOOA typed fields and dynamic context blocks.** Both render a bounded, model-editable state surface into every prompt. Letta bounds blocks by character limit; NOOA bounds by render expression (`pformat(self, ...)`) re-evaluated each turn. Letta's archival memory and recall search ≈ NOOA's `MemoryRef`/`deref` live-reference recall (§4), with the difference that NOOA dereferences into current process state while Letta retrieves stored passages.
- **Manus restorable compression and deepagents offload ≈ NOOA's capture bounds.** NOOA's head/tail stdout capture at 50,000 characters is unrecoverable in-context, with an optional `file_backed` escape hatch writing the full output to a temp file (§3.6); deepagents makes the escape hatch the default at 20,000 tokens with preview stubs and re-openable paths, and Manus states the same rule as design doctrine (drop content, keep the pointer). NOOA's stronger guarantee — full values never leave the process — is the one property none of the surveyed harnesses reproduces without a separate execution substrate ([prime-agent.md](prime-agent.md) does, with its kernel).
- **Magentic-One ledgers and Manus recitation ≈ NOOA's dynamic context and `todo.v`.** Both are model-maintained state documents that replace transcript growth for goal coherence. NOOA's events API adds what ledgers lack: verbatim addressability of the replaced content (`events.collapse` keeps originals searchable by tag, §2.6/§3.6).
- **Anthropic's `clear_tool_uses` is the weakest point on the displacement axis**: cleared results become placeholders with no pointer, and safety depends entirely on the memory tool having been written to first — an ordering the harness nudges with an automatic warning but does not enforce. NOOA's equivalent emergency path (`_archive_on_context_error`) moves raw events into session storage, keeping the data.
- **Amp handoff and Manus Branch are session-tree operations**, the harness-level analog of NOOA's snapshot boundary (§3.4): state passes between sessions by value, and NOOA's snapshot type allowlist plays the role Amp's reviewable draft prompt plays — an explicit, inspectable serialization at the moment of transfer.

## 9. What is load-bearing at very long horizons

Mechanisms observed to carry 100+-turn, multi-hour sessions (evidence noted per item):

1. **Values or verbatim logs outside the context, with pointers back.** Filesystem-backed workspaces and re-openable offload (deepagents, Manus, Letta MemFS) are the only mechanisms in this set that keep long-horizon information lossless while shrinking live context. This is the load-bearing stage in every harness that has one.
2. **Model-editable durable memory written before loss.** Memory tool before clearing (Anthropic), memory blocks plus sleep-time consolidation (Letta), working memory (Mastra), todo.md recitation (Manus), NOOA typed fields. Long-horizon correctness depends on the write happening before the loss event; only Anthropic documents a built-in ordering prompt to encourage it, and none enforce it.
3. **Goal-state documents updated in place.** Ledgers (Magentic-One), recitation (Manus), NOOA's dynamic suffix. These bound context growth for the planning surface and keep the plan inside recent attention; they do not bound tool-result growth.
4. **Subagent isolation with result-only return.** deepagents, Letta recall subagents, NOOA's depth-bounded `delegate`. This keeps the main context bounded by construction and is the one mechanism whose effect is independent of session length.

Mechanisms that postpone rather than avoid compaction:

- **Selective clearing of tool results** (Anthropic `clear_tool_uses_20250919`): nothing replaces what is cleared; without the memory-tool pairing it is a slower path to the same information loss, and each clear point rewrites the cached prefix — `clear_at_least` exists precisely to amortize that.
- **Sliding windows and partial-evict summarization** (Letta's 30% sliding window, Mastra's `lastMessages`): information leaves the context permanently or lives only behind a retrieval path, and Mastra's docs acknowledge the cache cost of every slide.
- **Summarizing consolidation**, even when cache-stable (Mastra observational memory, Letta sleep-time, NOOA's dormant summarizer): lossy by construction; viable only while the lossy surface stays small relative to the durable surface (memory files, observations, blocks) that survives it.
- **Handoff and fresh-thread patterns** (Amp, forked sessions): bounded context per thread by replacing continuity with extracted prompts; correctness depends on extraction fidelity and on a durable store (files, referenced threads) holding what the extraction drops.

The consistent late-2026 shape: a durable store (files, git-backed memory, database) that the model reads and writes through tools; a live context assembled as stable prefix plus append-only event history plus bounded volatile tail; and summarization retained but retired to the role NOOA gives it — an unused safety mechanism, invoked only when the displacement store was not written to in time.

## 10. Open questions and uncertainties

- Letta: MemFS v2 and the git-backed memory repository are visible in code and tests (`src/agent/memory-git*.ts`, `memory-worktree.ts`) but shipping documentation for them is thin; how memory blocks and the MemFS index compose in the rendered prompt at HEAD was not traced end to end. The exact trigger site for local-mode compaction in `letta-code` (threshold and estimator wiring under `src/backend/local/`) was not traced; the defaults in `compaction.ts` are verified, the call path is not.
- Letta: the sleep-time group's `min/max_message_buffer_length` semantics are documented only in schema docstrings ("best effort"), and docs.letta.com marks the cited memory pages legacy; the current cloud product's context-assembly behavior is not inspectable.
- Anthropic: the 39%/29%/84% figures come from an internal evaluation set whose composition is unpublished; no third-party replication was located.
- Manus: the blog's token-economics figures (100:1 ratio, $0.30/$3.00) are product-blog claims without published methodology; whether the file-system-as-context pattern is implemented exactly as described cannot be verified from outside.
- Magentic-One: the shipped Semantic Kernel / Agent Framework implementation is experimental; the docs do not specify whether the Orchestrator's message history grows monotonically across rounds or is bounded by the ledgers.
- Amp: the handoff extraction model and prompt are unspecified ("another model"); `ask-to-handoff` was cited but not read in full for this report.
- deepagents: the repository contains an evals package (`libs/evals`) that was not examined; no published long-horizon benchmark attributable to the project was found.
- Mastra: observational memory's observation-activation schedule and the exact replacement behavior for "older messages" beyond the documented threshold and early-activation settings were not traced into the SDK source.

## 11. Sources

Letta: https://github.com/letta-ai/letta (main branch, docs-only, README redirect; `archive` branch for the V1 server) — clones at HEAD `5bcdd177d70fa2b31a754cfcd801e77b2e1ab16a`, `cc4654acc3b424a68c385bce0fe0c00edaad5d7e` (letta-code), `56ba9c25552605eec89de8ed3dc6394b625c1993` (archive); https://docs.letta.com/v1-sdk/memory/memory-blocks; https://docs.letta.com/configuration/memory; https://www.letta.com/blog/sleep-time-compute/

LangChain deepagents: https://github.com/langchain-ai/deepagents — clone at HEAD `825acb3ca03bd103e4df6013b122eca8475d1982` (`libs/ARCHITECTURE.md`; `deepagents/graph.py`; `middleware/{summarization,filesystem,subagents,_blob_offload}.py`; `libs/CHANGELOG.md`); https://github.com/langchain-ai/deepagents/issues/4929

Anthropic: https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool; https://platform.claude.com/docs/en/build-with-claude/context-editing; https://platform.claude.com/docs/en/build-with-claude/compaction; https://claude.com/resources/articles/context-management (2025-09-29); https://code.claude.com/docs/en/memory

Manus: https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus (2025-07-18); https://manus.im/blog/manus-branch (2026-07-09); arXiv:2510.11967 (context-folding paper, cited only to correct attribution)

Amp: https://ampcode.com/news/handoff (2025-10-23); https://ampcode.com/guides/context-management; https://ampcode.com/news/ask-to-handoff; https://ampcode.com/200k-tokens-is-plenty

Microsoft: https://www.microsoft.com/en-us/research/articles/magentic-one-a-generalist-multi-agent-system-for-solving-complex-tasks/ (2024-11-04); https://arxiv.org/abs/2411.04468; https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-orchestration/magentic; https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/magentic-one.html

Mastra: https://mastra.ai/docs/memory/working-memory; https://mastra.ai/docs/memory/message-history; https://mastra.ai/docs/memory/observational-memory

In-repo cross-references: [nooa.md](nooa.md) (anchor; projection budgeting and dormant compaction); [pi.md](pi.md) and [prime-agent.md](prime-agent.md) (cut-point compaction; RLM kernel); [minimal-harness-survey.md](minimal-harness-survey.md) (Codex CLI, Open Interpreter, and other minimal harnesses); [benchmarks.md](benchmarks.md) (same-model harness variance); [no-compaction-approaches.md](no-compaction-approaches.md) (concept-level companion report)
